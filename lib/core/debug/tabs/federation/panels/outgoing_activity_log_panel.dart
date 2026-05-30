import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nightingale/core/debug/tabs/federation/federation_event_bus.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

class OutgoingActivityLogPanel extends StatefulWidget {
  const OutgoingActivityLogPanel({super.key});

  @override
  State<OutgoingActivityLogPanel> createState() =>
      _OutgoingActivityLogPanelState();
}

class _OutgoingActivityLogPanelState extends State<OutgoingActivityLogPanel> {
  final List<OutgoingActivityEvent> _events = [];
  StreamSubscription<OutgoingActivityEvent>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = FederationEventBus.instance.outgoing.listen((e) {
      setState(() => _events.insert(0, e));
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_events.isEmpty) {
      return const Center(
        child: Text('No outgoing activities yet',
            style: TextStyle(fontSize: 11, color: Colors.grey)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.sm),
      itemCount: _events.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final e = _events[i];
        return ExpansionTile(
          dense: true,
          title: Text(
            '${e.activityType} → ${Uri.parse(e.destination).host}',
            style: const TextStyle(fontSize: 11),
          ),
          subtitle: Text(
            '${_statusChip(e.status)} · ${e.httpStatus ?? '—'}',
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: SelectableText(
                const JsonEncoder.withIndent('  ')
                    .convert(jsonDecode(e.payloadJson)),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
              ),
            ),
          ],
        );
      },
    );
  }

  String _statusChip(DeliveryStatus s) => switch (s) {
        DeliveryStatus.delivered => '✓ delivered',
        DeliveryStatus.retrying => '↻ retrying',
        DeliveryStatus.relayed => '⇢ relayed',
        DeliveryStatus.failed => '✗ failed',
      };
}
