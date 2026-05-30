import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale/features/library/providers/library_providers.dart';

class LibraryLifecycleWatcher extends ConsumerStatefulWidget {
  const LibraryLifecycleWatcher({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<LibraryLifecycleWatcher> createState() =>
      _LibraryLifecycleWatcherState();
}

class _LibraryLifecycleWatcherState
    extends ConsumerState<LibraryLifecycleWatcher> {
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    developer.log('LIFECYCLE: initState', name: 'nightingale.lifecycle');
    _listener = AppLifecycleListener(
      onResume: _onResume,
    );
    // Trigger an initial scan on first launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      developer.log('LIFECYCLE: postFrameCallback - triggering scan', name: 'nightingale.lifecycle');
      ref.read(libraryScanProvider.notifier).scan();
    });
  }

  void _onResume() {
    developer.log('LIFECYCLE: onResume - triggering scan', name: 'nightingale.lifecycle');
    ref.read(libraryScanProvider.notifier).scan();
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    developer.log('LIFECYCLE: build', name: 'nightingale.lifecycle');
    return widget.child;
  }
}
