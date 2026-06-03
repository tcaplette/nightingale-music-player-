import 'package:flutter/material.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

class LibraryEmptyState extends StatelessWidget {
  const LibraryEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.detail,
    this.discoveredCount,
    this.isScanning = false,
    this.onChooseSongs,
  });

  final IconData icon;
  final String message;
  final String? detail;

  /// Number of tracks discovered on device but not yet in the library.
  /// When > 0 and [isScanning] is false, shows a count and a CTA button.
  final int? discoveredCount;

  /// When true, shows a scanning indicator instead of the count/CTA.
  final bool isScanning;

  /// Called when the user taps the "Choose Songs" CTA.
  final VoidCallback? onChooseSongs;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: scheme.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              style: textTheme.titleMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
            if (detail != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                detail!,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.35),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            if (isScanning) ...[
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Scanning for music…',
                style: textTheme.labelSmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ] else if ((discoveredCount ?? 0) > 0) ...[
              Text(
                'You have $discoveredCount ${discoveredCount == 1 ? "song" : "songs"} available to import',
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: onChooseSongs,
                icon: const Icon(Icons.library_music_outlined),
                label: const Text('Choose Songs'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
