import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:nightingale/core/http_server/federation_router.dart';
import 'package:nightingale/core/http_server/federation_server.dart';
import 'package:nightingale/core/logging/app_logger.dart';
import 'package:nightingale/features/federation/discovery/mastodon_profile_sync_service.dart';
import 'package:nightingale/features/federation/stun/stun_address_resolver.dart';
import 'package:nightingale/features/federation/network/source_availability_status.dart';
import 'package:nightingale/features/node_identity/node_identity_repository.dart';

const _tag = 'network_binding';

/// Detects the best available public network interface, binds
/// [FederationServer] to it, and publishes (or clears) the address on the
/// Mastodon profile. Re-run on every network change event.
class NetworkBindingService {
  NetworkBindingService({
    required StunAddressResolver stunResolver,
    required FederationServer server,
    required NodeIdentityRepository identityRepo,
    required MastodonProfileSyncService profileSync,
  })  : _stun = stunResolver,
        _server = server,
        _identityRepo = identityRepo,
        _profileSync = profileSync;

  final StunAddressResolver _stun;
  final FederationServer _server;
  final NodeIdentityRepository _identityRepo;
  final MastodonProfileSyncService _profileSync;

  final _statusController =
      StreamController<SourceAvailabilityStatus>.broadcast();

  /// Stream of [SourceAvailabilityStatus] updates. Riverpod providers and
  /// widgets should use [sourceAvailabilityProvider] instead.
  Stream<SourceAvailabilityStatus> get statusStream => _statusController.stream;

  SourceAvailabilityStatus _currentStatus = SourceAvailabilityStatus.checking;
  SourceAvailabilityStatus get currentStatus => _currentStatus;

  String? _currentBindAddress;

  void _setStatus(SourceAvailabilityStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  void dispose() {
    _statusController.close();
  }

  /// Runs the full detect→select→bind→publish cycle.
  ///
  /// - If STUN resolves to a local interface IP → bind there, publish address.
  /// - If NATted → try a cellular interface; bind and publish if found.
  /// - If no public interface → enter consumer-only mode.
  ///
  /// Restarts [FederationServer] only when the bind address changes.
  Future<void> evaluateAndBind() async {
    _setStatus(SourceAvailabilityStatus.checking);
    print('NIGHTINGALE BINDING: evaluateAndBind starting');

    try {
      var resolvedAddress = await _stun.resolve();

      if (resolvedAddress == null) {
        print('NIGHTINGALE BINDING: STUN failed (UDP blocked?) — trying HTTPS fallback');
        final httpIp = await _resolvePublicIpViaHttps();
        if (httpIp != null) {
          final serverPort = _server.currentPort ?? 7777;
          resolvedAddress = '$httpIp:$serverPort';
          print('NIGHTINGALE BINDING: HTTPS IP discovery succeeded: $resolvedAddress');
        } else {
          print('NIGHTINGALE BINDING: HTTPS fallback also failed — assuming NAT');
          await _tryCellularOrConsumerOnly();
          return;
        }
      }

      // Extract the IP from "ip:port".
      final stunIp = resolvedAddress.split(':').first;
      print('NIGHTINGALE BINDING: resolved=$resolvedAddress natted=${await _isNatted(stunIp)}');

      if (await _isNatted(stunIp)) {
        print('NIGHTINGALE BINDING: NATted — trying cellular');
        await _tryCellularOrConsumerOnly();
      } else {
        print('NIGHTINGALE BINDING: direct public IP=$stunIp — binding and publishing');
        await _bindAndPublish(
          bindIp: stunIp,
          publicAddress: resolvedAddress,
          status: SourceAvailabilityStatus.available,
        );
      }
    } catch (e) {
      AppLogger.warning('evaluateAndBind: error $e — assuming NAT', tag: _tag);
      await _tryCellularOrConsumerOnly();
    }
  }

  /// Falls back to HTTPS-based IP discovery when UDP/STUN is blocked.
  /// Tries multiple public services in sequence, returns the first valid IPv4.
  Future<String?> _resolvePublicIpViaHttps() async {
    const services = [
      'https://api.ipify.org',
      'https://checkip.amazonaws.com',
      'https://ifconfig.me/ip',
    ];
    for (final url in services) {
      try {
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 5);
        final request = await client.getUrl(Uri.parse(url));
        final response = await request.close().timeout(const Duration(seconds: 5));
        final body = await response.transform(const Utf8Decoder()).join();
        client.close();
        final ip = body.trim();
        if (RegExp(r'^\d+\.\d+\.\d+\.\d+$').hasMatch(ip)) {
          AppLogger.debug('Public IP via $url: $ip', tag: _tag);
          return ip;
        }
      } catch (_) {}
    }
    return null;
  }

  /// Returns true when [stunIp] does not appear in any local network interface.
  Future<bool> _isNatted(String stunIp) async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      print('NIGHTINGALE BINDING: interfaces=${interfaces.map((i) => '${i.name}:${i.addresses.map((a) => a.address).join(',')}').join(' | ')}');
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (addr.address == stunIp) return false;
        }
      }
      return true;
    } catch (e) {
      print('NIGHTINGALE BINDING: _isNatted error: $e');
      return true;
    }
  }

  /// Finds the first cellular interface with a confirmed public IP via STUN.
  ///
  /// Returns "ip:port" on success, null otherwise.
  Future<String?> _findPublicCellularAddress() async {
    const cellularPatterns = ['rmnet', 'ccmni', 'wwan', 'pdp_ip'];

    List<NetworkInterface> interfaces;
    try {
      interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
    } catch (e) {
      AppLogger.debug(
          '_findPublicCellularAddress: error listing interfaces: $e', tag: _tag);
      return null;
    }

    for (final iface in interfaces) {
      final name = iface.name.toLowerCase();
      final isCellular =
          cellularPatterns.any((pattern) => name.contains(pattern));
      if (!isCellular) continue;

      for (final addr in iface.addresses) {
        AppLogger.debug(
            '_findPublicCellularAddress: checking ${iface.name} (${addr.address})',
            tag: _tag);

        // Try STUN first; fall back to HTTPS IP discovery when UDP is blocked.
        final stunOnIface =
            StunAddressResolver(stunServer: _stun.stunServer, timeout: _stun.timeout);
        String? publicResult = await stunOnIface.resolve();

        if (publicResult == null) {
          AppLogger.debug(
              '_findPublicCellularAddress: STUN blocked on ${iface.name} — trying HTTPS fallback',
              tag: _tag);
          final httpIp = await _resolvePublicIpViaHttps();
          if (httpIp != null) {
            final serverPort = _server.currentPort ?? 7777;
            publicResult = '$httpIp:$serverPort';
            AppLogger.debug(
                '_findPublicCellularAddress: HTTPS fallback succeeded: $publicResult',
                tag: _tag);
          }
        }

        if (publicResult == null) continue;

        AppLogger.debug(
            '_findPublicCellularAddress: ${iface.name} public=$publicResult', tag: _tag);
        return '${addr.address}|$publicResult';
      }
    }
    return null;
  }

  Future<void> _tryCellularOrConsumerOnly() async {
    final cellularResult = await _findPublicCellularAddress();
    if (cellularResult != null) {
      final parts = cellularResult.split('|');
      final bindIp = parts[0];
      final publicAddress = parts[1];
      AppLogger.debug(
          'evaluateAndBind: using cellular bindIp=$bindIp publicAddress=$publicAddress',
          tag: _tag);
      await _bindAndPublish(
        bindIp: bindIp,
        publicAddress: publicAddress,
        status: SourceAvailabilityStatus.availableViaCellular,
      );
    } else {
      await _enterConsumerOnly();
    }
  }

  Future<void> _bindAndPublish({
    required String bindIp,
    required String publicAddress,
    required SourceAvailabilityStatus status,
  }) async {
    if (_currentBindAddress != bindIp) {
      await _server.stop();
      await _server.start(
        router: buildFederationRouter(),
        bindAddress: bindIp,
      );
      _currentBindAddress = bindIp;
      AppLogger.debug(
          'evaluateAndBind: server (re)started on $bindIp:${_server.currentPort}',
          tag: _tag);
    }

    await _identityRepo.updatePublicAddress(publicAddress);

    // Build the actor URL from the public IP, not the LAN IP stored at onboarding.
    final actor = await _identityRepo.getLocalActor();
    final publicIp = publicAddress.split(':').first;
    final serverPort = _server.currentPort ?? 7777;
    final publicActorUrl = 'http://$publicIp:$serverPort/users/${actor.preferredUsername}';
    _profileSync.sync(actorUrl: publicActorUrl, publicAddress: publicAddress).ignore();

    _setStatus(status);
  }

  Future<void> _enterConsumerOnly() async {
    await _server.stop();
    _currentBindAddress = null;
    await _identityRepo.updatePublicAddress(null);
    await _profileSync.clearAddress();
    _setStatus(SourceAvailabilityStatus.consumerOnly);
  }
}
