import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nightingale/core/router/app_router.dart';
import 'package:nightingale/features/discover/widgets/discover_empty_state.dart';
import 'package:nightingale/features/discover/widgets/recommendation_card.dart';
import 'package:nightingale/features/recommendations/domain/provenance_record.dart';
import 'package:nightingale/features/recommendations/domain/recommendation_engine_notifier.dart';
import 'package:nightingale/features/recommendations/domain/recommendation_result.dart';
import 'package:nightingale/features/social/providers/social_graph_notifier.dart';
import 'package:nightingale/shared/theme/app_colors.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/features/recommendations/data/playback_signal_capturer.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Trigger initial scoring pass on first open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recommendationEngineProvider.notifier).rescore();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(recommendationEngineProvider.notifier).rescore();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Re-score when follow count changes (new follow = significant signal)
    ref.listen(
      socialGraphProvider.select((s) => s.following.length),
      (prev, next) {
        if (prev != null && next > prev) {
          ref.read(recommendationEngineProvider.notifier).rescore(force: true);
        }
      },
    );

    final engineAsync = ref.watch(recommendationEngineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
      ),
      body: engineAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Could not load recommendations',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.neutral400),
          ),
        ),
        data: (state) {
          if (state.results.isEmpty) {
            final following = ref.watch(
              socialGraphProvider.select((s) => s.following),
            );
            if (following.isEmpty) {
              return DiscoverEmptyState(
                onFindPeople: () => context.push(AppRoutes.findPeople),
              );
            }
            return const _PendingLibraryState();
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(recommendationEngineProvider.notifier).rescore(force: true),
            child: _ResultList(results: state.results),
          );
        },
      ),
    );
  }
}


class _PendingLibraryState extends StatelessWidget {
  const _PendingLibraryState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.library_music_outlined,
              size: 48,
              color: AppColors.neutral400,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Fetching music from your connections',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Recommendations will appear once your connections\'s libraries are available.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.neutral400,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultList extends StatelessWidget {
  const _ResultList({required this.results});
  final List<RecommendationResult> results;

  @override
  Widget build(BuildContext context) {
    final sections = _groupBySections(results);

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _countItems(sections),
      itemBuilder: (context, index) {
        return _buildItem(context, sections, index);
      },
    );
  }

  // Returns a flat list of (header string | RecommendationResult)
  List<Object> _groupBySections(List<RecommendationResult> results) {
    final trending =
        results.where((r) => r.provenance.paths.contains(ScoringPath.trending)).toList();
    final affinity =
        results.where((r) => r.provenance.paths.contains(ScoringPath.affinity) &&
            !r.provenance.paths.contains(ScoringPath.trending)).toList();
    final newFromKnown =
        results.where((r) => r.provenance.paths.contains(ScoringPath.newFromKnown) &&
            !r.provenance.paths.contains(ScoringPath.trending) &&
            !r.provenance.paths.contains(ScoringPath.affinity)).toList();
    final coldStart =
        results.where((r) => r.provenance.paths.contains(ScoringPath.coldStart)).toList();
    // Anything that didn't land in a named section
    final pathFingerprints = {
      ...trending, ...affinity, ...newFromKnown, ...coldStart
    }.map((r) => r.trackFingerprint).toSet();
    final others = results.where((r) => !pathFingerprints.contains(r.trackFingerprint)).toList();

    final flat = <Object>[];
    void addSection(String header, List<RecommendationResult> items) {
      if (items.isEmpty) return;
      flat.add(header);
      flat.addAll(items);
    }

    addSection('What your people are into', trending);
    addSection('Sounds like you', affinity);
    addSection('From artists you already love', newFromKnown);
    addSection('Explore', coldStart.isEmpty ? others : coldStart);

    return flat;
  }

  int _countItems(List<Object> sections) => sections.length;

  Widget _buildItem(BuildContext context, List<Object> sections, int index) {
    final item = sections[index];
    if (item is String) {
      return _SectionHeader(label: item);
    }
    final result = item as RecommendationResult;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: RecommendationCard(
        result: result,
        onSave: () => _handleSave(result),
      ),
    );
  }

  void _handleSave(RecommendationResult result) {
    sl<PlaybackSignalCapturer>().recordSave(result.trackFingerprint);
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.lg,
        bottom: AppSpacing.sm,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.neutral500,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}
