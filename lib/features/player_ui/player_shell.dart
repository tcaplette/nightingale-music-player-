import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale/features/playback/providers/playback_providers.dart';
import 'package:nightingale/features/player_ui/mini_player.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

/// Global shell that sits above the navigator and keeps the MiniPlayer
/// persistent across all routes. Bottom padding is injected via
/// [MediaQuery] override so list content is never hidden behind the bar.
class PlayerShell extends ConsumerWidget {
  const PlayerShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playbackAsync = ref.watch(playbackProvider);
    final hasQueue = playbackAsync.valueOrNull?.hasQueue ?? false;

    final bottomPad = hasQueue
        ? AppDimensions.miniPlayerHeight + AppSpacing.sm
        : 0.0;

    return Stack(
      children: [
        MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: MediaQuery.of(context).padding.copyWith(
              bottom: MediaQuery.of(context).padding.bottom + bottomPad,
            ),
          ),
          child: child,
        ),
        if (hasQueue)
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom,
            child: const RepaintBoundary(child: MiniPlayer()),
          ),
      ],
    );
  }
}
