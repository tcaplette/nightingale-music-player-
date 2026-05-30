import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale/features/recommendations/domain/provenance_record.dart';
import 'package:nightingale/features/recommendations/domain/recommendation_engine_notifier.dart';
import 'package:nightingale/shared/theme/app_colors.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

// Compile-time gated — this file is only referenced from kDebugMode paths
// in debug_overlay_setup.dart. The entire tab is stripped in release builds.

class RecommendationInspectorTab extends ConsumerWidget {
  const RecommendationInspectorTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    assert(kDebugMode);
    final engineAsync = ref.watch(recommendationEngineProvider);

    return engineAsync.when(
      loading: () => const Center(
        child: Text(
          'Scoring…',
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
        if (state.results.isEmpty) {
          return const Center(
            child: Text(
              'No results yet',
              style: TextStyle(color: AppColors.neutral400, fontSize: 12),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.sm),
          children: [
            _Row('Total results', '${state.results.length}'),
            _Row('Scored at', state.lastScoredAt.toIso8601String()),
            _Row('Cold start', state.usedColdStart ? 'yes' : 'no'),
            const Divider(color: AppColors.neutral200),
            for (final r in state.results) ...[
              Text(
                '${r.trackArtist} — ${r.trackTitle}',
                style: const TextStyle(
                  color: AppColors.neutral700,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              _Row(
                'Score',
                r.score.toStringAsFixed(2),
              ),
              _Row(
                'Paths',
                r.provenance.paths
                    .map((p) => _pathLabel(p))
                    .join(', '),
              ),
              _Row('Why', r.provenance.reasonString),
              const SizedBox(height: AppSpacing.xs),
            ],
          ],
        );
      },
    );
  }

  String _pathLabel(ScoringPath p) => switch (p) {
    ScoringPath.trending => 'Trending',
    ScoringPath.affinity => 'Affinity',
    ScoringPath.newFromKnown => 'NewFromKnown',
    ScoringPath.coldStart => 'ColdStart',
  };
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.neutral400, fontSize: 10),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.neutral700,
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
