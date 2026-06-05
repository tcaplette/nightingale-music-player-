import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nightingale/core/resilience/offline_mode_coordinator.dart';
import 'package:nightingale/core/router/app_router.dart';
import 'package:nightingale/features/playback/providers/playback_providers.dart';
import 'package:nightingale/features/social/providers/federated_radio_provider.dart';

class AppBottomNav extends ConsumerWidget {
  const AppBottomNav({
    super.key,
    required this.navigationShell,
    required this.child,
  });

  final StatefulNavigationShell navigationShell;
  final Widget child;

  // Radio always sits at bar index 0 (left of Library).
  // Shell branches: Library=0, Feed=1, Discover=2.
  // Bar indices: Radio=0, Library=1, Feed=2, Discover=3.
  // Radio is always present — greyed out and non-tappable when offline.
  static int _barIndex(int shellIndex) => shellIndex + 1;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider).valueOrNull ?? false;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _barIndex(navigationShell.currentIndex),
        onDestinationSelected: (index) {
          if (index == 0) {
            if (!isOnline) return; // non-tappable offline
            final radioEnabled =
                ref.read(federatedRadioProvider).valueOrNull?.enabled ?? false;
            if (!radioEnabled) {
              ref.read(federatedRadioProvider.notifier).toggle().then((_) {
                ref.read(playbackProvider.notifier).initiateRadio().ignore();
              });
            }
            context.push(AppRoutes.nowPlaying);
            return;
          }
          final shellIndex = index - 1;
          navigationShell.goBranch(
            shellIndex,
            initialLocation: shellIndex == navigationShell.currentIndex,
          );
        },
        destinations: [
          NavigationDestination(
            icon: _RadioIcon(online: isOnline),
            selectedIcon: _RadioIcon(online: isOnline),
            label: 'Stream',
          ),
          const NavigationDestination(
            icon: Icon(Icons.library_music_outlined),
            selectedIcon: Icon(Icons.library_music),
            label: 'Library',
          ),
          const NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Feed',
          ),
          const NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Discover',
          ),
        ],
      ),
    );
  }
}

class _RadioIcon extends StatelessWidget {
  const _RadioIcon({required this.online});
  final bool online;

  @override
  Widget build(BuildContext context) {
    final color = online
        ? null
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38);

    if (online) return const Icon(Icons.cell_tower);

    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        children: [
          Icon(Icons.cell_tower, color: color),
          CustomPaint(
            size: const Size(24, 24),
            painter: _SlashPainter(color: color!),
          ),
        ],
      ),
    );
  }
}

class _SlashPainter extends CustomPainter {
  const _SlashPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    // Bottom-left to top-right diagonal slash
    canvas.drawLine(
      Offset(size.width * 0.15, size.height * 0.85),
      Offset(size.width * 0.85, size.height * 0.15),
      paint,
    );
  }

  @override
  bool shouldRepaint(_SlashPainter old) => old.color != color;
}
