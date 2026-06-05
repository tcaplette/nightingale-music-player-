import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nightingale/core/router/app_router.dart';
import 'package:nightingale/features/library/models/artist_model.dart';
import 'package:nightingale/features/library/providers/library_providers.dart';
import 'package:nightingale/features/library/screens/library_empty_state.dart';
import 'package:nightingale/features/playback/providers/playback_providers.dart';
import 'package:nightingale/features/social/providers/federated_radio_provider.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

class ArtistsView extends ConsumerWidget {
  const ArtistsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistsAsync = ref.watch(artistsProvider);

    return artistsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (artists) {
        if (artists.isEmpty) {
          return const LibraryEmptyState(
            icon: Icons.person_outline,
            message: 'No artists found',
            detail: 'Artists appear after your library is scanned.',
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.read(libraryScanProvider.notifier).scan(),
          child: ListView.builder(
            itemCount: artists.length,
            itemBuilder: (context, i) => _ArtistTile(
              artist: artists[i],
              onTap: () => context.push(
                '/library/artists/${Uri.encodeComponent(artists[i].name)}',
              ),
              onLongPress: () => _showArtistMenu(context, ref, artists[i]),
            ),
          ),
        );
      },
    );
  }

  void _showArtistMenu(BuildContext context, WidgetRef ref, ArtistModel artist) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.cell_tower),
              title: const Text('Start Radio'),
              onTap: () async {
                Navigator.of(ctx).pop();
                await ref.read(federatedRadioProvider.notifier).startSeeded(artist.name);
                ref.read(playbackProvider.notifier).initiateRadio().ignore();
                if (context.mounted) context.push(AppRoutes.nowPlaying);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ArtistTile extends StatelessWidget {
  const _ArtistTile({required this.artist, required this.onTap, this.onLongPress});
  final ArtistModel artist;
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
      title: Text(artist.name, style: textTheme.bodyLarge),
      subtitle: Text(
        '${artist.albumCount} ${artist.albumCount == 1 ? "album" : "albums"}',
        style: textTheme.labelMedium,
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
