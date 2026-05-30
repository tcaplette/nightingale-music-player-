import 'package:flutter/foundation.dart';

/// Single compile-time gate for all diagnostic code.
/// All debug overlay widgets, Timeline markers, log streams, and the
/// NetworkInspector are wrapped in `if (kDiagnosticsEnabled)` guards.
/// Flutter's tree-shaker removes all false branches in release builds,
/// leaving zero diagnostic symbols in the release binary.
const bool kDiagnosticsEnabled = !kReleaseMode;
