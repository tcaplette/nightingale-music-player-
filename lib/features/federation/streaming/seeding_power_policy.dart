import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:nightingale/core/logging/app_logger.dart';
import 'package:nightingale/features/settings/data/settings_repository.dart';

const _tag = 'seeding_policy';

typedef ConnectivityChecker = Future<List<ConnectivityResult>> Function();
typedef BatteryStateChecker = Future<BatteryState> Function();
typedef BatteryLevelChecker = Future<int> Function();

Future<List<ConnectivityResult>> _defaultConnectivityCheck() =>
    Connectivity().checkConnectivity();

Future<BatteryState> _defaultBatteryStateCheck() => Battery().batteryState;

Future<int> _defaultBatteryLevelCheck() => Battery().batteryLevel;

/// Runtime policy that gates outbound chunk-serving (seeding) on:
///   1. User toggle (enabled/disabled)
///   2. Device is charging
///   3. Network is unmetered Wi-Fi
///   4. Battery level ≥ configurable threshold (default 50%)
///
/// All checks happen at call time so the policy responds immediately to
/// changes (e.g. unplugging the charger) without restarting the server.
class SeedingPowerPolicy {
  SeedingPowerPolicy({
    required SettingsRepository settings,
    ConnectivityChecker? connectivityChecker,
    BatteryStateChecker? batteryStateChecker,
    BatteryLevelChecker? batteryLevelChecker,
  })  : _settings = settings,
        _connectivity =
            connectivityChecker ?? _defaultConnectivityCheck,
        _batteryState =
            batteryStateChecker ?? _defaultBatteryStateCheck,
        _batteryLevel =
            batteryLevelChecker ?? _defaultBatteryLevelCheck;

  final SettingsRepository _settings;
  final ConnectivityChecker _connectivity;
  final BatteryStateChecker _batteryState;
  final BatteryLevelChecker _batteryLevel;

  bool _enabled = true;
  int _threshold = 50;
  bool _initialized = false;

  bool get isSeedingEnabled => _enabled;
  int get batteryThreshold => _threshold;

  Future<void> init() async {
    _enabled = await _settings.isSeedingEnabled();
    _threshold = await _settings.getSeedingBatteryThreshold();
    _initialized = true;
    AppLogger.debug(
      'SeedingPowerPolicy: initialized — enabled=$_enabled, '
      'threshold=$_threshold%',
      tag: _tag,
    );
  }

  /// Returns true only when all seeding conditions are met.
  Future<bool> canSeed() async {
    if (!_initialized) await init();

    if (!_enabled) {
      AppLogger.debug('SeedingPowerPolicy: seeding disabled by user', tag: _tag);
      return false;
    }

    final results = await _connectivity();
    if (!results.contains(ConnectivityResult.wifi)) {
      AppLogger.debug('SeedingPowerPolicy: no Wi-Fi connection', tag: _tag);
      return false;
    }

    final state = await _batteryState();
    final isCharging =
        state == BatteryState.charging || state == BatteryState.full;
    if (!isCharging) {
      AppLogger.debug('SeedingPowerPolicy: device not charging', tag: _tag);
      return false;
    }

    final level = await _batteryLevel();
    if (level < _threshold) {
      AppLogger.debug(
        'SeedingPowerPolicy: battery $level% below threshold $_threshold%',
        tag: _tag,
      );
      return false;
    }

    return true;
  }

  /// Updates the seeding toggle immediately without requiring app restart.
  Future<void> setSeedingEnabled(bool enabled) async {
    _enabled = enabled;
    await _settings.setSeedingEnabled(enabled);
  }

  /// Updates the battery threshold immediately without requiring app restart.
  Future<void> updateThreshold(int percent) async {
    _threshold = percent.clamp(0, 100);
    await _settings.setSeedingBatteryThreshold(_threshold);
  }

  /// Human-readable status for UI display. Returns [SeedingStatus.active]
  /// when seeding is permitted.
  Future<SeedingStatus> status() async {
    if (!_initialized) await init();

    if (!_enabled) return SeedingStatus.disabled;

    final results = await _connectivity();
    if (!results.contains(ConnectivityResult.wifi)) {
      return SeedingStatus.pausedNoWifi;
    }

    final state = await _batteryState();
    final isCharging =
        state == BatteryState.charging || state == BatteryState.full;
    if (!isCharging) return SeedingStatus.pausedNotCharging;

    final level = await _batteryLevel();
    if (level < _threshold) return SeedingStatus.pausedBatteryLow;

    return SeedingStatus.active;
  }
}

enum SeedingStatus {
  active,
  disabled,
  pausedNotCharging,
  pausedNoWifi,
  pausedBatteryLow;

  String get label => switch (this) {
        SeedingStatus.active => 'Active',
        SeedingStatus.disabled => 'Disabled',
        SeedingStatus.pausedNotCharging => 'Paused – charging required',
        SeedingStatus.pausedNoWifi => 'Paused – Wi-Fi required',
        SeedingStatus.pausedBatteryLow => 'Paused – battery low',
      };
}
