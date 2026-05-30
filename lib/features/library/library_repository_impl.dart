import 'package:drift/drift.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/core/logging/app_logger.dart';
import 'package:nightingale/features/library/library_repository.dart';
import 'package:nightingale/features/library/models/album_model.dart' as ng;
import 'package:nightingale/features/library/models/artist_model.dart' as ng;
import 'package:nightingale/features/library/models/scan_result.dart';
import 'package:nightingale/features/library/models/track_model.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

const _tag = 'library';

class LibraryRepositoryImpl implements LibraryRepository {
  LibraryRepositoryImpl({required AppDatabase db}) : _db = db;

  final AppDatabase _db;
  final OnAudioQuery _query = OnAudioQuery();

  // ── Permissions ────────────────────────────────────────────────────────────

  /// Requests audio media permission. Returns true if granted.
  Future<bool> _ensureAudioPermission() async {
    final permission = await Permission.audio.request();
    if (permission.isGranted) return true;

    // Fallback for older Android versions that use storage permission
    final storage = await Permission.storage.request();
    return storage.isGranted;
  }

  // ── Scan ───────────────────────────────────────────────────────────────────

  @override
  Future<ScanResult> scanLibrary() async {
    final sw = Stopwatch()..start();
    final errors = <ScanFileError>[];
    int parsed = 0;
    int rejected = 0;

    AppLogger.info('Library scan started', tag: _tag);

    // Check permission before querying to avoid plugin crash
    final hasPermission = await _ensureAudioPermission();
    if (!hasPermission) {
      AppLogger.warning('Audio permission denied — returning empty scan', tag: _tag);
      return ScanResult(
        totalFound: 0,
        parsed: 0,
        rejected: 0,
        errors: [
          const ScanFileError(
            filePath: '',
            reason: 'Audio permission denied — enable in Settings',
          ),
        ],
        durationMs: sw.elapsedMilliseconds,
        completedAt: DateTime.now(),
      );
    }

    List<SongModel> songs;
    try {
      songs = await _query.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );
    } catch (e) {
      AppLogger.error('querySongs failed: $e', tag: _tag);
      return ScanResult(
        totalFound: 0,
        parsed: 0,
        rejected: 0,
        errors: [ScanFileError(filePath: '', reason: 'querySongs failed: $e')],
        durationMs: sw.elapsedMilliseconds,
        completedAt: DateTime.now(),
      );
    }

    AppLogger.debug('Media store returned ${songs.length} songs', tag: _tag);

    final existingPaths = await _db.trackDao.getAllFilePaths();
    final scannedPaths = <String>{};

    for (final song in songs) {
      final path = song.data;
      if (path.isEmpty) {
        rejected++;
        errors.add(const ScanFileError(filePath: '', reason: 'missing path'));
        continue;
      }
      scannedPaths.add(path);

      try {
        final albumId = await _upsertAlbum(song);
        await _upsertArtist(_normalise(song.artist) ?? 'Unknown Artist');
        final title = _normalise(song.title) ?? _titleFromPath(path);
        final artist = _normalise(song.artist) ?? 'Unknown Artist';

        await _db.trackDao.insertTrack(
          TracksTableCompanion.insert(
            filePath: path,
            title: title,
            artist: Value(artist),
            albumId: Value(albumId),
            albumArtist: Value(_normalise(song.artist)),
            trackNumber: Value(song.track),
            genre: Value(_normalise(song.genre)),
            durationMs: Value(song.duration ?? 0),
            artworkPath: const Value(null),
          ),
        );
        parsed++;
      } catch (e) {
        rejected++;
        errors.add(ScanFileError(filePath: path, reason: e.toString()));
        AppLogger.warning('Failed to parse $path: $e', tag: _tag);
      }
    }

    final removedPaths = existingPaths.difference(scannedPaths);
    if (removedPaths.isNotEmpty) {
      await _db.trackDao.deleteTracksWithFilePaths(removedPaths);
      AppLogger.info('Removed ${removedPaths.length} deleted tracks', tag: _tag);
    }

    sw.stop();
    final result = ScanResult(
      totalFound: songs.length,
      parsed: parsed,
      rejected: rejected,
      errors: errors,
      durationMs: sw.elapsedMilliseconds,
      completedAt: DateTime.now(),
    );

    AppLogger.info(
      'Scan complete: ${result.parsed} parsed, '
      '${result.rejected} rejected in ${result.durationMs}ms',
      tag: _tag,
    );

    return result;
  }

  Future<int?> _upsertAlbum(SongModel song) async {
    final albumName = _normalise(song.album);
    if (albumName == null) return null;
    final artist = _normalise(song.artist) ?? 'Unknown Artist';
    final existing = await _db.albumDao.getAlbumByNameAndArtist(albumName, artist);
    if (existing != null) return existing.id;
    return _db.albumDao.upsertAlbum(
      AlbumsTableCompanion.insert(
        name: albumName,
        artist: Value(artist),
      ),
    );
  }

  Future<void> _upsertArtist(String name) async {
    await _db.artistDao.upsertArtist(ArtistsTableCompanion.insert(name: name));
  }

  String? _normalise(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return value.trim();
  }

  String _titleFromPath(String path) {
    final name = path.split('/').last;
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }

  // ── Reads ──────────────────────────────────────────────────────────────────

  @override
  Future<List<TrackModel>> getAllTracks() async {
    final rows = await _db.trackDao.getAllTracks();
    return rows.map((r) => TrackModel.fromRow(r)).toList();
  }

  @override
  Stream<List<TrackModel>> watchAllTracks() {
    return _db.trackDao
        .watchAllTracks()
        .map((rows) => rows.map((r) => TrackModel.fromRow(r)).toList());
  }

  @override
  Future<List<ng.AlbumModel>> getAlbums() async {
    final rows = await _db.albumDao.getAllAlbums();
    return rows.map(ng.AlbumModel.fromRow).toList();
  }

  @override
  Stream<List<ng.AlbumModel>> watchAlbums() {
    return _db.albumDao
        .watchAllAlbums()
        .map((rows) => rows.map(ng.AlbumModel.fromRow).toList());
  }

  @override
  Future<List<TrackModel>> getTracksByAlbum(int albumId) async {
    final rows = await _db.trackDao.getTracksByAlbum(albumId);
    return rows.map((r) => TrackModel.fromRow(r)).toList();
  }

  @override
  Future<ng.AlbumModel?> getAlbumById(int albumId) async {
    final row = await _db.albumDao.getAlbumById(albumId);
    return row == null ? null : ng.AlbumModel.fromRow(row);
  }

  @override
  Future<List<ng.ArtistModel>> getArtists() async {
    final rows = await _db.artistDao.getAllArtists();
    final artists = <ng.ArtistModel>[];
    for (final row in rows) {
      final albums = await _db.albumDao.getAlbumsByArtist(row.name);
      artists.add(ng.ArtistModel(
        id: row.id,
        name: row.name,
        albumCount: albums.length,
      ));
    }
    return artists;
  }

  @override
  Stream<List<ng.ArtistModel>> watchArtists() {
    return _db.artistDao.watchAllArtists().asyncMap((rows) async {
      final artists = <ng.ArtistModel>[];
      for (final row in rows) {
        final albums = await _db.albumDao.getAlbumsByArtist(row.name);
        artists.add(ng.ArtistModel(
          id: row.id,
          name: row.name,
          albumCount: albums.length,
        ));
      }
      return artists;
    });
  }

  @override
  Future<List<ng.AlbumModel>> getAlbumsByArtist(String artist) async {
    final rows = await _db.albumDao.getAlbumsByArtist(artist);
    return rows.map(ng.AlbumModel.fromRow).toList();
  }

  @override
  Future<List<TrackModel>> getTracksByArtist(String artist) async {
    final rows = await _db.trackDao.getTracksByArtist(artist);
    return rows.map((r) => TrackModel.fromRow(r)).toList();
  }

  @override
  Future<List<String>> getGenres() async {
    final tracks = await _db.trackDao.getAllTracks();
    return tracks
        .map((t) => t.genre)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();
  }

  @override
  Future<List<TrackModel>> getTracksByGenre(String genre) async {
    final rows = await _db.trackDao.getTracksByGenre(genre);
    return rows.map((r) => TrackModel.fromRow(r)).toList();
  }

  @override
  Future<({
    List<TrackModel> tracks,
    List<ng.AlbumModel> albums,
    List<ng.ArtistModel> artists,
  })>
  searchLibrary(String query) async {
    if (query.trim().isEmpty) {
      return (
        tracks: <TrackModel>[],
        albums: <ng.AlbumModel>[],
        artists: <ng.ArtistModel>[],
      );
    }
    final trackRows = await _db.trackDao.searchTracks(query);
    final albumRows = await _db.albumDao.searchAlbums(query);
    final artistRows = await _db.artistDao.searchArtists(query);
    return (
      tracks: trackRows.map((r) => TrackModel.fromRow(r)).toList(),
      albums: albumRows.map(ng.AlbumModel.fromRow).toList(),
      artists: artistRows
          .map((r) => ng.ArtistModel(id: r.id, name: r.name))
          .toList(),
    );
  }
}
