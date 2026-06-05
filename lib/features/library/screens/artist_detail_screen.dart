import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nightingale/features/library/providers/library_providers.dart';
import 'package:nightingale/features/playback/providers/playback_providers.dart';
import 'package:nightingale/shared/components/artwork_thumbnail.dart';
import 'package:nightingale/shared/components/buttons/app_button.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

class ArtistDetailScreen extends ConsumerWidget {
  const ArtistDetailScreen({super.key, required this.artist});
  final String artist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumsAsync = ref.watch(artistAlbumsProvider(artist));
    final tracksAsync = ref.watch(artistTracksProvider(artist));
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(artist)),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(artist, style: textTheme.displayLarge),
                  const SizedBox(height: AppSpacing.md),
                  tracksAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (tracks) => AppButton(
                      label: 'Play All',
                      onPressed: tracks.isEmpty
                          ? null
                          : () => ref
                              .read(playbackProvider.notifier)
                              .loadAndPlay(tracks),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'ALBUMS',
                    style: textTheme.labelMedium?.copyWith(letterSpacing: 1.2),
                  ),
                ],
              ),
            ),
          ),
          albumsAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Center(child: Text('Error: $e')),
            ),
            data: (albums) => SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final album = albums[i];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    leading: ArtworkThumbnail(path: album.artworkPath, size: 48),
                    title: Text(album.name, style: textTheme.bodyLarge),
                    subtitle: album.releaseYear != null
                        ? Text(
                            '${album.releaseYear}',
                            style: textTheme.labelMedium,
                          )
                        : null,
                    trailing: Icon(
                      Icons.chevron_right,
                      color: scheme.onSurface.withValues(alpha: 0.3),
                    ),
                    onTap: () => context.push(
                      '/library/albums/'
                      '${Uri.encodeComponent(album.artist)}/'
                      '${Uri.encodeComponent(album.name)}',
                    ),
                  );
                },
                childCount: albums.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
