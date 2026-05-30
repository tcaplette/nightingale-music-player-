import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:nightingale/core/config/env_config.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/shared/components/error_boundary.dart';
import 'package:nightingale/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.nightingale.audio',
    androidNotificationChannelName: 'Nightingale',
    androidNotificationOngoing: true,
    androidStopForegroundOnPause: true,
  );
  AppConfig.initialize(Environment.staging);
  await setupServiceLocator();
  setupErrorWidget();
  runApp(const NightingaleApp());
}
