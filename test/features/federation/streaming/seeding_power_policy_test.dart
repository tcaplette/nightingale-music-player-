import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightingale/features/federation/streaming/seeding_power_policy.dart';
import 'package:nightingale/features/settings/data/settings_repository.dart';

// Minimal in-memory settings repository for tests.
class _FakeSettings extends SettingsRepository {
  _FakeSettings() : super(storage: const _FakeStorage());

  bool seedingEnabled = true;
  int batteryThreshold = 50;

  @override
  Future<bool> isSeedingEnabled() async => seedingEnabled;

  @override
  Future<void> setSeedingEnabled(bool enabled) async =>
      seedingEnabled = enabled;

  @override
  Future<int> getSeedingBatteryThreshold() async => batteryThreshold;

  @override
  Future<void> setSeedingBatteryThreshold(int percent) async =>
      batteryThreshold = percent;
}

// Dummy FlutterSecureStorage that does nothing — avoids platform channel calls.
class _FakeStorage implements FlutterSecureStorage {
  const _FakeStorage();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

SeedingPowerPolicy _policy({
  bool wifi = true,
  bool charging = true,
  int level = 80,
  bool enabled = true,
}) {
  final settings = _FakeSettings()
    ..seedingEnabled = enabled
    ..batteryThreshold = 50;

  return SeedingPowerPolicy(
    settings: settings,
    connectivityChecker: () async =>
        wifi ? [ConnectivityResult.wifi] : [ConnectivityResult.mobile],
    batteryStateChecker: () async =>
        charging ? BatteryState.charging : BatteryState.discharging,
    batteryLevelChecker: () async => level,
  );
}

void main() {
  group('SeedingPowerPolicy.canSeed', () {
    test('returns true: charging + Wi-Fi + above threshold', () async {
      expect(await _policy().canSeed(), isTrue);
    });

    test('returns false: cellular connection', () async {
      expect(await _policy(wifi: false).canSeed(), isFalse);
    });

    test('returns false: not charging', () async {
      expect(await _policy(charging: false).canSeed(), isFalse);
    });

    test('returns false: battery below threshold (30% < 50%)', () async {
      expect(await _policy(level: 30).canSeed(), isFalse);
    });

    test('returns false: seeding disabled by toggle', () async {
      expect(await _policy(enabled: false).canSeed(), isFalse);
    });

    test('all conditions false still returns false', () async {
      expect(
        await _policy(wifi: false, charging: false, level: 10, enabled: false)
            .canSeed(),
        isFalse,
      );
    });
  });

  group('SeedingPowerPolicy.updateThreshold', () {
    test('new threshold takes effect on next canSeed call', () async {
      final settings = _FakeSettings()
        ..seedingEnabled = true
        ..batteryThreshold = 50;

      final policy = SeedingPowerPolicy(
        settings: settings,
        connectivityChecker: () async => [ConnectivityResult.wifi],
        batteryStateChecker: () async => BatteryState.charging,
        batteryLevelChecker: () async => 40, // below 50%
      );

      await policy.init();
      expect(await policy.canSeed(), isFalse);

      await policy.updateThreshold(30); // lower the bar
      expect(await policy.canSeed(), isTrue);
    });
  });

  group('SeedingPowerPolicy.setSeedingEnabled', () {
    test('disabling returns false regardless of conditions', () async {
      final policy = _policy(enabled: true);
      await policy.init();
      await policy.setSeedingEnabled(false);
      expect(await policy.canSeed(), isFalse);
    });

    test('re-enabling restores condition checks', () async {
      final policy = _policy(enabled: false);
      await policy.init();
      await policy.setSeedingEnabled(true);
      expect(await policy.canSeed(), isTrue);
    });
  });

  group('SeedingPowerPolicy.status', () {
    test('active when all conditions met', () async {
      expect(await _policy().status(), SeedingStatus.active);
    });

    test('disabled when toggle off', () async {
      expect(await _policy(enabled: false).status(), SeedingStatus.disabled);
    });

    test('pausedNoWifi on cellular', () async {
      expect(await _policy(wifi: false).status(), SeedingStatus.pausedNoWifi);
    });

    test('pausedNotCharging on battery', () async {
      expect(
        await _policy(charging: false).status(),
        SeedingStatus.pausedNotCharging,
      );
    });

    test('pausedBatteryLow below threshold', () async {
      expect(
        await _policy(level: 20).status(),
        SeedingStatus.pausedBatteryLow,
      );
    });
  });
}
