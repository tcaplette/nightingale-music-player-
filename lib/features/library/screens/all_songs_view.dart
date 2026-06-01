import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale/features/library/providers/library_providers.dart';
import 'package:nightingale/features/library/widgets/metadata_editor_sheet.dart';
import 'package:nightingale/features/library/widgets/track_tile.dart';
import 'package:nightingale/features/playback/providers/playback_providers.dart';
import 'package:nightingale/shared/components/empty_state_widget.dart';
import 'package:nightingale/shared/components/skeleton_loader.dart';

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
          return RefreshIndicator(
            onRefresh: () => ref.read(libraryScanProvider.notifier).scan(),
            child: const EmptyStateWidget(
              icon: Icons.music_note_outlined,
              headline: 'No music yet',
              subhead: 'Add audio files to your device and refresh.',
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.read(libraryScanProvider.notifier).scan(),
          child: ListView.builder(
            itemCount: tracks.length,
            itemBuilder: (context, i) {
              final track = tracks[i];
              return TrackTile(
                track: track,
                onTap: () {
                  ref.read(playbackProvider.notifier).loadAndPlay(
                    tracks,
                    startIndex: i,
                  );
                },
                onLongPress: () => showMetadataEditorSheet(context, track),
              );
            },
          ),
        );
      },
    );
  }
}
