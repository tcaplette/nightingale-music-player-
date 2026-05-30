import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:nightingale/core/config/env_config.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/shared/components/error_boundary.dart';
import 'package:nightingale/app.dart';

void main() async {
  developer.Timeline.startSync('startup');
  developer.log('MAIN: start', name: 'nightingale.main');

  developer.Timeline.startSync('binding_init');
  WidgetsFlutterBinding.ensureInitialized();
  // Cap in-memory image cache to 50 images; disk cache capped via
  // cached_network_image configuration in the widget layer.
  PaintingBinding.instance.imageCache.maximumSize = 50;
  developer.Timeline.finishSync();
  developer.log('MAIN: WidgetsFlutterBinding done', name: 'nightingale.main');

  developer.Timeline.startSync('just_audio_background_init');
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.nightingale.audio',
    androidNotificationChannelName: 'Nightingale',
    androidNotificationOngoing: true,
    androidStopForegroundOnPause: true,
  );
  developer.Timeline.finishSync();
  developer.log('MAIN: JustAudioBackground.init done', name: 'nightingale.main');

  AppConfig.initialize(Environment.dev);
  developer.log('MAIN: AppConfig initialized', name: 'nightingale.main');

  developer.Timeline.startSync('service_locator_init');
  await setupServiceLocator();
  developer.Timeline.finishSync();
  developer.log('MAIN: setupServiceLocator done', name: 'nightingale.main');

  setupErrorWidget();
  developer.log('MAIN: setupErrorWidget done', name: 'nightingale.main');

  developer.Timeline.startSync('run_app');
  runApp(const NightingaleApp());
  developer.Timeline.finishSync();
  developer.Timeline.finishSync(); // startup
  developer.log('MAIN: runApp called', name: 'nightingale.main');
}
