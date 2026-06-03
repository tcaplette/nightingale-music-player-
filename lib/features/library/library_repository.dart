import 'package:nightingale/features/library/models/album_model.dart';
import 'package:nightingale/features/library/models/artist_model.dart';
import 'package:nightingale/features/library/models/scan_result.dart';
import 'package:nightingale/features/library/models/track_model.dart';

abstract interface class LibraryRepository {
  Future<ScanResult> scanLibrary();

  // ── Library reads (isIncluded = true only) ─────────────────────────────────

  Future<List<TrackModel>> getAllTracks();
  Stream<List<TrackModel>> watchAllTracks();

  Future<List<AlbumModel>> getAlbums();
  Stream<List<AlbumModel>> watchAlbums();

  Future<List<ArtistModel>> getArtists();
  Stream<List<ArtistModel>> watchArtists();

  Future<List<String>> getGenres();
  Stream<List<String>> watchGenres();

  Future<List<TrackModel>> getTracksByAlbum(int albumId);
  Stream<List<TrackModel>> watchTracksByAlbum(int albumId);

  Future<AlbumModel?> getAlbumById(int albumId);

  Future<List<AlbumModel>> getAlbumsByArtist(int artistId);
  Future<List<TrackModel>> getTracksByArtist(int artistId);
  Future<ArtistModel?> getArtistById(int artistId);
  Future<List<TrackModel>> getTracksByGenre(String genre);

  Future<({
    List<TrackModel> tracks,
    List<AlbumModel> albums,
    List<ArtistModel> artists,
  })>
  searchLibrary(String query);

  // ── Discovery reads (all tracks regardless of isIncluded) ──────────────────

  Stream<List<TrackModel>> watchAllDiscoveredTracks();
  Stream<List<AlbumModel>> watchDiscoveredAlbums();
  Future<int> getDiscoveredTrackCount();

  // ── Inclusion mutations ────────────────────────────────────────────────────

  Future<void> includeTrack(int trackId);
  Future<void> excludeTrack(int trackId);
  Future<void> includeAlbum(int albumId);
  Future<void> excludeAlbum(int albumId);
  Future<void> includeAllTracks();
  Future<void> excludeAllTracks();
}
