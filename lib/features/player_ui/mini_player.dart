import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nightingale/core/router/app_router.dart';
import 'package:nightingale/features/playback/providers/playback_providers.dart';
import 'package:nightingale/shared/theme/app_radius.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playbackAsync = ref.watch(playbackProvider);
    final state = playbackAsync.valueOrNull;
    if (state == null || !state.hasQueue || state.currentTrack == null) {
      return const SizedBox.shrink();
    }

    final track = state.currentTrack!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      label: 'Now playing: ${track.title} by ${track.artist}. Tap to open player.',
      button: true,
      child: GestureDetector(
      onTap: () => context.push(AppRoutes.nowPlaying),
      child: Container(
        height: AppDimensions.miniPlayerHeight,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: AppRadius.lgAll,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: AppSpacing.sm),
            // Artwork thumbnail
            _ArtworkThumb(artworkPath: track.artworkPath),
            const SizedBox(width: AppSpacing.sm),
            // Track info
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    track.artist,
                    style: textTheme.labelSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Play/Pause button
            Semantics(
              label: state.isPlaying ? 'Pause' : 'Play',
              button: true,
              child: IconButton(
                icon: Icon(
                  state.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: scheme.onSurface,
                ),
                onPressed: () {
                  if (state.isPlaying) {
                    ref.read(playbackProvider.notifier).pause();
                  } else {
                    ref.read(playbackProvider.notifier).play();
                  }
                },
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
        ),
      ),
    ),
    );
  }
}

class _ArtworkThumb extends StatelessWidget {
  const _ArtworkThumb({required this.artworkPath});
  final String? artworkPath;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const size = 44.0;

    if (artworkPath != null) {
      return ClipRRect(
        borderRadius: AppRadius.smAll,
        child: Image.asset(
          artworkPath!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(scheme, size),
        ),
      );
    }
    return _placeholder(scheme, size);
  }

  Widget _placeholder(ColorScheme scheme, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: AppRadius.smAll,
      ),
      child: Icon(
        Icons.music_note,
        size: size * 0.5,
        color: scheme.onSurface.withValues(alpha: 0.2),
      ),
    );
  }
}
