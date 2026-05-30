import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale/features/library/providers/library_providers.dart';
import 'package:nightingale/features/playback/providers/playback_providers.dart';
import 'package:nightingale/shared/components/buttons/app_button.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

class AlbumDetailScreen extends ConsumerWidget {
  const AlbumDetailScreen({super.key, required this.albumId});
  final int albumId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumAsync = ref.watch(albumDetailProvider(albumId));
    final tracksAsync = ref.watch(albumTracksProvider(albumId));
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: albumAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (album) {
          if (album == null) {
            return const Center(child: Text('Album not found'));
          }
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: _AlbumHeader(
                    artworkPath: album.artworkPath,
                    albumName: album.name,
                    artistName: album.artist,
                    releaseYear: album.releaseYear,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: tracksAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
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
          Expanded(
            child: artworkPath != null
                ? Image.asset(
                    artworkPath!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => _artworkPlaceholder(scheme),
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
