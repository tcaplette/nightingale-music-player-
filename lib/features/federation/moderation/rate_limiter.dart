import 'package:nightingale/core/logging/app_logger.dart';

class _Window {
  _Window() : start = DateTime.now().toUtc(), count = 0;
  final DateTime start;
  int count;
}

/// In-memory per-source sliding-window rate limiter.
/// State is intentionally not persisted — see design.md.
class RateLimiter {
  RateLimiter({this.limit = 60, this.windowSeconds = 60});

  final int limit;
  final int windowSeconds;

  final Map<String, _Window> _windows = {};

  /// Returns true if the request is allowed, false if rate-limited.
  bool checkAndRecord(String sourceDomain) {
    final now = DateTime.now().toUtc();
    final window = _windows[sourceDomain];

    if (window == null ||
        now.difference(window.start).inSeconds >= windowSeconds) {
      _windows[sourceDomain] = _Window()..count = 1;
      return true;
    }

    if (window.count >= limit) {
      AppLogger.debug(
        'Rate limited $sourceDomain (${window.count}/$limit in window)',
        tag: 'rate_limiter',
      );
      return false;
    }

    window.count++;
    return true;
  }

  Map<String, ({int count, int windowSeconds, DateTime windowStart})>
      get liveCounters => _windows.map(
            (domain, w) => MapEntry(
              domain,
              (
                count: w.count,
                windowSeconds: windowSeconds,
                windowStart: w.start,
              ),
            ),
          );
}
