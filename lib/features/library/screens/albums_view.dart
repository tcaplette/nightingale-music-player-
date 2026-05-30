import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nightingale/features/library/models/album_model.dart';
import 'package:nightingale/features/library/providers/library_providers.dart';
import 'package:nightingale/shared/components/empty_state_widget.dart';
import 'package:nightingale/shared/components/skeleton_loader.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

class AlbumsView extends ConsumerWidget {
  const AlbumsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumsAsync = ref.watch(albumsProvider);

    return albumsAsync.when(
      loading: () => const SkeletonListView(count: 8),
      error: (e, _) => EmptyStateWidget(
        icon: Icons.error_outline,
        headline: 'Could not load albums',
        subhead: e.toString(),
      ),
      data: (albums) {
        if (albums.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.album_outlined,
            headline: 'No albums yet',
            subhead: 'Albums will appear once your library is scanned.',
          );
        }
        return ListView.builder(
          itemCount: albums.length,
          itemBuilder: (context, i) => _AlbumTile(
            album: albums[i],
            onTap: () => context.push('/library/albums/${albums[i].id}'),
          ),
        );
      },
    );
  }
}

class _AlbumTile extends StatelessWidget {
  const _AlbumTile({required this.album, required this.onTap});
  final AlbumModel album;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      leading: _ArtworkThumbnail(path: album.artworkPath, size: 48),
      title: Text(
        album.name,
        style: textTheme.bodyLarge,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        album.artist,
        style: textTheme.labelMedium,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: scheme.onSurface.withValues(alpha: 0.3),
      ),
      onTap: onTap,
    );
  }
}

class _ArtworkThumbnail extends StatelessWidget {
  const _ArtworkThumbnail({required this.path, required this.size});
  final String? path;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (path != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.asset(
          path!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(scheme),
        ),
      );
    }
    return _placeholder(scheme);
  }

  Widget _placeholder(ColorScheme scheme) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        Icons.music_note,
        size: size * 0.5,
        color: scheme.onSurface.withValues(alpha: 0.2),
      ),
    );
  }
}
