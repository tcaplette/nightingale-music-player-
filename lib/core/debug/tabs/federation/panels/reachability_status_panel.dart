import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale/features/federation/reachability/node_reachability_provider.dart';
import 'package:nightingale/features/federation/reachability/reachability_state.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

class ReachabilityStatusPanel extends ConsumerWidget {
  const ReachabilityStatusPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(nodeReachabilityProvider);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _row('Status', _statusLabel(state)),
        if (state is ReachabilityRegistered) ...[
          _row('Address', state.address),
          _row('Port', state.port.toString()),
        ],
        if (state is ReachabilityFailed)
          _row('Reason', state.reason),
      ],
    );
  }

  Widget _row(String key, String value) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(key,
                  style: const TextStyle(color: Colors.grey, fontSize: 10)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(fontSize: 10)),
            ),
          ],
        ),
      );

  String _statusLabel(ReachabilityState state) => switch (state) {
        ReachabilityRegistered() => 'Registered',
        ReachabilityPending() => 'Pending',
        ReachabilityFailed() => 'Failed',
        ReachabilityOffline() => 'Offline',
      };
}
