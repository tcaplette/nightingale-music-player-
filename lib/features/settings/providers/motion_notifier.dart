import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/features/settings/data/settings_repository.dart';

const _kReducedMotionDuration = Duration(milliseconds: 80);

class MotionNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() =>
      sl<SettingsRepository>().isReduceMotionEnabled();

  Future<void> setReduceMotion(bool enabled) async {
    await sl<SettingsRepository>().setReduceMotionEnabled(enabled);
    state = AsyncData(enabled);
  }
}

final motionNotifierProvider =
    AsyncNotifierProvider<MotionNotifier, bool>(MotionNotifier.new);

/// Returns [_kReducedMotionDuration] when reduce-motion is enabled, otherwise [standard].
Duration resolvedDuration(bool reduceMotion, Duration standard) =>
    reduceMotion ? _kReducedMotionDuration : standard;
