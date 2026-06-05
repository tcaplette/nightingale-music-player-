import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale/features/library/providers/library_providers.dart';
import 'package:nightingale/features/playback/providers/playback_providers.dart';
import 'package:nightingale/shared/components/buttons/app_button.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

class AlbumDetailScreen extends ConsumerWidget {
  const AlbumDetailScreen({
    super.key,
    required this.albumName,
    required this.albumArtist,
  });

  final String albumName;
  final String albumArtist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (albumName: albumName, albumArtist: albumArtist);
    final albumAsync = ref.watch(albumDetailProvider(key));
    final tracksAsync = ref.watch(albumTracksProvider(key));
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: albumAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (album) {
          final artworkPath = album?.artworkPath;
          final displayName = album?.name ?? albumName;
          final displayArtist = album?.artist ?? albumArtist;
          final releaseYear = album?.releaseYear;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _AlbumHeader(
                  artworkPath: artworkPath,
                  albumName: displayName,
                  artistName: displayArtist,
                  releaseYear: releaseYear,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: tracksAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (e, _) => const SizedBox.shrink(),
                    data: (tracks) => AppButton(
                      label: 'Play Album',
                      onPressed: tracks.isEmpty
                          ? null
                          : () {
                              ref
                                  .read(playbackProvider.notifier)
                                  .loadAndPlay(tracks);
                            },
                    ),
                  ),
                ),
              ),
              tracksAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: Center(child: Text('Error: $e')),
                ),
                data: (tracks) => SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final track = tracks[i];
                      // ignore: avoid_print
                      print('[AlbumDetail] "${track.title}" trackNumber=${track.trackNumber}');
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        leading: SizedBox(
                          width: 32,
                          child: Text(
                            track.trackNumber?.toString() ?? '—',
                            style: textTheme.labelMedium?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.4),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        title: Text(track.title, style: textTheme.bodyLarge),
                        trailing: Text(
                          _formatDuration(track.duration),
                          style: textTheme.labelSmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        onTap: () => ref
                            .read(playbackProvider.notifier)
                            .loadAndPlay(tracks, startIndex: i),
                      );
                    },
                    childCount: tracks.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _AlbumHeader extends StatelessWidget {
  const _AlbumHeader({
    required this.artworkPath,
    required this.albumName,
    required this.artistName,
    required this.releaseYear,
  });

  final String? artworkPath;
  final String albumName;
  final String artistName;
  final int? releaseYear;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      color: scheme.surfaceContainerHighest,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: artworkPath != null
                ? Image.file(
                    File(artworkPath!),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, e, stack) => _artworkPlaceholder(scheme),
                  )
                : _artworkPlaceholder(scheme),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(albumName, style: textTheme.displayLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  releaseYear != null
                      ? '$artistName · $releaseYear'
                      : artistName,
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _artworkPlaceholder(ColorScheme scheme) {
    return Center(
      child: Icon(
        Icons.album,
        size: 80,
        color: scheme.onSurface.withValues(alpha: 0.15),
      ),
    );
  }
}
