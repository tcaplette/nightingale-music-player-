import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nightingale/features/settings/models/playback_settings.dart';

const _kThemeModeKey = 'nightingale_settings_theme_mode';
const _kReduceMotionKey = 'nightingale_settings_reduce_motion';
const _kBufferPresetKey = 'nightingale_settings_buffer_preset';
const _kSkipThresholdKey = 'nightingale_settings_skip_threshold';
const _kAudioFocusKey = 'nightingale_settings_audio_focus';
const _kNotifyNewFollowersKey = 'nightingale_settings_notify_new_followers';
const _kNotifyActivityFeedKey = 'nightingale_settings_notify_activity_feed';
const _kNotificationAutoClearKey = 'nightingale_settings_notification_auto_clear';
const _kSharingScopeKey = 'nightingale_settings_sharing_scope';
const _kListenActivityEnabledKey = 'nightingale_settings_listen_activity_enabled';

class SettingsRepository {
  SettingsRepository({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
            );

  final FlutterSecureStorage _storage;

  // ── Theme ──────────────────────────────────────────────────────────────────

  Future<ThemeMode> getThemeMode() async {
    final v = await _storage.read(key: _kThemeModeKey);
    return switch (v) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) => _storage.write(
        key: _kThemeModeKey,
        value: switch (mode) {
          ThemeMode.light => 'light',
          ThemeMode.dark => 'dark',
          ThemeMode.system => 'system',
        },
      );

  // ── Reduce Motion ──────────────────────────────────────────────────────────

  Future<bool> isReduceMotionEnabled() async {
    final v = await _storage.read(key: _kReduceMotionKey);
    return v == 'true';
  }

  Future<void> setReduceMotionEnabled(bool enabled) =>
      _storage.write(key: _kReduceMotionKey, value: enabled.toString());

  // ── Playback ───────────────────────────────────────────────────────────────

  Future<BufferPreset> getBufferPreset() async {
    final v = await _storage.read(key: _kBufferPresetKey);
    return BufferPreset.values.firstWhere(
      (e) => e.name == v,
      orElse: () => BufferPreset.normal,
    );
  }

  Future<void> setBufferPreset(BufferPreset preset) =>
      _storage.write(key: _kBufferPresetKey, value: preset.name);

  Future<SkipThreshold> getSkipThreshold() async {
    final v = await _storage.read(key: _kSkipThresholdKey);
    return SkipThreshold.values.firstWhere(
      (e) => e.name == v,
      orElse: () => SkipThreshold.three,
    );
  }

  Future<void> setSkipThreshold(SkipThreshold threshold) =>
      _storage.write(key: _kSkipThresholdKey, value: threshold.name);

  Future<AudioFocusBehaviour> getAudioFocusBehaviour() async {
    final v = await _storage.read(key: _kAudioFocusKey);
    return AudioFocusBehaviour.values.firstWhere(
      (e) => e.name == v,
      orElse: () => AudioFocusBehaviour.duck,
    );
  }

  Future<void> setAudioFocusBehaviour(AudioFocusBehaviour behaviour) =>
      _storage.write(key: _kAudioFocusKey, value: behaviour.name);

  Future<PlaybackSettings> loadPlaybackSettings() async {
    final buffer = await getBufferPreset();
    final skip = await getSkipThreshold();
    final focus = await getAudioFocusBehaviour();
    return PlaybackSettings(
      bufferPreset: buffer,
      skipThreshold: skip,
      audioFocusBehaviour: focus,
    );
  }

  // ── Notifications ──────────────────────────────────────────────────────────

  Future<bool> isNotifyNewFollowersEnabled() async {
    final v = await _storage.read(key: _kNotifyNewFollowersKey);
    return v != 'false';
  }

  Future<void> setNotifyNewFollowersEnabled(bool enabled) =>
      _storage.write(key: _kNotifyNewFollowersKey, value: enabled.toString());

  Future<bool> isNotifyActivityFeedEnabled() async {
    final v = await _storage.read(key: _kNotifyActivityFeedKey);
    return v != 'false';
  }

  Future<void> setNotifyActivityFeedEnabled(bool enabled) =>
      _storage.write(key: _kNotifyActivityFeedKey, value: enabled.toString());

  Future<NotificationAutoClear> getNotificationAutoClear() async {
    final v = await _storage.read(key: _kNotificationAutoClearKey);
    return NotificationAutoClear.values.firstWhere(
      (e) => e.name == v,
      orElse: () => NotificationAutoClear.never,
    );
  }

  Future<void> setNotificationAutoClear(NotificationAutoClear value) =>
      _storage.write(key: _kNotificationAutoClearKey, value: value.name);

  // ── Federation ─────────────────────────────────────────────────────────────

  Future<String?> getSharingScopeName() =>
      _storage.read(key: _kSharingScopeKey);

  Future<void> setSharingScopeName(String name) =>
      _storage.write(key: _kSharingScopeKey, value: name);

  Future<bool> isListenActivityEnabled() async {
    final v = await _storage.read(key: _kListenActivityEnabledKey);
    return v == 'true';
  }

  Future<void> setListenActivityEnabled(bool enabled) =>
      _storage.write(key: _kListenActivityEnabledKey, value: enabled.toString());
}

enum NotificationAutoClear {
  sevenDays,
  thirtyDays,
  never;

  String get label => switch (this) {
        NotificationAutoClear.sevenDays => '7 days',
        NotificationAutoClear.thirtyDays => '30 days',
        NotificationAutoClear.never => 'Never',
      };

  Duration? get duration => switch (this) {
        NotificationAutoClear.sevenDays => const Duration(days: 7),
        NotificationAutoClear.thirtyDays => const Duration(days: 30),
        NotificationAutoClear.never => null,
      };
}
