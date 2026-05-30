import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/core/repositories/base_repository.dart';

abstract interface class ActivityRepository implements Repository {
  // ── Now Playing ───────────────────────────────────────────────────────────

  Future<void> emitNowPlaying({
    required String trackId,
    required String trackTitle,
    required String trackArtist,
    required String hostingNodeUrl,
  });

  // ── Like / Unlike ─────────────────────────────────────────────────────────

  Future<void> likeTrack({
    required String trackId,
    required String hostingNodeInbox,
  });

  Future<void> unlikeTrack({
    required String trackId,
    required String hostingNodeInbox,
  });

  Future<bool> isLiked(String trackId);

  // ── Share (Announce) ──────────────────────────────────────────────────────

  Future<void> shareTrack({
    required String trackObjectUrl,
    required String trackTitle,
    required String trackArtist,
  });

  Future<void> sharePlaylist(String playlistCollectionUrl);

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> saveTrack({
    required String trackId,
    required String trackTitle,
    required String trackArtist,
    required String hostingNodeUrl,
  });

  // ── Playlist publish ──────────────────────────────────────────────────────

  Future<int> publishPlaylist({
    required String title,
    required List<String> trackIds,
    required String visibility,
  });

  Future<void> unpublishPlaylist(int playlistRowId);

  Future<List<PlaylistsTableData>> getLocalPlaylists();

  // ── Feed query ────────────────────────────────────────────────────────────

  Future<List<SocialActivitiesTableData>> getFeedPage({
    required int limit,
    required int offset,
    required List<String> excludeActorUrls,
  });

  // ── Incoming activity processing (called from inbox processor) ────────────

  Future<void> processIncomingActivity({
    required String activityId,
    required String type,
    required String actorUrl,
    required dynamic objectData,
    required String rawJson,
    required DateTime publishedAt,
    required bool isFromMuted,
    required bool isHostedLocally,
  });
}
