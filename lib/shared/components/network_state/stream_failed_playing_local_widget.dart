import 'package:flutter/material.dart';
import 'package:nightingale/shared/components/network_state/network_state_animator.dart';
import 'package:nightingale/shared/theme/app_radius.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

// Phase 7 tone + motion audit:
// [x] No "Error"/"Failed"/"Problem" copy — uses "Playing cached copy" (neutral)
// [x] Passive icon (download_done_outlined, muted color)
// [x] Entrance animation via NetworkStateAnimator
// [x] No AppColors.error used
// [x] Renders as non-intrusive banner, does not obscure controls

class StreamFailedPlayingLocalWidget extends StatelessWidget {
  const StreamFailedPlayingLocalWidget({
    super.key,
    this.statusLabel = 'Playing cached copy',
  });

  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return NetworkStateAnimator(
      child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: AppRadius.smAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.download_done_outlined,
            size: 13,
            color: scheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(statusLabel, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    ),
    );
  }
}
