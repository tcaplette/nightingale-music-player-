import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/features/federation/publishing/library_publisher.dart';
import 'package:nightingale/features/library/library_repository.dart';
import 'package:nightingale/features/library/models/album_model.dart';
import 'package:nightingale/features/library/models/artist_model.dart';
import 'package:nightingale/features/library/models/scan_result.dart';
import 'package:nightingale/features/library/models/track_model.dart';

// ── Scan state ─────────────────────────────────────────────────────────────

enum LibraryScanStatus { idle, scanning, done, error }

class LibraryScanState {
  const LibraryScanState({
    required this.status,
    this.lastResult,
    this.error,
    this.isMediaStorePotentiallyStale = false,
  });

  final LibraryScanStatus status;
  final ScanResult? lastResult;
  final Object? error;
  final bool isMediaStorePotentiallyStale;

  LibraryScanState copyWith({
    LibraryScanStatus? status,
    ScanResult? lastResult,
    Object? error,
    bool? isMediaStorePotentiallyStale,
  }) {
    return LibraryScanState(
      status: status ?? this.status,
      lastResult: lastResult ?? this.lastResult,
      error: error ?? this.error,
      isMediaStorePotentiallyStale:
          isMediaStorePotentiallyStale ?? this.isMediaStorePotentiallyStale,
    );
  }
}

class LibraryScanNotifier extends Notifier<LibraryScanState> {
  @override
  LibraryScanState build() => const LibraryScanState(
    status: LibraryScanStatus.idle,
  );

  Future<void> scan() async {
    if (state.status == LibraryScanStatus.scanning) return;
    state = state.copyWith(status: LibraryScanStatus.scanning);
    try {
      final repo = sl<LibraryRepository>();
      final result = await repo.scanLibrary();
      state = LibraryScanState(
        status: LibraryScanStatus.done,
        lastResult: result,
        isMediaStorePotentiallyStale: result.rejected > 0,
      );
    } catch (e) {
      state = LibraryScanState(
        status: LibraryScanStatus.error,
        error: e,
      );
    }
  }
}

final libraryScanProvider =
    NotifierProvider<LibraryScanNotifier, LibraryScanState>(
      LibraryScanNotifier.new,
    );

// ── Library data providers ─────────────────────────────────────────────────

final allTracksProvider = StreamProvider<List<TrackModel>>((ref) {
  ref.watch(libraryScanProvider);
  return sl<LibraryRepository>().watchAllTracks();
});

final albumsProvider = StreamProvider<List<AlbumModel>>((ref) {
  ref.watch(libraryScanProvider);
  return sl<LibraryRepository>().watchAlbums();
});

final artistsProvider = StreamProvider<List<ArtistModel>>((ref) {
  ref.watch(libraryScanProvider);
  return sl<LibraryRepository>().watchArtists();
});

final genresProvider = StreamProvider<List<String>>((ref) {
  ref.watch(libraryScanProvider);
  return sl<LibraryRepository>().watchGenres();
});

// ── Discovery providers (all tracks/albums regardless of inclusion) ──────────

final discoveredTracksProvider = StreamProvider<List<TrackModel>>((ref) {
  ref.watch(libraryScanProvider);
  return sl<LibraryRepository>().watchAllDiscoveredTracks();
});

final discoveredAlbumsProvider = StreamProvider<List<AlbumModel>>((ref) {
  ref.watch(libraryScanProvider);
  return sl<LibraryRepository>().watchDiscoveredAlbums();
});

/// Count of tracks discovered on device but not yet included in the library.
/// Reactive: updates when the user selects or deselects tracks.
final discoveredTrackCountProvider = StreamProvider<int>((ref) {
  return sl<LibraryRepository>().watchAllDiscoveredTracks().map(
    (tracks) => tracks.where((t) => !t.isIncluded).length,
  );
});

// Album name + artist pair used as family key
typedef AlbumKey = ({String albumName, String albumArtist});

final albumDetailProvider =
    FutureProvider.family<AlbumModel?, AlbumKey>((ref, key) {
      return sl<LibraryRepository>().getAlbumByNameAndArtist(
        key.albumName,
        key.albumArtist,
      );
    });

final albumTracksProvider =
    StreamProvider.family<List<TrackModel>, AlbumKey>((ref, key) {
      return sl<LibraryRepository>().watchTracksByAlbum(
        key.albumName,
        key.albumArtist,
      );
    });

final artistAlbumsProvider =
    FutureProvider.family<List<AlbumModel>, String>((ref, artist) {
      return sl<LibraryRepository>().getAlbumsByArtist(artist);
    });

final artistTracksProvider =
    FutureProvider.family<List<TrackModel>, String>((ref, artist) {
      return sl<LibraryRepository>().getTracksByArtist(artist);
    });

final genreTracksProvider =
    FutureProvider.family<List<TrackModel>, String>((ref, genre) {
      return sl<LibraryRepository>().getTracksByGenre(genre);
    });

/// True when the user's library is set to public or followers-only sharing.
/// Used to determine whether to show metadata completeness badges.
final isSharingActiveProvider = Provider<bool>((ref) {
  final publisher = sl<LibraryPublisher>();
  return publisher.sharingScope != SharingScope.private;
});

// ── Search ─────────────────────────────────────────────────────────────────

class SearchQuery {
  const SearchQuery(this.query);
  final String query;
}

final searchResultsProvider = FutureProvider.family<
  ({
    List<TrackModel> tracks,
    List<AlbumModel> albums,
    List<ArtistModel> artists,
  }),
  String
>((ref, query) => sl<LibraryRepository>().searchLibrary(query));
