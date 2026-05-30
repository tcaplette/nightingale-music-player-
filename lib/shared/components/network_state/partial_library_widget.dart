import 'package:flutter/material.dart';
import 'package:nightingale/shared/components/network_state/network_state_animator.dart';
import 'package:nightingale/shared/theme/app_radius.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

// Phase 7 tone + motion audit:
// [x] No "Error"/"Failed"/"Problem" copy — uses "Partial library" (neutral)
// [x] Passive icon (library_music_outlined, muted color)
// [x] Entrance animation via NetworkStateAnimator
// [x] No AppColors.error used
// [x] User can still interact with available portion (no blocking overlay)

class PartialLibraryWidget extends StatelessWidget {
  const PartialLibraryWidget({
    super.key,
    required this.displayName,
    this.statusLabel = 'Partial library',
  });

  final String displayName;
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
        border: Border.all(
          color: scheme.outline.withValues(alpha: 0.4),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.library_music_outlined,
            size: 13,
            color: scheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            "$displayName's library — $statusLabel",
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    ),
    );
  }
}
