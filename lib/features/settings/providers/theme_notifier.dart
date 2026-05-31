import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/features/settings/data/settings_repository.dart';

class ThemeNotifier extends AsyncNotifier<ThemeMode> {
  @override
  Future<ThemeMode> build() =>
      sl<SettingsRepository>().getThemeMode();

  Future<void> setTheme(ThemeMode mode) async {
    await sl<SettingsRepository>().setThemeMode(mode);
    state = AsyncData(mode);
  }
}

final themeNotifierProvider =
    AsyncNotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);
