import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/features/library/models/album_model.dart';
import 'package:nightingale/features/library/providers/library_providers.dart';
import 'package:nightingale/features/library/services/album_metadata_fetch_service.dart';
import 'package:nightingale/features/library/widgets/album_metadata_result_sheet.dart';
import 'package:nightingale/shared/components/artwork_thumbnail.dart';
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
          return RefreshIndicator(
            onRefresh: () => ref.read(libraryScanProvider.notifier).scan(),
            child: const EmptyStateWidget(
              icon: Icons.album_outlined,
              headline: 'No albums yet',
              subhead: 'Albums will appear once your library is scanned.',
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.read(libraryScanProvider.notifier).scan(),
          child: ListView.builder(
            itemCount: albums.length,
            itemBuilder: (context, i) => _AlbumTile(
              album: albums[i],
              onTap: () => context.push('/library/albums/${albums[i].id}'),
              onLongPress: () =>
                  _onAlbumLongPress(context, ref, albums[i]),
            ),
          ),
        );
      },
    );
  }
}

Future<void> _onAlbumLongPress(
  BuildContext context,
  WidgetRef ref,
  AlbumModel album,
) async {
  // Show the fetch sheet — user edits fields, previews result, then confirms
  final confirmed = await showModalBottomSheet<({String albumName, String artist})?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _AlbumFetchSheet(album: album),
  );

  if (confirmed == null || !context.mounted) return;

  // Load tracks
  final tracks = await ref.read(albumTracksProvider(album.id).future);
  if (tracks.isEmpty || !context.mounted) return;

  // Capture navigator before async gap
  final navigator = Navigator.of(context, rootNavigator: true);

  // Progress dialog
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const AlertDialog(
      content: Row(
        children: [
          CircularProgressIndicator(),
          SizedBox(width: AppSpacing.md),
          Expanded(child: Text('Applying metadata…')),
        ],
      ),
    ),
  );

  final result = await sl<AlbumMetadataFetchService>().fetch(
    album,
    tracks,
    albumNameOverride: confirmed.albumName,
    artistOverride: confirmed.artist,
  );

  // Dismiss progress, show result, then invalidate (order matters — see nav lock fix)
  navigator.pop();
  if (!context.mounted) return;
  showAlbumMetadataResultSheet(context, result);
  ref.invalidate(albumTracksProvider(album.id));
}

// ── Album fetch sheet ─────────────────────────────────────────────────────────

enum _FetchSheetState { idle, searching, preview, error }

class _AlbumFetchSheet extends StatefulWidget {
  const _AlbumFetchSheet({required this.album});
  final AlbumModel album;

  @override
  State<_AlbumFetchSheet> createState() => _AlbumFetchSheetState();
}

class _AlbumFetchSheetState extends State<_AlbumFetchSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _artistCtrl;

  _FetchSheetState _state = _FetchSheetState.idle;
  AlbumPreviewResult? _preview;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.album.name);
    _artistCtrl = TextEditingController(text: widget.album.artist);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _artistCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final name = _nameCtrl.text.trim();
    final artist = _artistCtrl.text.trim();
    if (name.isEmpty || artist.isEmpty) return;

    setState(() {
      _state = _FetchSheetState.searching;
      _preview = null;
    });

    final result = await sl<AlbumMetadataFetchService>().previewAlbum(
      name,
      artist,
      widget.album.id,
      expectedTrackCount: widget.album.trackCount,
    );

    if (!mounted) return;
    setState(() {
      _preview = result;
      _state =
          result != null ? _FetchSheetState.preview : _FetchSheetState.error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Header + Search button
            Row(
              children: [
                Expanded(
                  child: Text('Fetch Album Metadata',
                      style: theme.textTheme.titleMedium),
                ),
                FilledButton.tonalIcon(
                  onPressed:
                      _state == _FetchSheetState.searching ? null : _search,
                  icon: _state == _FetchSheetState.searching
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search, size: 16),
                  label: Text(_state == _FetchSheetState.searching
                      ? 'Searching…'
                      : 'Search'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Editable fields
            TextField(
              controller: _nameCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Album name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _artistCtrl,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: const InputDecoration(
                labelText: 'Artist',
                border: OutlineInputBorder(),
              ),
            ),

            // Preview card
            if (_state == _FetchSheetState.preview && _preview != null) ...[
              const SizedBox(height: AppSpacing.md),
              _PreviewCard(preview: _preview!),
            ],

            // Not found
            if (_state == _FetchSheetState.error) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'No match found — try adjusting the album name or artist.',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: scheme.error),
              ),
            ],

            const SizedBox(height: AppSpacing.md),

            // Apply button — only shown after a successful preview
            if (_state == _FetchSheetState.preview)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop((
                    albumName: _nameCtrl.text.trim(),
                    artist: _artistCtrl.text.trim(),
                  )),
                  child: const Text('Apply to all tracks'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.preview});
  final AlbumPreviewResult preview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final lookup = preview.lookup;

    final details = <String>[
      if (lookup.genre != null) lookup.genre!,
      if (lookup.releaseYear != null) lookup.releaseYear.toString(),
      if (lookup.tracks.isNotEmpty) '${lookup.tracks.length} tracks',
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Artwork preview
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: preview.artworkPath != null
                ? Image.file(
                    File(preview.artworkPath!),
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (context, e, stack) =>
                        _artworkPlaceholder(scheme),
                  )
                : _artworkPlaceholder(scheme),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Found via ${lookup.source}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF34C759),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (details.isNotEmpty)
                  Text(
                    details.join(' · '),
                    style: theme.textTheme.labelSmall,
                  ),
                if (preview.artworkPath == null)
                  Text(
                    'No artwork found',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _artworkPlaceholder(ColorScheme scheme) => Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(Icons.image_not_supported_outlined,
            size: 20, color: scheme.onSurfaceVariant),
      );
}

class _AlbumTile extends StatelessWidget {
  const _AlbumTile({
    required this.album,
    required this.onTap,
    this.onLongPress,
  });

  final AlbumModel album;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      leading: ArtworkThumbnail(path: album.artworkPath, size: 48),
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
      onLongPress: onLongPress,
    );
  }
}

