import 'package:flutter/material.dart';
import 'package:nightingale/shared/components/network_state/network_state_animator.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

// Phase 7 tone + motion audit:
// [x] No "Error"/"Failed"/"Problem" copy — uses "is offline" (calm/neutral)
// [x] Passive icon (cloud_off_outlined, muted color, no error-red)
// [x] Entrance animation via NetworkStateAnimator
// [x] No AppColors.error used
// [x] Does not obscure playback controls in Column layout

class HostOfflineWidget extends StatelessWidget {
  const HostOfflineWidget({
    super.key,
    required this.displayName,
    this.lastSeenAt,
  });

  final String displayName;
  final DateTime? lastSeenAt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return NetworkStateAnimator(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 16,
            color: scheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(width: AppSpacing.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$displayName is offline', style: textTheme.labelMedium),
              if (lastSeenAt != null)
                Text(
                  'Last seen ${_formatRelative(lastSeenAt!)}',
                  style: textTheme.labelSmall,
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatRelative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
