import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale/features/recommendations/domain/recommendation_engine_notifier.dart';
import 'package:nightingale/shared/theme/app_colors.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

class AffinityMatrixTab extends ConsumerWidget {
  const AffinityMatrixTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    assert(kDebugMode);
    final engineAsync = ref.watch(recommendationEngineProvider);

    return engineAsync.when(
      loading: () => const Center(
        child: Text(
          'Loading…',
          style: TextStyle(color: AppColors.neutral400, fontSize: 12),
        ),
      ),
      error: (e, _) => Center(
        child: Text(
          'Error: $e',
          style: const TextStyle(color: AppColors.errorDark, fontSize: 11),
        ),
      ),
      data: (state) {
        if (state.affinityMatrix.isEmpty) {
          return const Center(
            child: Text(
              'No affinity data yet.\nFollow someone and accumulate signals.',
              style: TextStyle(color: AppColors.neutral400, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          );
        }

        final sorted = state.affinityMatrix.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.sm),
          children: [
            for (final entry in sorted)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _shortUrl(entry.key),
                        style: const TextStyle(
                          color: AppColors.neutral700,
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      entry.value < 0
                          ? 'Insufficient data'
                          : entry.value.toStringAsFixed(3),
                      style: TextStyle(
                        color: entry.value < 0
                            ? AppColors.neutral400
                            : AppColors.accent,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  String _shortUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return '${uri.host}${uri.path.length > 20 ? '…' : uri.path}';
    } catch (_) {
      return url.length > 30 ? '${url.substring(0, 30)}…' : url;
    }
  }
}
