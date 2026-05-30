import 'package:nightingale/core/activitypub/models/ap_audio.dart';
import 'package:nightingale/core/activitypub/models/ap_collection.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/core/logging/app_logger.dart';
import 'package:nightingale/features/library/library_repository.dart';
import 'package:nightingale/features/library/models/track_model.dart';
import 'package:nightingale/features/node_identity/node_identity_repository.dart';

const _tag = 'library_publisher';

enum SharingScope { private, followersOnly, public }

/// Builds ActivityPub OrderedCollections from the local library for federation.
class LibraryPublisher {
  LibraryPublisher({
    required LibraryRepository libraryRepo,
    required NodeIdentityRepository identityRepo,
    required AppDatabase db,
  })  : _libraryRepo = libraryRepo,
        _identityRepo = identityRepo,
        _db = db;

  final LibraryRepository _libraryRepo;
  final NodeIdentityRepository _identityRepo;
  final AppDatabase _db;

  /// Current sharing scope. Defaults to private (opt-in).
  SharingScope _sharingScope = SharingScope.private;

  SharingScope get sharingScope => _sharingScope;

  void setSharingScope(SharingScope scope) {
    _sharingScope = scope;
    AppLogger.info('Library sharing scope set to $scope', tag: _tag);
  }

  /// Builds the library collection for the given requester.
  /// Returns null if the library is private or the requester is not authorized.
  Future<ApOrderedCollection?> buildCollection({String? requesterActorUrl}) async {
    if (_sharingScope == SharingScope.private) {
      AppLogger.debug('Library is private — denying collection request', tag: _tag);
      return null;
    }

    if (_sharingScope == SharingScope.followersOnly) {
      final isFollower = await _isFollower(requesterActorUrl);
      if (!isFollower) {
        AppLogger.debug(
          'Library is followers-only — requester $requesterActorUrl is not a follower',
          tag: _tag,
        );
        return null;
      }
    }

    final tracks = await _libraryRepo.getAllTracks();
    final actorUrl = await _identityRepo.getActorUrl();

    return ApOrderedCollection(
      id: '$actorUrl/library',
      totalItems: tracks.length,
      first: '$actorUrl/library?page=1',
    );
  }

  /// Builds a collection page containing Audio objects.
  Future<ApOrderedCollectionPage?> buildCollectionPage({
    required int page,
    int pageSize = 50,
    String? requesterActorUrl,
  }) async {
    if (_sharingScope == SharingScope.private) return null;

    if (_sharingScope == SharingScope.followersOnly) {
      final isFollower = await _isFollower(requesterActorUrl);
      if (!isFollower) return null;
    }

    final allTracks = await _libraryRepo.getAllTracks();
    final start = (page - 1) * pageSize;
    if (start >= allTracks.length) {
      return ApOrderedCollectionPage(
        id: '${await _identityRepo.getActorUrl()}/library?page=$page',
        partOf: '${await _identityRepo.getActorUrl()}/library',
        orderedItems: [],
      );
    }

    final end = (start + pageSize).clamp(0, allTracks.length);
    final pageTracks = allTracks.sublist(start, end);
    final actorUrl = await _identityRepo.getActorUrl();

    final audioObjects = pageTracks.map((t) => _trackToAudio(t, actorUrl)).toList();

    return ApOrderedCollectionPage(
      id: '$actorUrl/library?page=$page',
      partOf: '$actorUrl/library',
      orderedItems: audioObjects.map((a) => a.toJson()).toList(),
      next: end < allTracks.length ? '$actorUrl/library?page=${page + 1}' : null,
    );
  }

  ApAudio _trackToAudio(TrackModel track, String actorUrl) {
    return ApAudio(
      id: '$actorUrl/tracks/${track.id}',
      name: track.title,
      artist: track.artist,
      album: track.albumName,
      duration: track.duration,
      url: '$actorUrl/stream/${track.id}',
      artworkUrl: track.artworkPath,
    );
  }

  Future<bool> _isFollower(String? requesterActorUrl) async {
    if (requesterActorUrl == null) return false;
    // Check FollowersTable for the requester
    final row = await (_db.select(_db.followersTable)
          ..where((t) => t.actorUrl.equals(requesterActorUrl)))
        .getSingleOrNull();
    return row != null;
  }

  /// Public method to check if a given actor URL is a follower.
  /// Used by stream handler for privacy enforcement.
  Future<bool> isFollower(String actorUrl) async {
    final row = await (_db.select(_db.followersTable)
          ..where((t) => t.actorUrl.equals(actorUrl)))
        .getSingleOrNull();
    return row != null;
  }
}
