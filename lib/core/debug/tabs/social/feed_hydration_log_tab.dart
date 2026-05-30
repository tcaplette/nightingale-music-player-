import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale/features/social/providers/social_feed_notifier.dart';
import 'package:nightingale/shared/theme/app_colors.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

class FeedHydrationLogTab extends ConsumerWidget {
  const FeedHydrationLogTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    assert(
      kDebugMode,
      'FeedHydrationLogTab must only be used in debug builds',
    );

    final log = ref.watch(
      socialFeedProvider.select((s) => s.hydrationLog),
    );

    if (log.isEmpty) {
      return const Center(
        child: Text(
          'Open the Feed to populate the hydration log',
          style: TextStyle(color: AppColors.neutral400, fontSize: 12),
        ),
      );
    }

    final rendered = log.where((e) => e.disposition == 'rendered').length;
    final filtered = log.where((e) => e.disposition == 'filtered').length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              _Chip('Rendered: $rendered', AppColors.accent),
              const SizedBox(width: AppSpacing.xs),
              _Chip('Filtered: $filtered', AppColors.neutral400),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            itemCount: log.length,
            itemBuilder: (_, i) {
              final entry = log[i];
              final isFiltered = entry.disposition == 'filtered';
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatusDot(isFiltered ? AppColors.neutral300 : AppColors.accent),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${entry.type} · ${_host(entry.actorUrl)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.neutral700,
                            ),
                          ),
                          if (entry.filterReason != null)
                            Text(
                              'filtered: ${entry.filterReason}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.neutral400,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      _relTime(entry.timestamp),
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.neutral400,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _host(String actorUrl) {
    try {
      return Uri.parse(actorUrl).host;
    } catch (_) {
      return actorUrl;
    }
  }

  String _relTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 5) return 'now';
    return '${diff.inSeconds}s ago';
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 10, color: color),
        ),
      );
}

class _StatusDot extends StatelessWidget {
  const _StatusDot(this.color);
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 6,
        height: 6,
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}
