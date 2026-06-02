import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:http/http.dart' as http;
import 'package:metadata_god/metadata_god.dart' as mg;
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/core/logging/app_logger.dart';
import 'package:nightingale/features/library/models/album_model.dart';
import 'package:nightingale/features/library/models/track_model.dart';
import 'package:nightingale/features/library/services/metadata_lookup_service.dart';

const _tag = 'album_batch_fetch';
const _userAgent = 'Nightingale/1.0 (music-player; contact@nightingale.app)';
const _timeout = Duration(seconds: 10);
const _lookup = MetadataLookupService();

// ── Data classes ──────────────────────────────────────────────────────────────

class MbTrackEntry {
  const MbTrackEntry({
    required this.title,
    required this.durationMs,
    required this.trackNumber,
    this.discNumber,
  });

  final String title;
  final int durationMs;
  final int trackNumber;
  final int? discNumber;
}

class AlbumLookupResult {
  const AlbumLookupResult({
    required this.tracks,
    this.albumName,
    this.artist,
    this.genre,
    this.releaseYear,
    this.artworkUrl,
    required this.source,
  });

  final List<MbTrackEntry> tracks;
  final String? albumName; // confirmed name from the matched release
  final String? artist;    // confirmed artist from the matched release
  final String? genre;
  final int? releaseYear;
  final String? artworkUrl;
  final String source;
}

class AlbumPreviewResult {
  const AlbumPreviewResult({required this.lookup, this.artworkPath});

  final AlbumLookupResult lookup;
  final String? artworkPath; // locally downloaded preview image
}

class AlbumFetchResult {
  const AlbumFetchResult({
    required this.totalTracks,
    required this.matched,
    required this.unmatched,
    required this.errors,
  });

  final int totalTracks;
  final List<TrackModel> matched;
  final List<TrackModel> unmatched;
  final Map<TrackModel, String> errors;

  bool get noDataFound => matched.isEmpty && unmatched.length == totalTracks && errors.isEmpty;
}

// ── Service ───────────────────────────────────────────────────────────────────

class AlbumMetadataFetchService {
  AlbumMetadataFetchService({required AppDatabase db}) : _db = db;

  final AppDatabase _db;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Persists corrected album name and artist to the DB.
  /// Called before a search so the album record stays in sync with what the
  /// user typed in the fetch sheet.
  Future<void> saveAlbumIdentity(
    int albumId, {
    required String name,
    required String artist,
  }) =>
      _db.albumDao.updateNameAndArtist(albumId, name: name, artist: artist);

  /// Looks up album metadata and downloads artwork for preview — no writes.
  Future<AlbumPreviewResult?> previewAlbum(
    String albumName,
    String artist,
    int albumId, {
    int? expectedTrackCount,
  }) async {
    final result = await _lookupRelease(
      albumName.trim(),
      artist.trim(),
      expectedTrackCount: expectedTrackCount,
    );
    if (result == null) return null;
    String? artworkPath;
    if (result.artworkUrl != null) {
      artworkPath =
          await _lookup.downloadArtwork(result.artworkUrl!, albumId);
    }
    return AlbumPreviewResult(lookup: result, artworkPath: artworkPath);
  }

  Future<AlbumFetchResult> fetch(
    AlbumModel album,
    List<TrackModel> tracks, {
    String? albumNameOverride,
    String? artistOverride,
    String? preloadedArtworkPath,
  }) async {
    if (tracks.isEmpty) {
      return const AlbumFetchResult(
        totalTracks: 0,
        matched: [],
        unmatched: [],
        errors: {},
      );
    }

    final resolvedName = (albumNameOverride != null &&
            albumNameOverride.trim().isNotEmpty)
        ? albumNameOverride.trim()
        : album.name;
    final resolvedArtist =
        (artistOverride != null && artistOverride.trim().isNotEmpty)
            ? artistOverride.trim()
            : album.artist;

    final matched = <TrackModel>[];
    final unmatched = <TrackModel>[];
    final errors = <TrackModel, String>{};

    // 1. MusicBrainz release lookup (with iTunes merge for gaps)
    final albumResult = await _lookupRelease(
      resolvedName,
      resolvedArtist,
      expectedTrackCount: tracks.length,
    );

    if (albumResult == null) {
      AppLogger.debug(
        'No release data found for "$resolvedName" by $resolvedArtist',
        tag: _tag,
      );
      return AlbumFetchResult(
        totalTracks: tracks.length,
        matched: const [],
        unmatched: List.of(tracks),
        errors: const {},
      );
    }

    // 2. Use preloaded artwork from preview if available; otherwise download.
    // Reusing the preview artwork avoids a second Cover Art Archive round-trip
    // (which can fail or return a different result).
    String? artworkPath = preloadedArtworkPath;
    if (artworkPath == null && albumResult.artworkUrl != null) {
      artworkPath = await _lookup.downloadArtwork(
        albumResult.artworkUrl!,
        album.id,
      );
    }

    // 3. Update album row with all resolved values (name, artist, artwork, year)
    await _updateAlbumRecord(
      album,
      albumResult,
      artworkPath,
      resolvedName: resolvedName,
      resolvedArtist: resolvedArtist,
    );

    // 4. Match and apply per track
    if (albumResult.tracks.isNotEmpty) {
      final (matchMap, unmatchedList) =
          _matchTracks(tracks, albumResult.tracks);
      unmatched.addAll(unmatchedList);

      for (final entry in matchMap.entries) {
        final track = entry.key;
        try {
          await _writeFields(
            track: track,
            newGenre: albumResult.genre,
            newYear: albumResult.releaseYear,
            newArtworkPath: artworkPath,
            resolvedAlbumName: resolvedName,
            resolvedAlbumArtist: resolvedArtist,
          );
          matched.add(track);
        } catch (e) {
          AppLogger.warning(
            'Failed to apply match for "${track.title}": $e',
            tag: _tag,
          );
          errors[track] = e.toString();
        }
      }

      // Unmatched tracks still get album-level fields (artist, artwork, genre, year).
      // We couldn't confirm their individual track data but they belong to this album.
      for (final track in unmatchedList) {
        try {
          await _writeFields(
            track: track,
            newGenre: albumResult.genre,
            newYear: albumResult.releaseYear,
            newArtworkPath: artworkPath,
            resolvedAlbumName: resolvedName,
            resolvedAlbumArtist: resolvedArtist,
          );
        } catch (e) {
          errors[track] = e.toString();
        }
      }
    } else {
      // No MusicBrainz track listing — apply album-level fields to all tracks
      for (final track in tracks) {
        try {
          await _writeFields(
            track: track,
            newGenre: albumResult.genre,
            newYear: albumResult.releaseYear,
            newArtworkPath: artworkPath,
            resolvedAlbumName: resolvedName,
            resolvedAlbumArtist: resolvedArtist,
          );
          matched.add(track);
        } catch (e) {
          errors[track] = e.toString();
        }
      }
    }

    return AlbumFetchResult(
      totalTracks: tracks.length,
      matched: matched,
      unmatched: unmatched,
      errors: errors,
    );
  }

  // ── MusicBrainz Release Lookup ────────────────────────────────────────────

  Future<AlbumLookupResult?> _lookupRelease(
    String albumName,
    String artist, {
    int? expectedTrackCount,
  }) async {
    try {
      // Lowercase both values — MusicBrainz Lucene is technically case-insensitive
      // but mixed-case inputs can produce zero results in practice. Escaping
      // internal quotes prevents malformed Lucene syntax.
      final safeAlbum = albumName.toLowerCase().replaceAll('"', r'\"');
      final safeArtist = artist.toLowerCase().replaceAll('"', r'\"');
      final query = Uri.encodeComponent(
        'release:"$safeAlbum" AND artist:"$safeArtist"',
      );
      final uri = Uri.parse(
        'https://musicbrainz.org/ws/2/release'
        '?query=$query&inc=recordings+tags&fmt=json&limit=5',
      );

      final response = await http
          .get(uri, headers: {'User-Agent': _userAgent})
          .timeout(_timeout);

      if (response.statusCode == 429 || response.statusCode == 503) {
        AppLogger.warning(
          'MusicBrainz rate limited (${response.statusCode}), trying iTunes',
          tag: _tag,
        );
        return await _lookupItunesAlbum(albumName, artist);
      }
      if (response.statusCode != 200) {
        AppLogger.warning(
          'MusicBrainz release search ${response.statusCode}',
          tag: _tag,
        );
        return await _lookupItunesAlbum(albumName, artist);
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final releases =
          (data['releases'] as List?)?.cast<Map<String, dynamic>>();
      if (releases == null || releases.isEmpty) {
        return await _lookupItunesAlbum(albumName, artist);
      }

      // Pick best release: score by track count match + official status
      final release = _pickBestRelease(releases, expectedTrackCount);

      final mbid = release['id'] as String?;
      final releaseYear = _parseYear(release['date'] as String?);
      final mbAlbumName = release['title'] as String?;

      // Artist from artist-credit array: join all credited names
      final mbArtist = _extractArtistCredit(release);

      // Genre from release tags (highest-count tag wins)
      final tags =
          (release['tags'] as List?)?.cast<Map<String, dynamic>>();
      String? genre;
      if (tags != null && tags.isNotEmpty) {
        final sorted = List.of(tags)
          ..sort((a, b) =>
              ((b['count'] as num?)?.toInt() ?? 0)
                  .compareTo((a['count'] as num?)?.toInt() ?? 0));
        genre = sorted.first['name'] as String?;
      }

      // Track listing from media
      final mbTracks = _extractTrackListing(release);

      // Artwork from Cover Art Archive
      String? artworkUrl;
      if (mbid != null) {
        artworkUrl = await _fetchReleaseArtwork(mbid);
      }

      // Merge iTunes if any album-level field is missing
      final mbComplete =
          genre != null && releaseYear != null && artworkUrl != null;
      if (!mbComplete) {
        final itunes = await _lookupItunesAlbum(albumName, artist);
        if (itunes != null) {
          return AlbumLookupResult(
            tracks: mbTracks,
            albumName: mbAlbumName ?? itunes.albumName,
            artist: mbArtist ?? itunes.artist,
            genre: genre ?? itunes.genre,
            releaseYear: releaseYear ?? itunes.releaseYear,
            artworkUrl: artworkUrl ?? itunes.artworkUrl,
            source: 'MusicBrainz + iTunes',
          );
        }
      }

      return AlbumLookupResult(
        tracks: mbTracks,
        albumName: mbAlbumName,
        artist: mbArtist,
        genre: genre,
        releaseYear: releaseYear,
        artworkUrl: artworkUrl,
        source: 'MusicBrainz',
      );
    } catch (e) {
      AppLogger.warning('MusicBrainz release lookup error: $e', tag: _tag);
      return await _lookupItunesAlbum(albumName, artist);
    }
  }

  static Map<String, dynamic> _pickBestRelease(
    List<Map<String, dynamic>> releases,
    int? expectedTrackCount,
  ) {
    if (releases.length == 1) return releases.first;

    Map<String, dynamic>? best;
    int bestScore = -1;

    for (final r in releases) {
      int score = 0;
      if ((r['status'] as String?)?.toLowerCase() == 'official') score += 2;

      if (expectedTrackCount != null) {
        final totalTracks = _countReleaseTracks(r);
        if (totalTracks > 0) {
          if (totalTracks == expectedTrackCount) {
            score += 4;
          } else if ((totalTracks - expectedTrackCount).abs() == 1) {
            score += 1;
          }
        }
      }

      if (score > bestScore) {
        bestScore = score;
        best = r;
      }
    }

    return best ?? releases.first;
  }

  /// Counts the total number of tracks across all media in a release.
  /// Uses the `track-count` field when available, falls back to counting the
  /// `tracks` array — the search API sometimes omits the field but includes
  /// the full track list.
  static int _countReleaseTracks(Map<String, dynamic> release) {
    final media = (release['media'] as List?)?.cast<Map<String, dynamic>>();
    if (media == null || media.isEmpty) return 0;
    return media.fold<int>(0, (sum, m) {
      final tc = (m['track-count'] as num?)?.toInt();
      if (tc != null) return sum + tc;
      return sum + ((m['tracks'] as List?)?.length ?? 0);
    });
  }

  /// Extracts artist name(s) from a MusicBrainz `artist-credit` array.
  /// Joins multiple credits with " & ".
  static String? _extractArtistCredit(Map<String, dynamic> release) {
    final credits =
        (release['artist-credit'] as List?)?.cast<Map<String, dynamic>>();
    if (credits == null || credits.isEmpty) return null;
    final names = credits
        .map((c) =>
            (c['name'] as String?) ??
            (c['artist'] as Map<String, dynamic>?)?['name'] as String?)
        .whereType<String>()
        .where((n) => n.isNotEmpty)
        .toList();
    return names.isEmpty ? null : names.join(' & ');
  }

  List<MbTrackEntry> _extractTrackListing(Map<String, dynamic> release) {
    final result = <MbTrackEntry>[];
    final media =
        (release['media'] as List?)?.cast<Map<String, dynamic>>();
    if (media == null) return result;

    for (final disc in media) {
      final discNumber = (disc['position'] as num?)?.toInt() ?? 1;
      final discTracks =
          (disc['tracks'] as List?)?.cast<Map<String, dynamic>>();
      if (discTracks == null) continue;
      for (final t in discTracks) {
        final trackNumber = int.tryParse(t['number']?.toString() ?? '') ??
            (t['position'] as num?)?.toInt() ??
            0;
        final durationMs = (t['length'] as num?)?.toInt() ?? 0;
        final title = t['title'] as String? ?? '';
        if (title.isEmpty) continue;
        result.add(MbTrackEntry(
          title: title,
          durationMs: durationMs,
          trackNumber: trackNumber,
          discNumber: discNumber,
        ));
      }
    }
    return result;
  }

  Future<String?> _fetchReleaseArtwork(String mbid) async {
    try {
      // MusicBrainz recommends a 1-second delay between requests
      await Future.delayed(const Duration(milliseconds: 1100));
      final uri =
          Uri.parse('https://coverartarchive.org/release/$mbid');
      final response = await http
          .get(uri, headers: {'User-Agent': _userAgent})
          .timeout(_timeout);

      if (response.statusCode == 404) return null;
      if (response.statusCode != 200) {
        AppLogger.warning(
          'Cover Art Archive ${response.statusCode} for $mbid',
          tag: _tag,
        );
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final images =
          (data['images'] as List?)?.cast<Map<String, dynamic>>();
      if (images == null || images.isEmpty) return null;

      final front = images.firstWhere(
        (img) => img['front'] == true,
        orElse: () => images.first,
      );
      final thumbnails = front['thumbnails'] as Map<String, dynamic>?;
      return (thumbnails?['large'] as String?) ??
          (front['image'] as String?);
    } catch (e) {
      AppLogger.warning('Cover Art Archive error for $mbid: $e', tag: _tag);
      return null;
    }
  }

  // ── iTunes Album Lookup ────────────────────────────────────────────────────

  Future<AlbumLookupResult?> _lookupItunesAlbum(
    String albumName,
    String artist,
  ) async {
    try {
      final term = Uri.encodeComponent('$artist $albumName');
      final uri = Uri.parse(
        'https://itunes.apple.com/search'
        '?term=$term&entity=album&limit=5',
      );
      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results =
          (data['results'] as List?)?.cast<Map<String, dynamic>>();
      if (results == null || results.isEmpty) return null;

      final result = results.first;
      final genre = result['primaryGenreName'] as String?;
      final releaseYear = _parseYear(result['releaseDate'] as String?);
      final rawArtwork = result['artworkUrl100'] as String?;
      final artworkUrl = rawArtwork?.replaceAll('100x100bb', '600x600bb');
      final itunesAlbumName = result['collectionName'] as String?;
      final itunesArtist = result['artistName'] as String?;

      return AlbumLookupResult(
        tracks: const [],
        albumName: itunesAlbumName,
        artist: itunesArtist,
        genre: genre,
        releaseYear: releaseYear,
        artworkUrl: artworkUrl,
        source: 'iTunes',
      );
    } catch (e) {
      AppLogger.warning('iTunes album lookup error: $e', tag: _tag);
      return null;
    }
  }

  // ── Track Matching Engine ─────────────────────────────────────────────────

  static String _normalizeTitle(String title) {
    var t = title.toLowerCase();
    t = t.replaceAll(RegExp(r'\(feat\.?[^)]*\)', caseSensitive: false), '');
    t = t.replaceAll(RegExp(r'\(ft\.?[^)]*\)', caseSensitive: false), '');
    t = t.replaceAll(RegExp(r'\bfeat\.?\s+\S+', caseSensitive: false), '');
    t = t.replaceAll(RegExp(r'\bft\.?\s+\S+', caseSensitive: false), '');
    t = t.replaceAll(RegExp(r'[^\w\s]'), '').trim();
    t = t.replaceAll(RegExp(r'\s+'), ' ');
    return t;
  }

  static int _scoreMatch(TrackModel local, MbTrackEntry candidate) {
    var score = 0;
    if (local.trackNumber != null &&
        local.trackNumber == candidate.trackNumber) {
      score += 3;
    }
    if ((local.durationMs - candidate.durationMs).abs() <= 4000) {
      score += 2;
    }
    if (_normalizeTitle(local.title) == _normalizeTitle(candidate.title)) {
      score += 1;
    }
    return score;
  }

  static (Map<TrackModel, MbTrackEntry>, List<TrackModel>) _matchTracks(
    List<TrackModel> tracks,
    List<MbTrackEntry> mbTracks,
  ) {
    final matched = <TrackModel, MbTrackEntry>{};
    final unmatched = <TrackModel>[];

    for (final track in tracks) {
      var bestScore = 0;
      MbTrackEntry? bestCandidate;
      var tie = false;

      for (final candidate in mbTracks) {
        final score = _scoreMatch(track, candidate);
        if (score > bestScore) {
          bestScore = score;
          bestCandidate = candidate;
          tie = false;
        } else if (score == bestScore && score > 0) {
          tie = true;
        }
      }

      if (bestScore >= 3 && !tie && bestCandidate != null) {
        matched[track] = bestCandidate;
      } else {
        unmatched.add(track);
      }
    }

    return (matched, unmatched);
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  Future<void> _writeFields({
    required TrackModel track,
    required String? newGenre,
    required int? newYear,
    required String? newArtworkPath,
    String? resolvedAlbumName,
    String? resolvedAlbumArtist,
  }) async {
    // Read current file tags — these are authoritative. DB values can be stale
    // (e.g. artist missing from DB but present in the file). Writing DB values
    // back without checking first would erase correct file data.
    mg.Metadata? fileTags;
    try {
      fileTags = await mg.MetadataGod.getMetadata(track.filePath);
    } catch (e) {
      AppLogger.warning(
        'Could not read file tags for "${track.title}" — using DB values: $e',
        tag: _tag,
      );
    }

    // Baseline for fields we are NOT changing.
    // title: prefer file tag > DB.
    // artist: fill from resolved album artist if the track's value is unknown/empty.
    // album/albumArtist: always use resolved batch values so file and DB stay in sync.
    final baseTitle = _coalesce(fileTags?.title, track.title);
    final rawArtist = _coalesce(fileTags?.artist, track.artist);
    final baseArtist = _isUnknown(rawArtist)
        ? (resolvedAlbumArtist ?? rawArtist)
        : rawArtist;
    final baseAlbum = resolvedAlbumName ??
        _coalesce(fileTags?.album, track.albumName);
    final baseAlbumArtist = resolvedAlbumArtist ??
        _coalesce(fileTags?.albumArtist, track.albumArtist, track.artist);

    // For the fields we are filling: check the FILE for emptiness, not the DB.
    final fileGenre = fileTags?.genre;
    final fileYear = fileTags?.year;
    final hasFileArtwork = fileTags?.picture != null;

    final effectiveGenre = _isEmpty(fileGenre) ? newGenre : fileGenre;
    final effectiveYear = (fileYear == null) ? newYear : fileYear;
    final effectiveArtworkPath =
        (!hasFileArtwork && _isEmpty(track.artworkPath))
            ? newArtworkPath
            : track.artworkPath;

    // Nothing to do
    if (baseArtist == rawArtist &&
        effectiveGenre == fileGenre &&
        effectiveYear == fileYear &&
        effectiveArtworkPath == track.artworkPath) { return; }

    // Artwork to embed: new if we're adding it, otherwise preserve what's in the file
    mg.Image? picture;
    if (newArtworkPath != null && !hasFileArtwork) {
      try {
        final bytes = await File(newArtworkPath).readAsBytes();
        picture = mg.Image(data: bytes, mimeType: 'image/jpeg');
      } catch (e) {
        AppLogger.warning(
          'Could not read new artwork for "${track.title}": $e',
          tag: _tag,
        );
        picture = fileTags?.picture;
      }
    } else {
      picture = fileTags?.picture; // preserve existing embedded art
    }

    await mg.MetadataGod.writeMetadata(
      track.filePath,
      mg.Metadata(
        title: baseTitle,
        artist: baseArtist,
        album: baseAlbum,
        albumArtist: baseAlbumArtist,
        genre: effectiveGenre,
        year: effectiveYear,
        picture: picture,
      ),
    );

    // Update DB only after successful file write
    await _db.trackDao.updateTrack(
      track.toUpdateCompanion().copyWith(
        artist: Value(baseArtist ?? track.artist),
        genre: Value(effectiveGenre),
        releaseYear: Value(effectiveYear),
        artworkPath: Value(effectiveArtworkPath),
      ),
    );
  }

  Future<void> _updateAlbumRecord(
    AlbumModel album,
    AlbumLookupResult result,
    String? artworkPath, {
    required String resolvedName,
    required String resolvedArtist,
  }) async {
    final effectiveArtwork =
        _isEmpty(album.artworkPath) ? artworkPath : album.artworkPath;
    final effectiveYear = album.releaseYear ?? result.releaseYear;

    // If the user left the artist as an "unknown" placeholder, use the artist
    // the lookup actually found instead of persisting the placeholder.
    final effectiveArtist = _isUnknown(resolvedArtist)
        ? (result.artist ?? resolvedArtist)
        : resolvedArtist;

    // Same for album name — if the user left it blank/unknown, use lookup result.
    final effectiveName = _isUnknown(resolvedName)
        ? (result.albumName ?? resolvedName)
        : resolvedName;

    try {
      await _db.albumDao.updateAfterFetch(
        album.id,
        name: effectiveName,
        artist: effectiveArtist,
        artworkPath: effectiveArtwork,
        releaseYear: effectiveYear,
      );
    } catch (e) {
      AppLogger.warning('Failed to update album record: $e', tag: _tag);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static bool _isEmpty(String? value) =>
      value == null || value.trim().isEmpty;

  static bool _isUnknown(String? value) {
    if (_isEmpty(value)) return true;
    final lower = value!.trim().toLowerCase();
    return lower == 'unknown' ||
        lower == 'unknown artist' ||
        lower == 'unknown album' ||
        lower == 'various artists';
  }

  /// Returns the first non-empty value from the given candidates.
  static String? _coalesce(String? a, [String? b, String? c]) {
    if (!_isEmpty(a)) return a;
    if (!_isEmpty(b)) return b;
    if (!_isEmpty(c)) return c;
    return null;
  }

  static int? _parseYear(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    return int.tryParse(dateStr.split('-').first.split('T').first);
  }
}
