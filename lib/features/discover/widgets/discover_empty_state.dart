import 'package:flutter/material.dart';
import 'package:nightingale/shared/theme/app_colors.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

class DiscoverEmptyState extends StatelessWidget {
  const DiscoverEmptyState({super.key, required this.onAddMusic});

  final VoidCallback onAddMusic;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.explore_outlined,
              size: 48,
              color: AppColors.neutral400,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Nothing to discover yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Add music to your library or follow someone to see what people around you are into.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.neutral400,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(
              onPressed: onAddMusic,
              child: const Text('Add music'),
            ),
          ],
        ),
      ),
    );
  }
}
