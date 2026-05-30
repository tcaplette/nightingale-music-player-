import 'package:flutter/material.dart';
import 'package:nightingale/shared/theme/app_colors.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

class DiscoverEmptyState extends StatelessWidget {
  const DiscoverEmptyState({super.key, required this.onFindPeople});

  final VoidCallback onFindPeople;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
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
              'Follow people to see what they\'re into — recommendations grow from there.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.neutral400,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onFindPeople,
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Find people to follow'),
            ),
          ],
        ),
      ),
    );
  }
}
