import 'dart:convert';

const _kMaxPayloadBytes = 64 * 1024; // 64 KB

sealed class SanitizerResult {}

class SanitizerOk extends SanitizerResult {
  SanitizerOk(this.json);
  final Map<String, dynamic> json;
}

class SanitizerRejected extends SanitizerResult {
  SanitizerRejected(this.reason);
  final String reason;
}

class ActivitySanitizer {
  const ActivitySanitizer();

  SanitizerResult sanitize(String rawBody) {
    if (rawBody.length > _kMaxPayloadBytes) {
      return SanitizerRejected('payload exceeds 64 KB limit');
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(rawBody) as Map<String, dynamic>;
    } catch (_) {
      return SanitizerRejected('invalid JSON');
    }

    return SanitizerOk(_sanitizeMap(json));
  }

  Map<String, dynamic> _sanitizeMap(Map<String, dynamic> map) {
    return map.map((key, value) {
      if (value is String) {
        return MapEntry(key, _sanitizeString(key, value));
      } else if (value is Map<String, dynamic>) {
        return MapEntry(key, _sanitizeMap(value));
      } else if (value is List) {
        return MapEntry(key, _sanitizeList(value));
      }
      return MapEntry(key, value);
    });
  }

  List<dynamic> _sanitizeList(List<dynamic> list) {
    return list.map((item) {
      if (item is String) return _sanitizeString('', item);
      if (item is Map<String, dynamic>) return _sanitizeMap(item);
      return item;
    }).toList();
  }

  // URL fields: null out non-HTTPS URLs. String fields: strip HTML.
  dynamic _sanitizeString(String key, String value) {
    final isUrlField = const {'url', 'href', 'icon', 'image', 'id', 'inbox',
        'outbox', 'followers', 'following', 'actor', 'object', 'target'}
        .contains(key);
    if (isUrlField) {
      if (!value.startsWith('https://')) return null;
      return value;
    }
    return _stripHtml(value);
  }

  // Minimal HTML stripper — removes tags, normalises whitespace.
  String _stripHtml(String input) =>
      input.replaceAll(RegExp(r'<[^>]*>'), '').trim();
}
