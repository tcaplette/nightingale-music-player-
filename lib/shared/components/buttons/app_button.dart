import 'package:flutter/material.dart';
import 'package:nightingale/shared/theme/app_motion.dart';
import 'package:nightingale/shared/theme/app_radius.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

enum AppButtonVariant { primary, secondary }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bool disabled = onPressed == null || isLoading;

    final backgroundColor = switch (variant) {
      AppButtonVariant.primary =>
        disabled ? scheme.primary.withValues(alpha: 0.4) : scheme.primary,
      AppButtonVariant.secondary => Colors.transparent,
    };

    final foregroundColor = switch (variant) {
      AppButtonVariant.primary => scheme.onPrimary,
      AppButtonVariant.secondary =>
        disabled ? scheme.onSurface.withValues(alpha: 0.4) : scheme.primary,
    };

    final border = variant == AppButtonVariant.secondary
        ? Border.all(
            color: disabled
                ? scheme.outline.withValues(alpha: 0.4)
                : scheme.primary,
          )
        : null;

    return AnimatedOpacity(
      opacity: disabled ? 0.6 : 1.0,
      duration: AppMotion.micro,
      curve: AppMotion.curveMicro,
      child: GestureDetector(
        onTap: disabled ? null : onPressed,
        child: AnimatedContainer(
          duration: AppMotion.micro,
          curve: AppMotion.curveMicro,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: AppRadius.mdAll,
            border: border,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm + 4,
          ),
          child: isLoading
              ? SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: foregroundColor,
                  ),
                )
              : Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
