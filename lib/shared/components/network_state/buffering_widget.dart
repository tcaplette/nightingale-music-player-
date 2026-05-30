import 'package:flutter/material.dart';
import 'package:nightingale/shared/components/network_state/network_state_animator.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

// Phase 7 tone + motion audit:
// [x] No "Error"/"Failed"/"Problem" copy
// [x] Passive icon (CircularProgressIndicator, neutral color)
// [x] Entrance animation via AnimatedOpacity
// [x] No AppColors.error used
// [x] Does not obscure playback controls in Column layout

class BufferingWidget extends StatelessWidget {
  const BufferingWidget({super.key, required this.statusLabel});

  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return NetworkStateAnimator(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: scheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(statusLabel, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}
