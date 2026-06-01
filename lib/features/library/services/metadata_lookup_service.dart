import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:nightingale/core/logging/app_logger.dart';
import 'package:path_provider/path_provider.dart';

const _tag = 'metadata_lookup';
const _userAgent = 'Nightingale/1.0 (music-player; contact@nightingale.app)';
const _timeout = Duration(seconds: 10);
const _maxRetries = 3;

class MetadataLookupResult {
  const MetadataLookupResult({
    this.album,
    this.releaseYear,
    this.genre,
    this.artworkUrl,
    required this.source,
  });

  final String? album;
  final int? releaseYear;
  final String? genre;
  final String? artworkUrl;
  final String source; // 'MusicBrainz' | 'iTunes'
}

class MetadataLookupService {
  const MetadataLookupService();

  /// Retries [fn] up to [_maxRetries] times with exponential backoff.
  /// Returns null if all attempts fail.
  Future<T?> _withRetry<T>(Future<T?> Function() fn) async {
    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final result = await fn();
        if (result != null) return result;
      } catch (e) {
        AppLogger.debug(
          'Attempt ${attempt + 1}/$_maxRetries failed: $e',
          tag: _tag,
        );
      }
      if (attempt < _maxRetries - 1) {
        // Exponential backoff: 1s, 2s, 4s
        await Future.delayed(Duration(seconds: 1 << attempt));
      }
    }
    return null;
  }

  /// Downloads artwork from [url] and saves it to the artworks directory.
  /// Returns the local file path, or null on failure.
  Future<String?> downloadArtwork(String url, int trackId) async {
    try {
      final response =
          await http.get(Uri.parse(url)).timeout(_timeout);
      if (response.statusCode != 200) return null;
      final dir = await getApplicationDocumentsDirectory();
      final artDir = Directory('${dir.path}/artworks');
      if (!artDir.existsSync()) artDir.createSync(recursive: true);
      final file = File('${artDir.path}/$trackId.jpg');
      await file.writeAsBytes(response.bodyBytes);
      return file.path;
    } catch (e) {
      AppLogger.warning('Artwork download failed: $e', tag: _tag);
      return null;
    }
  }

  /// Looks up metadata using MusicBrainz first, falls back to iTunes.
  Future<MetadataLookupResult?> lookup({
    required String title,
    required String artist,
    String? album,
  }) async {
    final mb = await _withRetry(
      () => _lookupMusicBrainz(title: title, artist: artist),
    );
    if (mb != null) return mb;
    AppLogger.debug('MusicBrainz returned no result, trying iTunes', tag: _tag);
    return _withRetry(
      () => _lookupItunes(title: title, artist: artist, album: album),
    );
  }

  // ── MusicBrainz ────────────────────────────────────────────────────────────

  Future<MetadataLookupResult?> _lookupMusicBrainz({
    required String title,
    required String artist,
  }) async {
    try {
      final query = Uri.encodeComponent(
        'recording:"$title" AND artist:"$artist"',
      );
      final uri = Uri.parse(
        'https://musicbrainz.org/ws/2/recording'
        '?query=$query&inc=releases+tags&fmt=json&limit=5',
      );

      final response = await http
          .get(uri, headers: {'User-Agent': _userAgent})
          .timeout(_timeout);

      if (response.statusCode == 503 || response.statusCode == 429) {
        // Rate limited — throw so _withRetry backs off
        throw Exception('MusicBrainz rate limit: ${response.statusCode}');
      }
      if (response.statusCode != 200) {
        AppLogger.warning(
          'MusicBrainz recording search ${response.statusCode}',
          tag: _tag,
        );
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final recordings =
          (data['recordings'] as List?)?.cast<Map<String, dynamic>>();
      if (recordings == null || recordings.isEmpty) return null;

      final recording = recordings.first;

      // Pick the best release (prefer official, then first available)
      final releases =
          (recording['releases'] as List?)?.cast<Map<String, dynamic>>();
      if (releases == null || releases.isEmpty) return null;

      final release = releases.firstWhere(
        (r) =>
            (r['status'] as String?)?.toLowerCase() == 'official',
        orElse: () => releases.first,
      );

      final mbid = release['id'] as String?;
      final albumName = release['title'] as String?;
      final dateStr = release['date'] as String?;
      final releaseYear = _parseYear(dateStr);

      // Tags → genre (pick highest-count tag)
      final tags =
          (recording['tags'] as List?)?.cast<Map<String, dynamic>>();
      String? genre;
      if (tags != null && tags.isNotEmpty) {
        tags.sort(
          (a, b) =>
              ((b['count'] as num?)?.toInt() ?? 0)
                  .compareTo((a['count'] as num?)?.toInt() ?? 0),
        );
        genre = tags.first['name'] as String?;
      }

      // Cover Art Archive
      String? artworkUrl;
      if (mbid != null) {
        artworkUrl = await _fetchCoverArt(mbid);
      }

      return MetadataLookupResult(
        album: albumName,
        releaseYear: releaseYear,
        genre: genre,
        artworkUrl: artworkUrl,
        source: 'MusicBrainz',
      );
    } catch (e) {
      AppLogger.warning('MusicBrainz lookup error: $e', tag: _tag);
      return null;
    }
  }

  Future<String?> _fetchCoverArt(String mbid) async {
    try {
      // MusicBrainz recommends a 1-second delay between requests
      await Future.delayed(const Duration(milliseconds: 1100));

      final uri = Uri.parse(
        'https://coverartarchive.org/release/$mbid',
      );
      final response = await http
          .get(uri, headers: {'User-Agent': _userAgent})
          .timeout(_timeout);

      if (response.statusCode == 404) return null;
      if (response.statusCode == 503 || response.statusCode == 429) {
        throw Exception('Cover Art Archive rate limit: ${response.statusCode}');
      }
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

      // Prefer front cover
      final front = images.firstWhere(
        (img) => img['front'] == true,
        orElse: () => images.first,
      );

      // Use large thumbnail if available, else full image
      final thumbnails = front['thumbnails'] as Map<String, dynamic>?;
      return (thumbnails?['large'] as String?) ??
          (front['image'] as String?);
    } catch (e) {
      AppLogger.warning('Cover Art Archive error: $e', tag: _tag);
      return null;
    }
  }

  // ── iTunes ─────────────────────────────────────────────────────────────────

  Future<MetadataLookupResult?> _lookupItunes({
    required String title,
    required String artist,
    String? album,
  }) async {
    try {
      final term = Uri.encodeComponent('$artist $title');
      final uri = Uri.parse(
        'https://itunes.apple.com/search'
        '?term=$term&entity=song&limit=5',
      );

      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results =
          (data['results'] as List?)?.cast<Map<String, dynamic>>();
      if (results == null || results.isEmpty) return null;

      // Pick the result whose album name best matches if we have one
      final result = album != null
          ? (results.firstWhere(
              (r) =>
                  (r['collectionName'] as String?)
                      ?.toLowerCase()
                      .contains(album.toLowerCase()) ??
                  false,
              orElse: () => results.first,
            ))
          : results.first;

      final albumName = result['collectionName'] as String?;
      final releaseYear = _parseYear(result['releaseDate'] as String?);
      final genre = result['primaryGenreName'] as String?;

      // iTunes artwork: swap 100x100 for 600x600
      final rawArtwork = result['artworkUrl100'] as String?;
      final artworkUrl =
          rawArtwork?.replaceAll('100x100bb', '600x600bb');

      return MetadataLookupResult(
        album: albumName,
        releaseYear: releaseYear,
        genre: genre,
        artworkUrl: artworkUrl,
        source: 'iTunes',
      );
    } catch (e) {
      AppLogger.warning('iTunes lookup error: $e', tag: _tag);
      return null;
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  int? _parseYear(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    // Handles "2001", "2001-10", "2001-10-01", "2001-10-01T00:00:00Z"
    return int.tryParse(dateStr.split('-').first.split('T').first);
  }
}
