import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/features/library/library_repository.dart';
import 'package:nightingale/features/library/models/album_model.dart';
import 'package:nightingale/features/library/providers/library_providers.dart';
import 'package:nightingale/shared/components/artwork_thumbnail.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

/// Modal bottom sheet that lets the user choose which discovered albums to
/// include in their library. Selecting an album includes all of its tracks.
/// Albums show a three-state indicator: fully included, partially included,
/// or excluded.
class AlbumsSelectionSheet extends ConsumerWidget {
  const AlbumsSelectionSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumsAsync = ref.watch(discoveredAlbumsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            _SheetHandle(),
            _AlbumsSheetHeader(albumsAsync: albumsAsync),
            const Divider(height: 1),
            Expanded(
              child: albumsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (albums) => albums.isEmpty
                    ? const _EmptyDiscovery()
                    : _AlbumList(
                        albums: albums,
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

class _AlbumsSheetHeader extends ConsumerWidget {
  const _AlbumsSheetHeader({required this.albumsAsync});
  final AsyncValue<List<AlbumModel>> albumsAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albums = albumsAsync.valueOrNull ?? [];
    final allFullyIncluded = albums.isNotEmpty &&
        albums.every((a) => a.includedTrackCount == a.trackCount && a.trackCount > 0);
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
              'Add Albums',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          TextButton(
            onPressed: albums.isEmpty
                ? null
                : () async {
                    if (allFullyIncluded) {
                      await repo.excludeAllTracks();
                    } else {
                      await repo.includeAllTracks();
                    }
                  },
            child: Text(allFullyIncluded ? 'Deselect All' : 'Select All'),
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

class _AlbumList extends ConsumerWidget {
  const _AlbumList({
    required this.albums,
    required this.scrollController,
  });

  final List<AlbumModel> albums;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = sl<LibraryRepository>();

    return ListView.builder(
      controller: scrollController,
      itemCount: albums.length,
      itemBuilder: (context, i) {
        final album = albums[i];
        return _AlbumRow(
          album: album,
          onToggle: () async {
            final fullyIncluded = album.includedTrackCount == album.trackCount &&
                album.trackCount > 0;
            if (fullyIncluded) {
              await repo.excludeAlbum(album.name, album.artist);
            } else {
              await repo.includeAlbum(album.name, album.artist);
            }
          },
        );
      },
    );
  }
}

class _AlbumRow extends StatelessWidget {
  const _AlbumRow({required this.album, required this.onToggle});

  final AlbumModel album;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    final fullyIncluded =
        album.trackCount > 0 && album.includedTrackCount == album.trackCount;
    final partiallyIncluded =
        album.includedTrackCount > 0 && album.includedTrackCount < album.trackCount;

    Widget indicator;
    if (partiallyIncluded) {
      indicator = Icon(
        Icons.indeterminate_check_box_outlined,
        color: scheme.primary,
      );
    } else {
      indicator = Checkbox(
        value: fullyIncluded,
        tristate: false,
        onChanged: (_) => onToggle(),
      );
    }

    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            ArtworkThumbnail(path: album.artworkPath, size: 48),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.name,
                    style: textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${album.artist} · ${album.trackCount} tracks',
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            indicator,
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
              Icons.album_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No albums found on this device',
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
