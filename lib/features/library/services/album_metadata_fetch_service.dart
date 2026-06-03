import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:metadata_god/metadata_god.dart' as mg;
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/core/logging/app_logger.dart';
import 'package:nightingale/features/library/models/album_model.dart';
import 'package:nightingale/features/library/models/track_model.dart';
import 'package:nightingale/features/library/services/id3_tag_initializer.dart';
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

    debugPrint(
      '[$_tag] Release found via ${albumResult.source}: '
      '"${albumResult.albumName}" by ${albumResult.artist} — '
      '${albumResult.tracks.length} MB tracks, year=${albumResult.releaseYear}, '
      'genre=${albumResult.genre}, '
      'artwork=${albumResult.artworkUrl != null ? "yes" : "none"}',
    );

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
      debugPrint('[$_tag] Local tracks (${tracks.length}):');
      for (final t in tracks) {
        debugPrint('[$_tag]   local: #${t.trackNumber ?? "?"} "${t.title}" ${t.durationMs}ms');
      }
      debugPrint('[$_tag] MB tracks (${albumResult.tracks.length}):');
      for (final t in albumResult.tracks) {
        debugPrint('[$_tag]   mb:    #${t.trackNumber} "${t.title}" ${t.durationMs}ms');
      }

      final (matchMap, unmatchedList) =
          _matchTracks(tracks, albumResult.tracks);

      debugPrint('[$_tag] Matching result: ${matchMap.length} matched, ${unmatchedList.length} unmatched');
      for (final entry in matchMap.entries) {
        debugPrint('[$_tag]   ✓ "${entry.key.title}" → "${entry.value.title}"');
      }
      for (final t in unmatchedList) {
        debugPrint('[$_tag]   ✗ "${t.title}" — no match found');
      }
      unmatched.addAll(unmatchedList);

      for (final entry in matchMap.entries) {
        final track = entry.key;
        final mbTrack = entry.value;
        try {
          await _writeFields(
            track: track,
            newGenre: albumResult.genre,
            newYear: albumResult.releaseYear,
            newArtworkPath: artworkPath,
            resolvedAlbumName: resolvedName,
            resolvedAlbumArtist: resolvedArtist,
            newTrackNumber: mbTrack.trackNumber,
            newDiscNumber: mbTrack.discNumber,
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
      debugPrint('[$_tag] No MB track listing — applying album-level fields to all ${tracks.length} tracks');
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
          debugPrint('[$_tag]   ✓ wrote fields for "${track.title}"');
          matched.add(track);
        } catch (e, st) {
          debugPrint('[$_tag]   ✗ _writeFields threw for "${track.title}": $e\n$st');
          errors[track] = e.toString();
        }
      }
      debugPrint('[$_tag] Else-branch done: ${matched.length} matched, ${errors.length} errors');
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

      // Track listing from search result — the search API sometimes omits
      // recordings even with inc=recordings. If empty, fetch the full release.
      var mbTracks = _extractTrackListing(release);
      if (mbTracks.isEmpty && mbid != null) {
        mbTracks = await _fetchFullTrackListing(mbid) ?? [];
        AppLogger.debug(
          'Full release lookup for $mbid returned ${mbTracks.length} tracks',
          tag: _tag,
        );
      }

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
      for (int i = 0; i < discTracks.length; i++) {
        final t = discTracks[i];
        final trackNumber = int.tryParse(t['number']?.toString() ?? '') ??
            (t['position'] as num?)?.toInt() ??
            (i + 1); // 1-indexed fallback when MB omits number/position
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

  /// Fetches the full release from MusicBrainz by MBID and returns its track
  /// listing. Used as a fallback when the search result omits recordings.
  Future<List<MbTrackEntry>?> _fetchFullTrackListing(String mbid) async {
    try {
      await Future.delayed(const Duration(milliseconds: 1100));
      final uri = Uri.parse(
        'https://musicbrainz.org/ws/2/release/$mbid?inc=recordings&fmt=json',
      );
      final response = await http
          .get(uri, headers: {'User-Agent': _userAgent})
          .timeout(_timeout);
      if (response.statusCode != 200) {
        AppLogger.warning(
          'MusicBrainz full release fetch ${response.statusCode} for $mbid',
          tag: _tag,
        );
        return null;
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return _extractTrackListing(data);
    } catch (e) {
      AppLogger.warning('Full release fetch error for $mbid: $e', tag: _tag);
      return null;
    }
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
    // unicode: true keeps accented letters (é, ü, ñ …) so "Beyoncé" and
    // "Beyonce" don't silently collapse to different strings.
    t = t.replaceAll(RegExp(r'[^\w\s]', unicode: true), '').trim();
    t = t.replaceAll(RegExp(r'\s+'), ' ');
    return t;
  }

  static int _scoreMatch(TrackModel local, MbTrackEntry candidate) {
    var score = 0;
    if (local.trackNumber != null &&
        local.trackNumber == candidate.trackNumber) {
      score += 3;
    }
    // Skip duration scoring when MusicBrainz has no duration (returns 0).
    // 10 s tolerance handles YouTube rips, different editions, and pre-gap variance.
    if (candidate.durationMs > 0 &&
        (local.durationMs - candidate.durationMs).abs() <= 10000) {
      score += 2;
    }
    // Substring match handles "Artist - 'Song Title' (Full Album Stream)" patterns
    // where the MB title is a clean substring of the YouTube-style local title.
    final localNorm = _normalizeTitle(local.title);
    final candNorm = _normalizeTitle(candidate.title);
    if (localNorm.contains(candNorm) || candNorm.contains(localNorm)) {
      score += 2;
    }
    return score;
  }

  static void _logScores(TrackModel local, List<MbTrackEntry> candidates) {
    debugPrint('[$_tag]   scoring "${local.title}" (#${local.trackNumber ?? "?"} ${local.durationMs}ms):');
    for (final c in candidates) {
      final trackPts = (local.trackNumber != null && local.trackNumber == c.trackNumber) ? 3 : 0;
      final durDiff = c.durationMs > 0 ? (local.durationMs - c.durationMs).abs() : -1;
      final durPts = (c.durationMs > 0 && durDiff <= 10000) ? 2 : 0;
      final localNorm = _normalizeTitle(local.title);
      final candNorm = _normalizeTitle(c.title);
      final titlePts = (localNorm.contains(candNorm) || candNorm.contains(localNorm)) ? 2 : 0;
      final total = trackPts + durPts + titlePts;
      debugPrint(
        '[$_tag]     vs "#${c.trackNumber} ${c.title}" (${c.durationMs}ms) '
        '→ trackNum=$trackPts dur=$durPts(diff=${durDiff}ms) title=$titlePts '
        '[local_norm="$localNorm" mb_norm="$candNorm"] total=$total',
      );
    }
  }

  static (Map<TrackModel, MbTrackEntry>, List<TrackModel>) _matchTracks(
    List<TrackModel> tracks,
    List<MbTrackEntry> mbTracks,
  ) {
    final matched = <TrackModel, MbTrackEntry>{};
    final stillUnmatched = <TrackModel>[];
    final claimedPass1 = <MbTrackEntry>{};

    // Pass 1: score-based matching (duration + title ≥ 3)
    // Only consider unclaimed MB tracks so each MB entry is assigned at most once.
    for (final track in tracks) {
      var bestScore = 0;
      MbTrackEntry? bestCandidate;
      var tie = false;

      _logScores(track, mbTracks);

      for (final candidate in mbTracks) {
        if (claimedPass1.contains(candidate)) continue;
        final score = _scoreMatch(track, candidate);
        if (score > bestScore) {
          bestScore = score;
          bestCandidate = candidate;
          tie = false;
        } else if (score == bestScore && score > 0) {
          tie = true;
        }
      }

      debugPrint(
        '[$_tag]   → bestScore=$bestScore tie=$tie '
        '${bestScore >= 3 && !tie ? "MATCHED to \"${bestCandidate?.title}\"" : "UNMATCHED (pass 1)"}',
      );

      if (bestScore >= 3 && !tie && bestCandidate != null) {
        matched[track] = bestCandidate;
        claimedPass1.add(bestCandidate);
      } else {
        stillUnmatched.add(track);
      }
    }

    // Pass 2: title-only fallback for anything that didn't score high enough.
    // If exactly one unclaimed MB track's title is a substring of (or contains)
    // the local title, assign it — this handles YouTube rips where duration
    // varies but the title is unambiguous.
    final claimedMb = matched.values.toSet();
    final finalUnmatched = <TrackModel>[];

    for (final track in stillUnmatched) {
      final localNorm = _normalizeTitle(track.title);
      final candidates = mbTracks
          .where((c) => !claimedMb.contains(c))
          .where((c) {
            final cn = _normalizeTitle(c.title);
            return localNorm.contains(cn) || cn.contains(localNorm);
          })
          .toList();

      if (candidates.length == 1) {
        matched[track] = candidates.first;
        claimedMb.add(candidates.first);
        debugPrint('[$_tag]   → pass 2 MATCHED "${track.title}" → "${candidates.first.title}"');
      } else {
        finalUnmatched.add(track);
        debugPrint('[$_tag]   → pass 2 UNMATCHED "${track.title}" (${candidates.length} title candidates)');
      }
    }

    return (matched, finalUnmatched);
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  Future<void> _writeFields({
    required TrackModel track,
    required String? newGenre,
    required int? newYear,
    required String? newArtworkPath,
    String? resolvedAlbumName,
    String? resolvedAlbumArtist,
    int? newTrackNumber,
    int? newDiscNumber,
  }) async {
    final effectiveArtist = _isUnknown(track.artist)
        ? (resolvedAlbumArtist ?? track.artist)
        : track.artist;
    final effectiveAlbum = resolvedAlbumName ?? track.albumName;
    final effectiveAlbumArtist =
        resolvedAlbumArtist ?? track.albumArtist ?? track.artist;
    final effectiveGenre = _isEmpty(track.genre) ? newGenre : track.genre;
    final effectiveYear = track.releaseYear ?? newYear;
    final effectiveArtworkPath = newArtworkPath ?? track.artworkPath;
    final effectiveTrackNumber = newTrackNumber ?? track.trackNumber;
    final effectiveDiscNumber = newDiscNumber ?? track.discNumber;

    mg.Image? picture;
    if (newArtworkPath != null) {
      try {
        final bytes = await File(newArtworkPath).readAsBytes();
        picture = mg.Image(data: bytes, mimeType: 'image/jpeg');
      } catch (e) {
        AppLogger.warning(
          'Could not read artwork for "${track.title}": $e',
          tag: _tag,
        );
      }
    }

    final metadata = mg.Metadata(
      title: track.title,
      artist: effectiveArtist,
      album: effectiveAlbum,
      albumArtist: effectiveAlbumArtist,
      genre: effectiveGenre,
      year: effectiveYear,
      trackNumber: effectiveTrackNumber,
      discNumber: effectiveDiscNumber,
      picture: picture,
    );

    try {
      await mg.MetadataGod.writeMetadata(track.filePath, metadata);
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('NoTag')) {
        // File has no ID3 container — stamp a minimal header and retry.
        try {
          await stampId3Header(track.filePath);
          await mg.MetadataGod.writeMetadata(track.filePath, metadata);
          debugPrint('[$_tag] Created ID3 tag for "${track.title}"');
        } catch (e2) {
          AppLogger.warning('Tag write failed after stamp for "${track.title}": $e2', tag: _tag);
          debugPrint('[$_tag] Tag write failed after stamp for "${track.title}": $e2');
        }
      } else {
        AppLogger.warning('File tag write failed for "${track.title}": $e', tag: _tag);
        debugPrint('[$_tag] File tag write failed for "${track.title}": $e');
      }
    }

    await _db.trackDao.updateTrack(
      track.toUpdateCompanion().copyWith(
        artist: Value(effectiveArtist),
        genre: Value(effectiveGenre),
        releaseYear: Value(effectiveYear),
        artworkPath: Value(effectiveArtworkPath),
        trackNumber: Value(effectiveTrackNumber),
        discNumber: Value(effectiveDiscNumber),
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
    // Prefer freshly fetched artwork over whatever the scanner extracted.
    final effectiveArtwork = artworkPath ?? album.artworkPath;
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

  static int? _parseYear(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    return int.tryParse(dateStr.split('-').first.split('T').first);
  }
}
