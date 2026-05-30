import 'package:flutter/material.dart';
import 'package:nightingale/shared/components/identity/person_display.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

/// A list-tile that shows a person as avatar + display name + optional label.
/// The raw @user@node handle is never shown in this component.
class PersonTile extends StatelessWidget {
  const PersonTile({
    super.key,
    required this.displayName,
    this.avatarUrl,
    this.secondaryLabel,
    this.trailing,
    this.onTap,
  });

  final String displayName;
  final String? avatarUrl;
  final String? secondaryLabel;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            PersonDisplay(
              displayName: displayName,
              avatarUrl: avatarUrl,
              avatarSize: 44,
            ),
            if (secondaryLabel != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  secondaryLabel!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ] else
              const Spacer(),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
