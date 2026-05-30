import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/core/repositories/activity_repository.dart';
import 'package:nightingale/core/repositories/social_repository.dart';

const _pageSize = 50;

class FeedHydrationEntry {
  const FeedHydrationEntry({
    required this.activityId,
    required this.type,
    required this.actorUrl,
    required this.disposition,
    required this.filterReason,
    required this.timestamp,
  });

  final String activityId;
  final String type;
  final String actorUrl;
  // 'rendered' | 'filtered'
  final String disposition;
  final String? filterReason;
  final DateTime timestamp;
}

class SocialFeedState {
  const SocialFeedState({
    this.items = const [],
    this.isLoading = false,
    this.isOffline = false,
    this.hasMore = true,
    this.hydrationLog = const [],
  });

  final List<SocialActivitiesTableData> items;
  final bool isLoading;
  final bool isOffline;
  final bool hasMore;
  final List<FeedHydrationEntry> hydrationLog;

  SocialFeedState copyWith({
    List<SocialActivitiesTableData>? items,
    bool? isLoading,
    bool? isOffline,
    bool? hasMore,
    List<FeedHydrationEntry>? hydrationLog,
  }) =>
      SocialFeedState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        isOffline: isOffline ?? this.isOffline,
        hasMore: hasMore ?? this.hasMore,
        hydrationLog: hydrationLog ?? this.hydrationLog,
      );
}

class SocialFeedNotifier extends StateNotifier<SocialFeedState> {
  SocialFeedNotifier(this._activityRepo, this._socialRepo)
      : super(const SocialFeedState()) {
    refresh();
  }

  final ActivityRepository _activityRepo;
  final SocialRepository _socialRepo;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, hydrationLog: []);
    await _load(offset: 0, append: false);
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;
    await _load(offset: state.items.length, append: true);
  }

  Future<void> _load({required int offset, required bool append}) async {
    final blocks = (await _socialRepo.getBlocks()).map((b) => b.actorUrl).toList();
    final mutes = (await _socialRepo.getMutes()).map((m) => m.actorUrl).toList();
    final exclude = {...blocks, ...mutes}.toList();

    final raw = await _activityRepo.getFeedPage(
      limit: _pageSize,
      offset: offset,
      excludeActorUrls: exclude,
    );

    final hydrationLog = <FeedHydrationEntry>[];
    final rendered = <SocialActivitiesTableData>[];

    for (final item in raw) {
      final isBlocked = blocks.contains(item.actorUrl);
      final isMuted = mutes.contains(item.actorUrl);

      if (isBlocked || isMuted) {
        hydrationLog.add(FeedHydrationEntry(
          activityId: item.activityId,
          type: item.type,
          actorUrl: item.actorUrl,
          disposition: 'filtered',
          filterReason: isBlocked ? 'blocked' : 'muted',
          timestamp: DateTime.now(),
        ));
      } else {
        rendered.add(item);
        hydrationLog.add(FeedHydrationEntry(
          activityId: item.activityId,
          type: item.type,
          actorUrl: item.actorUrl,
          disposition: 'rendered',
          filterReason: null,
          timestamp: DateTime.now(),
        ));
      }
    }

    state = state.copyWith(
      items: append ? [...state.items, ...rendered] : rendered,
      isLoading: false,
      hasMore: raw.length == _pageSize,
      hydrationLog: append
          ? [...state.hydrationLog, ...hydrationLog]
          : hydrationLog,
    );
  }
}

final socialFeedProvider =
    StateNotifierProvider<SocialFeedNotifier, SocialFeedState>(
  (ref) => SocialFeedNotifier(
    sl<ActivityRepository>(),
    sl<SocialRepository>(),
  ),
);
