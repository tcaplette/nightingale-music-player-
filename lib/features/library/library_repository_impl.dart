import 'dart:io';

import 'package:drift/drift.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/core/logging/app_logger.dart';
import 'package:nightingale/features/library/library_repository.dart';
import 'package:nightingale/features/library/models/album_model.dart' as ng;
import 'package:nightingale/features/library/models/artist_model.dart' as ng;
import 'package:nightingale/features/library/models/scan_result.dart';
import 'package:nightingale/features/library/models/track_model.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

const _tag = 'library';

class LibraryRepositoryImpl implements LibraryRepository {
  LibraryRepositoryImpl({required AppDatabase db}) : _db = db;

  final AppDatabase _db;
  final OnAudioQuery _query = OnAudioQuery();

  // ── Permissions ────────────────────────────────────────────────────────────

  Future<bool> _ensureAudioPermission() async {
    final permission = await Permission.audio.request();
    if (permission.isGranted) return true;
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

      // Skip tracks already in DB — preserves user-edited metadata and
      // does NOT change isIncluded for existing tracks.
      if (existingPaths.contains(path)) continue;

      try {
        final artworkPath = await _saveArtwork(song.id);
        final albumId = await _upsertAlbum(song, artworkPath: artworkPath);
        await _upsertArtist(_normalise(song.artist) ?? 'Unknown Artist');
        final title = _normalise(song.title) ?? _titleFromPath(path);
        final artist = _normalise(song.artist) ?? 'Unknown Artist';
        final isrc = await _readIsrc(path);

        // New tracks are NOT auto-included — user must explicitly select them.
        await _db.trackDao.insertTrack(
          TracksTableCompanion.insert(
            filePath: path,
            title: title,
            artist: Value(artist),
            albumId: Value(albumId),
            albumArtist: Value(_normalise(song.artist)),
            trackNumber: Value(song.track == 0 ? null : song.track),
            genre: Value(_normaliseGenre(song.genre)),
            durationMs: Value(song.duration ?? 0),
            artworkPath: Value(artworkPath),
            isrc: Value(isrc),
            isIncluded: const Value(false),
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

  Future<String?> _saveArtwork(int songId) async {
    try {
      final bytes = await _query.queryArtwork(
        songId,
        ArtworkType.AUDIO,
        format: ArtworkFormat.JPEG,
        size: 512,
      );
      if (bytes == null || bytes.isEmpty) return null;
      final dir = await getApplicationDocumentsDirectory();
      final artDir = Directory('${dir.path}/artworks');
      if (!artDir.existsSync()) artDir.createSync(recursive: true);
      final file = File('${artDir.path}/$songId.jpg');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      AppLogger.debug('Artwork extraction failed for song $songId: $e', tag: _tag);
      return null;
    }
  }

  Future<String?> _readIsrc(String filePath) async {
    return null;
  }

  Future<int?> _upsertAlbum(SongModel song, {String? artworkPath}) async {
    final albumName = _normalise(song.album);
    if (albumName == null) return null;
    final artist = _normalise(song.artist) ?? 'Unknown Artist';
    final existing = await _db.albumDao.getAlbumByNameAndArtist(albumName, artist);
    if (existing != null) {
      if (existing.artworkPath == null && artworkPath != null) {
        await _db.albumDao.updateMetadata(existing.id, artworkPath: artworkPath);
      }
      return existing.id;
    }
    return _db.albumDao.upsertAlbum(
      AlbumsTableCompanion.insert(
        name: albumName,
        artist: Value(artist),
        artworkPath: Value(artworkPath),
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

  String? _normaliseGenre(String? value) {
    final trimmed = _normalise(value);
    if (trimmed == null) return null;
    return trimmed[0].toUpperCase() + trimmed.substring(1).toLowerCase();
  }

  String _titleFromPath(String path) {
    final name = path.split('/').last;
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }

  // ── Inclusion mutations ────────────────────────────────────────────────────

  @override
  Future<void> includeTrack(int trackId) =>
      _db.trackDao.setTrackIncluded(trackId, true);

  @override
  Future<void> excludeTrack(int trackId) =>
      _db.trackDao.setTrackIncluded(trackId, false);

  @override
  Future<void> includeAlbum(int albumId) =>
      _db.trackDao.setAlbumTracksIncluded(albumId, true);

  @override
  Future<void> excludeAlbum(int albumId) =>
      _db.trackDao.setAlbumTracksIncluded(albumId, false);

  @override
  Future<void> includeAllTracks() =>
      _db.trackDao.setAllTracksIncluded(true);

  @override
  Future<void> excludeAllTracks() =>
      _db.trackDao.setAllTracksIncluded(false);

  @override
  Future<int> getDiscoveredTrackCount() =>
      _db.trackDao.getDiscoveredTrackCount();

  // ── Library reads ──────────────────────────────────────────────────────────

  Future<List<TrackModel>> _rowsToModels(List<TracksTableData> rows) async {
    final albumIds = rows.map((r) => r.albumId).whereType<int>().toSet();
    final albumNames = <int, String>{};
    final albumArtworkPaths = <int, String?>{};
    for (final id in albumIds) {
      final album = await _db.albumDao.getAlbumById(id);
      if (album != null) {
        albumNames[id] = album.name;
        albumArtworkPaths[id] = album.artworkPath;
      }
    }
    return rows
        .map(
          (r) => TrackModel.fromRow(
            r,
            albumName: r.albumId != null ? albumNames[r.albumId] : null,
            albumArtworkPath: r.albumId != null ? albumArtworkPaths[r.albumId] : null,
          ),
        )
        .toList();
  }

  @override
  Future<List<TrackModel>> getAllTracks() async {
    final rows = await _db.trackDao.getAllTracks();
    return _rowsToModels(rows);
  }

  @override
  Stream<List<TrackModel>> watchAllTracks() {
    return _db.trackDao.watchAllTracks().asyncMap(_rowsToModels);
  }

  @override
  Stream<List<TrackModel>> watchAllDiscoveredTracks() {
    return _db.trackDao.watchAllDiscoveredTracks().asyncMap(_rowsToModels);
  }

  @override
  Stream<List<ng.AlbumModel>> watchDiscoveredAlbums() {
    return _db.albumDao.watchAllDiscoveredAlbums().map(
      (items) => items
          .map(
            (item) => ng.AlbumModel(
              id: item.$1.id,
              name: item.$1.name,
              artist: item.$1.artist,
              artworkPath: item.$1.artworkPath,
              releaseYear: item.$1.releaseYear,
              trackCount: item.$1.trackCount,
              includedTrackCount: item.$2,
            ),
          )
          .toList(),
    );
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
    return _rowsToModels(rows);
  }

  @override
  Stream<List<TrackModel>> watchTracksByAlbum(int albumId) {
    return _db.trackDao.watchTracksByAlbum(albumId).asyncMap(_rowsToModels);
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
      if (albums.isNotEmpty) {
        artists.add(ng.ArtistModel(id: row.id, name: row.name, albumCount: albums.length));
      }
    }
    return artists;
  }

  @override
  Stream<List<ng.ArtistModel>> watchArtists() {
    // Derives from included-tracks stream for full reactivity: updates whenever
    // track inclusion changes, not just when a scan completes.
    return _db.trackDao.watchAllTracks().asyncMap((_) async {
      final rows = await _db.artistDao.getAllArtists();
      final artists = <ng.ArtistModel>[];
      for (final row in rows) {
        final albums = await _db.albumDao.getAlbumsByArtist(row.name);
        if (albums.isNotEmpty) {
          artists.add(ng.ArtistModel(id: row.id, name: row.name, albumCount: albums.length));
        }
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
        .map((t) => _normaliseGenre(t.genre))
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();
  }

  @override
  Stream<List<String>> watchGenres() {
    return _db.trackDao.watchAllTracks().map(
      (tracks) => tracks
          .map((t) => _normaliseGenre(t.genre))
          .whereType<String>()
          .toSet()
          .toList()
          ..sort(),
    );
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
