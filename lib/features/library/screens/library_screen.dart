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
import 'package:nightingale/features/social/providers/notifications_notifier.dart';
import 'package:nightingale/shared/components/network_state/partial_library_widget.dart';
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
    final isStale = scanState.isMediaStorePotentiallyStale;
    final isScanning = scanState.status == LibraryScanStatus.scanning;

    return Scaffold(
      backgroundColor: Colors.green, // DEBUG: obvious color to verify rendering
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
          // Phase 5 — Feed shortcut
          IconButton(
            icon: const Icon(Icons.people_outline),
            tooltip: 'Feed',
            onPressed: () => context.push(AppRoutes.feed),
          ),
          // Phase 6 — Discover shortcut
          IconButton(
            icon: const Icon(Icons.explore_outlined),
            tooltip: 'Discover',
            onPressed: () => context.push(AppRoutes.discover),
          ),
          // Phase 5 — Notifications shortcut with unread badge
          _NotificationsBadgeButton(),
          IconButton(
            icon: isScanning
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Refresh library',
            onPressed: isScanning
                ? null
                : () => ref.read(libraryScanProvider.notifier).scan(),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () => context.push(AppRoutes.search),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Songs'),
            Tab(text: 'Albums'),
            Tab(text: 'Artists'),
            Tab(text: 'Genres'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (isStale)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: const PartialLibraryWidget(
                displayName: 'Your',
                statusLabel: 'Library may be incomplete',
              ),
            ),
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

class _NotificationsBadgeButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(
      notificationsProvider.select((s) => s.unreadCount),
    );

    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          tooltip: 'Notifications',
          onPressed: () => context.push(AppRoutes.notifications),
        ),
        if (unread > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                unread > 99 ? '99+' : '$unread',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
