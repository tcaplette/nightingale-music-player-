import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nightingale/features/recommendations/domain/signal_event.dart';
import 'package:nightingale/shared/theme/app_colors.dart';
import 'package:nightingale/shared/theme/app_radius.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

// Session-scoped in-memory log fed by SignalEventBus.
class SignalEventBus {
  SignalEventBus._();
  static final SignalEventBus instance = SignalEventBus._();

  final StreamController<SignalEvent> _controller =
      StreamController.broadcast();

  Stream<SignalEvent> get stream => _controller.stream;

  void emit(SignalEvent event) {
    if (!kDebugMode) return;
    _controller.add(event);
  }
}

class SignalEventLogTab extends StatefulWidget {
  const SignalEventLogTab({super.key});

  @override
  State<SignalEventLogTab> createState() => _SignalEventLogTabState();
}

class _SignalEventLogTabState extends State<SignalEventLogTab> {
  final List<SignalEvent> _events = [];
  SignalEventType? _filter;
  StreamSubscription<SignalEvent>? _sub;

  @override
  void initState() {
    super.initState();
    assert(kDebugMode);
    _sub = SignalEventBus.instance.stream.listen((e) {
      if (mounted) setState(() => _events.add(e));
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shown = _filter == null
        ? _events
        : _events.where((e) => e.eventType == _filter).toList();

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              for (final type in [null, ...SignalEventType.values])
                GestureDetector(
                  onTap: () => setState(() => _filter = type),
                  child: Container(
                    margin: const EdgeInsets.only(right: AppSpacing.xs),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _filter == type
                          ? AppColors.accent
                          : AppColors.neutral200,
                      borderRadius: AppRadius.fullAll,
                    ),
                    child: Text(
                      type == null ? 'All' : type.value,
                      style: const TextStyle(
                        color: AppColors.neutral900,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: shown.isEmpty
              ? const Center(
                  child: Text(
                    'No signals yet',
                    style: TextStyle(
                        color: AppColors.neutral400, fontSize: 12),
                  ),
                )
              : ListView.builder(
                  reverse: true,
                  itemCount: shown.length,
                  itemBuilder: (_, i) {
                    final e = shown[shown.length - 1 - i];
                    final fp = e.trackFingerprint.length > 20
                        ? '${e.trackFingerprint.substring(0, 20)}…'
                        : e.trackFingerprint;
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 2,
                      ),
                      child: Text(
                        '[${e.eventType.value}] $fp  w=${e.weight.toStringAsFixed(1)}',
                        style: const TextStyle(
                          color: AppColors.neutral700,
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
