import 'package:flutter/material.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/features/federation/mdns/mdns_advertiser.dart';
import 'package:nightingale/features/federation/mdns/mdns_discovery_service.dart';
import 'package:nightingale/features/federation/mdns/mdns_event_log.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

class MdnsDebugPanel extends StatefulWidget {
  const MdnsDebugPanel({super.key});

  @override
  State<MdnsDebugPanel> createState() => _MdnsDebugPanelState();
}

class _MdnsDebugPanelState extends State<MdnsDebugPanel> {
  bool _refreshing = false;

  @override
  Widget build(BuildContext context) {
    final discovery = sl<MdnsDiscoveryService>();
    final advertiser = sl<MdnsAdvertiser>();
    final peers = discovery.peers;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _section('Advertiser'),
        _row('Status', advertiser.isRunning ? 'Running ✓' : 'Stopped ✗',
            advertiser.isRunning ? Colors.green : Colors.red),
        _row('Name', advertiser.username),
        _row('Port', advertiser.port.toString()),
        const SizedBox(height: AppSpacing.sm),
        Row(children: [
          _btn('Start', advertiser.isRunning ? null : () async {
            await advertiser.start();
            if (mounted) setState(() {});
          }),
          const SizedBox(width: AppSpacing.sm),
          _btn('Stop', advertiser.isRunning ? () async {
            await advertiser.stop();
            if (mounted) setState(() {});
          } : null),
        ]),

        const Divider(height: AppSpacing.xl),

        _section('Discovery'),
        _row('Status', discovery.isRunning ? 'Browsing ✓' : 'Stopped ✗',
            discovery.isRunning ? Colors.green : Colors.red),
        _row('Peers found', peers.length.toString()),
        const SizedBox(height: AppSpacing.sm),
        Row(children: [
          _btn(
            _refreshing ? 'Refreshing…' : 'Refresh',
            _refreshing ? null : () async {
              setState(() => _refreshing = true);
              await discovery.refresh();
              await Future.delayed(const Duration(seconds: 3));
              if (mounted) setState(() => _refreshing = false);
            },
          ),
        ]),

        if (peers.isEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          const Text(
            'No peers discovered yet.',
            style: TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ] else ...[
          const SizedBox(height: AppSpacing.md),
          ...peers.entries.map((e) => _peerTile(e.key, e.value)),
        ],

        const Divider(height: AppSpacing.xl),

        _section('Event Log'),
        ...MdnsEventLog.instance.events.reversed.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              e,
              style: const TextStyle(fontSize: 9, fontFamily: 'monospace'),
            ),
          ),
        ),
        if (MdnsEventLog.instance.events.isEmpty)
          const Text('No events yet.', style: TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: AppSpacing.sm),
        _btn('Clear log', () {
          MdnsEventLog.instance.clear();
          setState(() {});
        }),
      ],
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      );

  Widget _row(String label, String value, [Color? valueColor]) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(label,
                  style: const TextStyle(color: Colors.grey, fontSize: 10)),
            ),
            Text(
              value,
              style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  color: valueColor),
            ),
          ],
        ),
      );

  Widget _peerTile(String path, MdnsPeer peer) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          '$path  →  ${peer.ip}:${peer.port}',
          style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
        ),
      );

  Widget _btn(String label, VoidCallback? onPressed) => OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: const TextStyle(fontSize: 10),
        ),
        child: Text(label),
      );
}
