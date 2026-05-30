import 'package:flutter/services.dart';

/// Three-tier haptic vocabulary for nightingale.
/// All calls are fire-and-forget; silently no-ops on unsupported devices.
abstract final class HapticService {
  /// Light impact — track starts playing. Positive confirmation.
  static void trackStart() => HapticFeedback.lightImpact();

  /// Medium impact — save or like action. Intentional positive action.
  static void saveOrLike() => HapticFeedback.mediumImpact();

  /// Heavy impact — terminal stream failure or node unreachable. Failure signal.
  static void streamFailed() => HapticFeedback.heavyImpact();
}
