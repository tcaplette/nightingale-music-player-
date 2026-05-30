import 'dart:async';

import 'package:nightingale/core/logging/app_logger.dart';
import 'package:nightingale/features/federation/library/remote_library_fetcher.dart';
import 'package:nightingale/features/federation/social/social_subscribing_service.dart';
import 'package:nightingale/features/library/models/track_model.dart';

const _tag = 'library_refresh';

/// Background refresh service for remote libraries.
/// 
/// Refreshes cached remote libraries when the app comes to foreground
/// or on a periodic schedule.
class RemoteLibraryRefreshService {
  RemoteLibraryRefreshService({
    required SocialSubscribingService social,
    required RemoteLibraryFetcher fetcher,
  })  : _social = social,
        _fetcher = fetcher;

  final SocialSubscribingService _social;
  final RemoteLibraryFetcher _fetcher;

  Timer? _refreshTimer;

  /// Starts periodic background refresh.
  void startPeriodicRefresh({Duration interval = const Duration(minutes: 30)}) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(interval, (_) => refreshAll());
    AppLogger.info('Started periodic library refresh every ${interval.inMinutes}m', tag: _tag);
  }

  /// Stops periodic refresh.
  void stopPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// Refreshes all followed actors' libraries.
  Future<void> refreshAll() async {
    try {
      final following = await _social.getFollowing();
      AppLogger.info('Refreshing ${following.length} remote libraries', tag: _tag);

      for (final actor in following) {
        try {
          final tracks = await _fetcher.fetchLibrary(actor.actorUrl);
          if (tracks != null) {
            AppLogger.debug(
              'Refreshed library from ${actor.actorUrl}: ${tracks.length} tracks',
              tag: _tag,
            );
          }
        } catch (e) {
          AppLogger.warning(
            'Failed to refresh library from ${actor.actorUrl}: $e',
            tag: _tag,
          );
        }
      }
    } catch (e) {
      AppLogger.error('Library refresh failed: $e', tag: _tag);
    }
  }

  /// Refreshes a single actor's library.
  Future<List<TrackModel>?> refreshActor(String actorUrl) async {
    try {
      return await _fetcher.fetchLibrary(actorUrl);
    } catch (e) {
      AppLogger.warning('Failed to refresh library from $actorUrl: $e', tag: _tag);
      return null;
    }
  }
}
