import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nightingale/features/library/models/artist_model.dart';
import 'package:nightingale/features/library/providers/library_providers.dart';
import 'package:nightingale/features/library/screens/library_empty_state.dart';
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
        return ListView.builder(
          itemCount: artists.length,
          itemBuilder: (context, i) => _ArtistTile(
            artist: artists[i],
            onTap: () => context.push(
              '/library/artists/${Uri.encodeComponent(artists[i].name)}',
            ),
          ),
        );
      },
    );
  }
}

class _ArtistTile extends StatelessWidget {
  const _ArtistTile({required this.artist, required this.onTap});
  final ArtistModel artist;
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
    );
  }
}
