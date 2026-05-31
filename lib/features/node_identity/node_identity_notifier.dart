import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/core/http_server/federation_server.dart';
import 'package:nightingale/core/logging/app_logger.dart';
import 'package:nightingale/features/federation/mdns/mdns_advertiser.dart';
import 'package:nightingale/features/federation/stun/stun_address_resolver.dart';
import 'package:nightingale/features/node_identity/local_address_resolver.dart';
import 'package:nightingale/features/node_identity/node_identity_repository.dart';

sealed class NodeIdentityState {}

class NodeIdentityLoading extends NodeIdentityState {}

class NodeIdentityReady extends NodeIdentityState {
  NodeIdentityReady(this.actorUrl);
  final String actorUrl;
}

class NodeIdentityMissing extends NodeIdentityState {}

class NodeIdentityNotifier extends Notifier<NodeIdentityState> {
  @override
  NodeIdentityState build() {
    _check();
    return NodeIdentityLoading();
  }

  Future<void> _check() async {
    final repo = sl<NodeIdentityRepository>();
    final has = await repo.hasIdentity();
    if (has) {
      final url = await repo.getActorUrl();
      state = NodeIdentityReady(url);
    } else {
      state = NodeIdentityMissing();
    }
  }

  Future<void> createIdentity({required String displayName}) async {
    final repo = sl<NodeIdentityRepository>();

    // Resolve LAN IP — synchronous and fast.
    final lanResolver = sl<LocalAddressResolver>();
    final server = sl<FederationServer>();
    final port = server.currentPort ?? 7777;
    final lanIp = await lanResolver.resolve() ?? '127.0.0.1';

    await repo.generateIdentity(
      displayName: displayName,
      lanIp: lanIp,
      port: port,
    );

    final url = await repo.getActorUrl();
    state = NodeIdentityReady(url);

    // Kick off STUN in background — onboarding does not block on it.
    _resolvePublicAddressInBackground(repo);

    // Start mDNS advertisement now that identity is known.
    _startMdnsAdvertiser(displayName, port);
  }

  void _resolvePublicAddressInBackground(NodeIdentityRepository repo) {
    Future(() async {
      try {
        final stun = sl<StunAddressResolver>();
        final publicAddress = await stun.resolve();
        await repo.updatePublicAddress(publicAddress);
        AppLogger.debug(
          'STUN resolved at onboarding: $publicAddress',
          tag: 'identity',
        );
      } catch (e) {
        AppLogger.debug('STUN resolution failed at onboarding: $e', tag: 'identity');
      }
    }).ignore();
  }

  void _startMdnsAdvertiser(String displayName, int port) {
    Future(() async {
      try {
        final repo = sl<NodeIdentityRepository>();
        final actor = await repo.getLocalActor();
        final advertiser = MdnsAdvertiser(
          username: actor.preferredUsername,
          port: port,
        );
        // Replace the placeholder advertiser in the service locator isn't
        // straightforward with GetIt singletons, so just start this one.
        await advertiser.start();
      } catch (e) {
        AppLogger.debug('mDNS advertiser start failed: $e', tag: 'identity');
      }
    }).ignore();
  }
}

final nodeIdentityProvider =
    NotifierProvider<NodeIdentityNotifier, NodeIdentityState>(
  NodeIdentityNotifier.new,
);
