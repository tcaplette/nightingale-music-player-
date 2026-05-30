import 'package:flutter/material.dart';
import 'package:nightingale/shared/theme/app_motion.dart';
import 'package:nightingale/shared/theme/app_radius.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

/// A shimmer-animated skeleton row for list loading states.
/// Use [SkeletonListView] to show N rows while data is loading.
class SkeletonRow extends StatefulWidget {
  const SkeletonRow({
    super.key,
    this.hasLeadingSquare = true,
    this.hasTrailingLine = false,
  });

  final bool hasLeadingSquare;
  final bool hasTrailingLine;

  @override
  State<SkeletonRow> createState() => _SkeletonRowState();
}

class _SkeletonRowState extends State<SkeletonRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.emphasis,
    )..repeat(reverse: true);
    _shimmer = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerHighest;
    final highlight = scheme.surfaceContainerHighest.withValues(alpha: 0.4);

    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, _) {
        final color = Color.lerp(base, highlight, _shimmer.value)!;
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              if (widget.hasLeadingSquare) ...[
                _Bone(width: 48, height: 48, color: color, radius: AppRadius.sm),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Bone(width: double.infinity, height: 14, color: color),
                    const SizedBox(height: AppSpacing.xs),
                    _Bone(width: 140, height: 11, color: color),
                  ],
                ),
              ),
              if (widget.hasTrailingLine) ...[
                const SizedBox(width: AppSpacing.md),
                _Bone(width: 40, height: 11, color: color),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Bone extends StatelessWidget {
  const _Bone({
    required this.width,
    required this.height,
    required this.color,
    this.radius = AppRadius.sm,
  });

  final double width;
  final double height;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// A ListView of [count] skeleton rows.
class SkeletonListView extends StatelessWidget {
  const SkeletonListView({
    super.key,
    this.count = 8,
    this.hasLeadingSquare = true,
  });

  final int count;
  final bool hasLeadingSquare;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      itemBuilder: (_, __) => SkeletonRow(hasLeadingSquare: hasLeadingSquare),
    );
  }
}
