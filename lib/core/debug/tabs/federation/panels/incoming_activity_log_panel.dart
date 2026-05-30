import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nightingale/core/debug/tabs/federation/federation_event_bus.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

class IncomingActivityLogPanel extends StatefulWidget {
  const IncomingActivityLogPanel({super.key});

  @override
  State<IncomingActivityLogPanel> createState() =>
      _IncomingActivityLogPanelState();
}

class _IncomingActivityLogPanelState extends State<IncomingActivityLogPanel> {
  final List<IncomingActivityEvent> _events = [];
  StreamSubscription<IncomingActivityEvent>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = FederationEventBus.instance.incoming.listen((e) {
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
        child: Text('No incoming activities yet',
            style: TextStyle(fontSize: 11, color: Colors.grey)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.sm),
      itemCount: _events.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final e = _events[i];
        final sigOk = e.signatureResult == 'verified';
        return ListTile(
          dense: true,
          title: Text(
            '${e.activityType} from ${Uri.parse(e.sourceActorUrl).host}',
            style: const TextStyle(fontSize: 11),
          ),
          subtitle: Text(
            'sig: ${e.signatureResult} · ${e.outcome}',
            style: TextStyle(
              fontSize: 10,
              color: sigOk ? Colors.green : Colors.red,
            ),
          ),
          trailing: Text(
            _timeLabel(e.timestamp),
            style: const TextStyle(fontSize: 9, color: Colors.grey),
          ),
        );
      },
    );
  }

  String _timeLabel(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
}
