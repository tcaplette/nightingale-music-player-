import 'package:drift/drift.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/core/logging/app_logger.dart';
import 'package:nightingale/features/library/library_repository.dart';
import 'package:nightingale/features/library/models/album_model.dart';
import 'package:nightingale/features/library/models/artist_model.dart';
import 'package:nightingale/features/library/models/scan_result.dart';
import 'package:nightingale/features/library/models/track_model.dart';
import 'package:on_audio_query/on_audio_query.dart' hide AlbumModel, ArtistModel;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

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

      if (song.isAlarm == true || song.isNotification == true || song.isRingtone == true) {
        rejected++;
        AppLogger.debug('Skipping system sound: $path', tag: _tag);
        continue;
      }

      scannedPaths.add(path);

      // Skip tracks already in DB — preserves user-edited metadata and
      // does NOT change isIncluded for existing tracks.
      if (existingPaths.contains(path)) continue;

      try {
        final artworkPath = await _saveArtwork(song.id);
        final title = _normalise(song.title) ?? _titleFromPath(path);
        final rawArtist = _normalise(song.artist);
        final artist = (rawArtist == null || rawArtist.toLowerCase() == '<unknown>')
            ? 'Unknown Artist'
            : rawArtist;
        final albumName = _normalise(song.album);
        final albumArtist = artist;
        final isrc = await _readIsrc(path);

        // New tracks are NOT auto-included — user must explicitly select them.
        await _db.trackDao.insertTrack(
          TracksTableCompanion.insert(
            filePath: path,
            title: title,
            artist: Value(artist),
            albumName: Value(albumName),
            albumArtist: Value(albumArtist),
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
  Future<void> includeAlbum(String albumName, String? albumArtist) =>
      _db.trackDao.setAlbumTracksIncluded(albumName, albumArtist, true);

  @override
  Future<void> excludeAlbum(String albumName, String? albumArtist) =>
      _db.trackDao.setAlbumTracksIncluded(albumName, albumArtist, false);

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

  @override
  Future<List<TrackModel>> getAllTracks() async {
    final rows = await _db.trackDao.getAllTracks();
    return rows.map(TrackModel.fromRow).toList();
  }

  @override
  Stream<List<TrackModel>> watchAllTracks() =>
      _db.trackDao.watchAllTracks().map((rows) => rows.map(TrackModel.fromRow).toList());

  @override
  Stream<List<TrackModel>> watchAllDiscoveredTracks() =>
      _db.trackDao.watchAllDiscoveredTracks().map((rows) => rows.map(TrackModel.fromRow).toList());

  @override
  Stream<List<AlbumModel>> watchDiscoveredAlbums() =>
      _db.trackDao.watchAllDiscoveredAlbums().map(
        (rows) => rows.map((row) => AlbumModel(
          name: row.read<String>('album_name'),
          artist: row.readNullable<String>('album_artist') ?? 'Unknown Artist',
          artworkPath: row.readNullable<String>('artwork_path'),
          releaseYear: row.readNullable<int>('release_year'),
          trackCount: row.read<int>('track_count'),
          includedTrackCount: row.read<int>('included_count'),
        )).toList(),
      );

  @override
  Future<List<AlbumModel>> getAlbums() async {
    final rows = await _db.trackDao.watchAllAlbums().first;
    return rows.map(_albumFromRow).toList();
  }

  @override
  Stream<List<AlbumModel>> watchAlbums() =>
      _db.trackDao.watchAllAlbums().map((rows) => rows.map(_albumFromRow).toList());

  @override
  Stream<List<TrackModel>> watchTracksByAlbum(String albumName, String? albumArtist) =>
      _db.trackDao.watchTracksByAlbum(albumName, albumArtist).map(
        (rows) => rows.map(TrackModel.fromRow).toList(),
      );

  @override
  Future<AlbumModel?> getAlbumByNameAndArtist(
    String albumName,
    String? albumArtist,
  ) async {
    final row = await _db.trackDao.getAlbumByNameAndArtist(albumName, albumArtist);
    return row == null ? null : _albumFromRow(row);
  }

  @override
  Future<List<ArtistModel>> getArtists() async {
    final rows = await _db.trackDao.watchAllArtists().first;
    return rows.map(_artistFromRow).toList();
  }

  @override
  Stream<List<ArtistModel>> watchArtists() =>
      _db.trackDao.watchAllArtists().map((rows) => rows.map(_artistFromRow).toList());

  @override
  Future<List<AlbumModel>> getAlbumsByArtist(String artist) async {
    final rows = await _db.trackDao.getAlbumsByArtist(artist);
    return rows.map(_albumFromRow).toList();
  }

  @override
  Future<List<TrackModel>> getTracksByArtist(String artist) async {
    final rows = await _db.trackDao.getTracksByArtist(artist);
    return rows.map(TrackModel.fromRow).toList();
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
  Stream<List<String>> watchGenres() =>
      _db.trackDao.watchAllTracks().map(
        (tracks) => tracks
            .map((t) => _normaliseGenre(t.genre))
            .whereType<String>()
            .toSet()
            .toList()
            ..sort(),
      );

  @override
  Future<List<TrackModel>> getTracksByGenre(String genre) async {
    final rows = await _db.trackDao.getTracksByGenre(genre);
    return rows.map(TrackModel.fromRow).toList();
  }

  @override
  Future<({
    List<TrackModel> tracks,
    List<AlbumModel> albums,
    List<ArtistModel> artists,
  })>
  searchLibrary(String query) async {
    if (query.trim().isEmpty) {
      return (
        tracks: <TrackModel>[],
        albums: <AlbumModel>[],
        artists: <ArtistModel>[],
      );
    }
    final trackRows = await _db.trackDao.searchTracks(query);
    final albumRows = await _db.trackDao.searchAlbums(query);
    final artistRows = await _db.trackDao.searchArtists(query);
    return (
      tracks: trackRows.map(TrackModel.fromRow).toList(),
      albums: albumRows.map(_albumFromRow).toList(),
      artists: artistRows
          .map((r) => ArtistModel(name: r.read<String>('artist')))
          .toList(),
    );
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  AlbumModel _albumFromRow(dynamic row) {
    return AlbumModel(
      name: row.read<String>('album_name'),
      artist: row.readNullable<String>('album_artist') ?? 'Unknown Artist',
      artworkPath: row.readNullable<String>('artwork_path'),
      releaseYear: row.readNullable<int>('release_year'),
      trackCount: row.read<int>('track_count'),
    );
  }

  ArtistModel _artistFromRow(dynamic row) {
    return ArtistModel(
      name: row.read<String>('artist'),
      albumCount: row.read<int>('album_count'),
    );
  }
}
