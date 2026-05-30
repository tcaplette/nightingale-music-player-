import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/core/resilience/activity_queue_service.dart';
import 'package:nightingale/core/resilience/offline_mode_coordinator.dart';
import 'package:nightingale/core/router/app_router.dart';
import 'package:nightingale/features/library/library_lifecycle_watcher.dart';
import 'package:nightingale/shared/components/error_boundary.dart';
import 'package:nightingale/shared/theme/app_theme.dart';

class NightingaleApp extends StatelessWidget {
  const NightingaleApp({super.key});

  @override
  Widget build(BuildContext context) {
    developer.log('APP: NightingaleApp.build', name: 'nightingale.app');
    return ErrorBoundaryWidget(
      child: ProviderScope(
        child: _AppBody(),
      ),
    );
  }
}

class _AppBody extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AppBody> createState() => _AppBodyState();
}

class _AppBodyState extends ConsumerState<_AppBody> {
  bool _wasOnline = true;

  @override
  void initState() {
    super.initState();
    // Listen for transitions from offline → online and flush the activity queue.
    ref.listenManual(isOnlineProvider, (previous, next) {
      final nowOnline = next.valueOrNull ?? true;
      if (!_wasOnline && nowOnline) {
        sl<ActivityQueueService>().flush().ignore();
      }
      _wasOnline = nowOnline;
    });
  }

  @override
  Widget build(BuildContext context) {
    developer.log('APP: _AppBody.build', name: 'nightingale.app');
    return LibraryLifecycleWatcher(
      child: MaterialApp.router(
        title: 'Nightingale',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
