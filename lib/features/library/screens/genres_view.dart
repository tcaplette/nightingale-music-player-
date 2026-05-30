import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale/features/library/models/track_model.dart';
import 'package:nightingale/features/library/providers/library_providers.dart';
import 'package:nightingale/features/library/screens/library_empty_state.dart';
import 'package:nightingale/features/playback/providers/playback_providers.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

class GenresView extends ConsumerWidget {
  const GenresView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genresAsync = ref.watch(genresProvider);

    return genresAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (genres) {
        if (genres.isEmpty) {
          return const LibraryEmptyState(
            icon: Icons.label_outline,
            message: 'No genres found',
            detail: 'Genres appear when your tracks have genre tags.',
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.read(libraryScanProvider.notifier).scan(),
          child: ListView.builder(
            itemCount: genres.length,
            itemBuilder: (context, i) => _GenreTile(genre: genres[i]),
          ),
        );
      },
    );
  }
}

class _GenreTile extends ConsumerWidget {
  const _GenreTile({required this.genre});
  final String genre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      title: Text(genre, style: textTheme.bodyLarge),
      trailing: Icon(
        Icons.expand_more,
        color: scheme.onSurface.withValues(alpha: 0.3),
      ),
      children: [_GenreTrackList(genre: genre)],
    );
  }
}

class _GenreTrackList extends ConsumerWidget {
  const _GenreTrackList({required this.genre});
  final String genre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksAsync = ref.watch(genreTracksProvider(genre));
    return tracksAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text('Error: $e'),
      ),
      data: (tracks) => Column(
        children: [
          for (var i = 0; i < tracks.length; i++)
            _TrackRow(
              track: tracks[i],
              onTap: () => ref
                  .read(playbackProvider.notifier)
                  .loadAndPlay(tracks, startIndex: i),
            ),
        ],
      ),
    );
  }
}

class _TrackRow extends StatelessWidget {
  const _TrackRow({required this.track, required this.onTap});
  final TrackModel track;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xs,
      ),
      title: Text(track.title, style: textTheme.bodyMedium),
      subtitle: Text(track.artist, style: textTheme.labelSmall),
      onTap: onTap,
    );
  }
}
