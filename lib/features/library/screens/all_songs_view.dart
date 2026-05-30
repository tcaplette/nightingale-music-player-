import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale/features/library/models/track_model.dart';
import 'package:nightingale/features/library/providers/library_providers.dart';
import 'package:nightingale/features/playback/providers/playback_providers.dart';
import 'package:nightingale/shared/components/empty_state_widget.dart';
import 'package:nightingale/shared/components/skeleton_loader.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

class AllSongsView extends ConsumerWidget {
  const AllSongsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksAsync = ref.watch(allTracksProvider);

    return tracksAsync.when(
      loading: () => const SkeletonListView(count: 10),
      error: (e, _) => EmptyStateWidget(
        icon: Icons.error_outline,
        headline: 'Could not load songs',
        subhead: e.toString(),
      ),
      data: (tracks) {
        if (tracks.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.music_note_outlined,
            headline: 'No music yet',
            subhead: 'Add audio files to your device and refresh.',
          );
        }
        return ListView.builder(
          itemCount: tracks.length,
          itemBuilder: (context, i) => _TrackTile(
            track: tracks[i],
            onTap: () {
              print('NIGHTINGALE TAP: track ${tracks[i].title} at index $i');
              print('NIGHTINGALE TAP: filePath = ${tracks[i].filePath}');
              final notifier = ref.read(playbackProvider.notifier);
              print('NIGHTINGALE TAP: notifier = $notifier');
              notifier.loadAndPlay(tracks, startIndex: i);
            },
          ),
        );
      },
    );
  }
}

class _TrackTile extends StatelessWidget {
  const _TrackTile({required this.track, required this.onTap});
  final TrackModel track;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final duration = _formatDuration(track.duration);
    return Semantics(
      label: '${track.title} by ${track.artist}, $duration',
      button: true,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        title: Text(
          track.title,
          style: textTheme.bodyLarge,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          track.artist,
          style: textTheme.labelMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          duration,
          style: textTheme.labelSmall?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
