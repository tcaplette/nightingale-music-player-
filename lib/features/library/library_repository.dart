import 'package:nightingale/features/library/models/album_model.dart';
import 'package:nightingale/features/library/models/artist_model.dart';
import 'package:nightingale/features/library/models/scan_result.dart';
import 'package:nightingale/features/library/models/track_model.dart';

abstract interface class LibraryRepository {
  Future<ScanResult> scanLibrary();

  Future<List<TrackModel>> getAllTracks();

  Stream<List<TrackModel>> watchAllTracks();

  Future<List<AlbumModel>> getAlbums();

  Stream<List<AlbumModel>> watchAlbums();

  Future<List<TrackModel>> getTracksByAlbum(int albumId);

  Future<AlbumModel?> getAlbumById(int albumId);

  Future<List<ArtistModel>> getArtists();

  Stream<List<ArtistModel>> watchArtists();

  Future<List<AlbumModel>> getAlbumsByArtist(String artist);

  Future<List<TrackModel>> getTracksByArtist(String artist);

  Future<List<String>> getGenres();

  Future<List<TrackModel>> getTracksByGenre(String genre);

  Future<({
    List<TrackModel> tracks,
    List<AlbumModel> albums,
    List<ArtistModel> artists,
  })>
  searchLibrary(String query);
}
