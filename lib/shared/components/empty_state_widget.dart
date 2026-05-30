import 'package:flutter/material.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.headline,
    this.subhead,
    this.action,
  });

  final IconData icon;
  final String headline;
  final String? subhead;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.38);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: muted),
            const SizedBox(height: AppSpacing.md),
            Text(
              headline,
              style: theme.textTheme.titleMedium?.copyWith(color: muted),
              textAlign: TextAlign.center,
            ),
            if (subhead != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                subhead!,
                style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.md),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
