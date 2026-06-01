import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nightingale/core/debug/debug_overlay.dart';
import 'package:nightingale/core/router/app_router.dart';
import 'package:nightingale/features/library/providers/library_providers.dart';
import 'package:nightingale/features/library/screens/all_songs_view.dart';
import 'package:nightingale/features/library/screens/albums_view.dart';
import 'package:nightingale/features/library/screens/artists_view.dart';
import 'package:nightingale/features/library/screens/genres_view.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  int _tapCount = 0;
  DateTime? _lastTap;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _handleDevTap() {
    if (!kDebugMode) return;
    final now = DateTime.now();
    if (_lastTap != null && now.difference(_lastTap!) > const Duration(seconds: 2)) {
      _tapCount = 0;
    }
    _lastTap = now;
    _tapCount++;
    if (_tapCount >= 7) {
      _tapCount = 0;
      DebugOverlayController.show(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    developer.log('LIBRARY: build', name: 'nightingale.ui');
    final scanState = ref.watch(libraryScanProvider);
    final isScanning = scanState.status == LibraryScanStatus.scanning;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          if (kDebugMode)
            GestureDetector(
              onTap: _handleDevTap,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Center(
                  child: Text('DEV', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () => context.push(AppRoutes.search),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(
            kTextTabBarHeight + (isScanning ? 3.0 : 0.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TabBar(
                controller: _tabs,
                tabs: const [
                  Tab(text: 'Songs'),
                  Tab(text: 'Albums'),
                  Tab(text: 'Artists'),
                  Tab(text: 'Genres'),
                ],
              ),
              if (isScanning)
                const LinearProgressIndicator(minHeight: 3),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: const [
                AllSongsView(),
                AlbumsView(),
                ArtistsView(),
                GenresView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
