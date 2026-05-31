import 'package:flutter/material.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/core/http_server/federation_server.dart';
import 'package:nightingale/features/federation/stun/stun_address_resolver.dart';
import 'package:nightingale/features/node_identity/local_address_resolver.dart';
import 'package:nightingale/features/node_identity/node_identity_repository.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

class NodeIdentityPanel extends StatefulWidget {
  const NodeIdentityPanel({super.key});

  @override
  State<NodeIdentityPanel> createState() => _NodeIdentityPanelState();
}

class _NodeIdentityPanelState extends State<NodeIdentityPanel> {
  String _actorUrl = '–';
  String _lanIp = '–';
  String _publicAddress = '–';
  String _port = '–';
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _refreshing = true);
    try {
      final repo = sl<NodeIdentityRepository>();
      final server = sl<FederationServer>();
      final lanResolver = sl<LocalAddressResolver>();

      final actorUrl = await repo.getActorUrl().catchError((_) => '–');
      final publicAddress =
          await repo.getPublicAddress().catchError((_) => null);
      final lanIp = await lanResolver.resolve().catchError((_) => null);
      final port = server.currentPort;

      if (mounted) {
        setState(() {
          _actorUrl = actorUrl;
          _publicAddress = publicAddress ?? '– (STUN pending)';
          _lanIp = lanIp ?? '– (no LAN interface)';
          _port = port?.toString() ?? '–';
          _refreshing = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Node Identity',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            TextButton(
              onPressed: _refreshing ? null : _load,
              child: Text(
                _refreshing ? 'Refreshing…' : 'Refresh',
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ],
        ),
        const Divider(),
        _row('Actor URL', _actorUrl),
        _row('LAN IP', _lanIp),
        _row('Public Addr', _publicAddress),
        _row('Bound Port', _port),
        const SizedBox(height: AppSpacing.md),
        TextButton(
          onPressed: _refreshing ? null : _runStun,
          child: const Text('Re-run STUN', style: TextStyle(fontSize: 10)),
        ),
      ],
    );
  }

  Future<void> _runStun() async {
    setState(() => _refreshing = true);
    try {
      final stun = sl<StunAddressResolver>();
      final result = await stun.resolve();
      final repo = sl<NodeIdentityRepository>();
      await repo.updatePublicAddress(result);
    } catch (_) {}
    await _load();
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 90,
              child: Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      );
}
