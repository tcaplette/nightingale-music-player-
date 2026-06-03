import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/features/library/library_repository.dart';
import 'package:nightingale/features/library/models/track_model.dart';
import 'package:nightingale/features/library/providers/library_providers.dart';
import 'package:nightingale/shared/components/artwork_thumbnail.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

/// Modal bottom sheet that lets the user choose which discovered tracks to
/// include in their library. Toggling a checkbox immediately persists the
/// change — there is no pending batch; "Done" simply dismisses the sheet.
class SongsSelectionSheet extends ConsumerWidget {
  const SongsSelectionSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksAsync = ref.watch(discoveredTracksProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            _SheetHandle(),
            _SongsSheetHeader(tracksAsync: tracksAsync),
            const Divider(height: 1),
            Expanded(
              child: tracksAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (tracks) => tracks.isEmpty
                    ? const _EmptyDiscovery()
                    : _TrackList(
                        tracks: tracks,
                        scrollController: scrollController,
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _SongsSheetHeader extends ConsumerWidget {
  const _SongsSheetHeader({required this.tracksAsync});
  final AsyncValue<List<TrackModel>> tracksAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracks = tracksAsync.valueOrNull ?? [];
    final allIncluded = tracks.isNotEmpty && tracks.every((t) => t.isIncluded);
    final repo = sl<LibraryRepository>();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Add Songs',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          TextButton(
            onPressed: tracks.isEmpty
                ? null
                : () async {
                    if (allIncluded) {
                      await repo.excludeAllTracks();
                    } else {
                      await repo.includeAllTracks();
                    }
                  },
            child: Text(allIncluded ? 'Deselect All' : 'Select All'),
          ),
          const SizedBox(width: AppSpacing.xs),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _TrackList extends ConsumerWidget {
  const _TrackList({
    required this.tracks,
    required this.scrollController,
  });

  final List<TrackModel> tracks;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = sl<LibraryRepository>();

    return ListView.builder(
      controller: scrollController,
      itemCount: tracks.length,
      itemBuilder: (context, i) {
        final track = tracks[i];
        return _TrackRow(
          track: track,
          onToggle: () async {
            if (track.isIncluded) {
              await repo.excludeTrack(track.id);
            } else {
              await repo.includeTrack(track.id);
            }
          },
        );
      },
    );
  }
}

class _TrackRow extends StatelessWidget {
  const _TrackRow({required this.track, required this.onToggle});

  final TrackModel track;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            ArtworkThumbnail(path: track.artworkPath ?? track.albumArtworkPath, size: 40),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    style: textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    track.artist,
                    style: textTheme.labelSmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Checkbox(
              value: track.isIncluded,
              onChanged: (_) => onToggle(),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDiscovery extends StatelessWidget {
  const _EmptyDiscovery();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.music_off_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No music found on this device',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
