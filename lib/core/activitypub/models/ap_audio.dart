import 'package:nightingale/core/activitypub/ap_context.dart';

/// Represents an ActivityPub Audio object for federated library publishing.
class ApAudio {
  const ApAudio({
    required this.id,
    required this.name,
    required this.artist,
    this.album,
    required this.duration,
    required this.url,
    this.artworkUrl,
  });

  final String id;
  final String name;
  final String artist;
  final String? album;
  final Duration duration;
  final String url;
  final String? artworkUrl;

  Map<String, dynamic> toJson() => {
    '@context': kActivityStreamsContext,
    'id': id,
    'type': 'Audio',
    'name': name,
    'artist': artist,
    if (album != null) 'album': album,
    'duration': duration.inSeconds,
    'url': {
      'type': 'Link',
      'href': url,
      'mediaType': 'audio/mpeg',
    },
    if (artworkUrl != null)
      'icon': {
        'type': 'Image',
        'url': artworkUrl,
      },
  };

  factory ApAudio.fromJson(Map<String, dynamic> json) {
    final urlObj = json['url'];
    final String? url = urlObj is Map ? urlObj['href'] as String? : urlObj as String?;
    final iconObj = json['icon'];
    final String? artworkUrl = iconObj is Map ? iconObj['url'] as String? : null;

    // Parse duration (can be int seconds or ISO 8601 duration string)
    Duration? duration;
    final durationRaw = json['duration'];
    if (durationRaw is int) {
      duration = Duration(seconds: durationRaw);
    } else if (durationRaw is String) {
      // Parse PT##S format
      final match = RegExp(r'PT(\d+)S').firstMatch(durationRaw);
      if (match != null) {
        duration = Duration(seconds: int.parse(match.group(1)!));
      }
    }

    return ApAudio(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      artist: json['artist'] as String? ?? 'Unknown Artist',
      album: json['album'] as String?,
      duration: duration ?? Duration.zero,
      url: url ?? '',
      artworkUrl: artworkUrl,
    );
  }
}
