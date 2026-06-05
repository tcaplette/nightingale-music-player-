import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nightingale/core/router/app_router.dart';
import 'package:nightingale/features/library/models/track_model.dart';
import 'package:nightingale/features/library/providers/library_providers.dart';
import 'package:nightingale/features/library/screens/library_empty_state.dart';
import 'package:nightingale/features/library/widgets/metadata_editor_sheet.dart';
import 'package:nightingale/features/library/widgets/songs_selection_sheet.dart';
import 'package:nightingale/features/library/widgets/track_tile.dart';
import 'package:nightingale/features/playback/providers/playback_providers.dart';
import 'package:nightingale/features/social/providers/federated_radio_provider.dart';
import 'package:nightingale/shared/components/empty_state_widget.dart';
import 'package:nightingale/shared/components/skeleton_loader.dart';

class AllSongsView extends ConsumerWidget {
  const AllSongsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksAsync = ref.watch(allTracksProvider);
    final scanState = ref.watch(libraryScanProvider);
    final isScanning = scanState.status == LibraryScanStatus.scanning;
    final discoveredCountAsync = ref.watch(discoveredTrackCountProvider);
    final discoveredCount = discoveredCountAsync.valueOrNull ?? 0;

    return tracksAsync.when(
      loading: () => const SkeletonListView(count: 10),
      error: (e, _) => EmptyStateWidget(
        icon: Icons.error_outline,
        headline: 'Could not load songs',
        subhead: e.toString(),
      ),
      data: (tracks) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openSelectionSheet(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Songs'),
          ),
          body: tracks.isEmpty
              ? RefreshIndicator(
                  onRefresh: () => ref.read(libraryScanProvider.notifier).scan(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.7,
                      child: LibraryEmptyState(
                        icon: Icons.music_note_outlined,
                        message: 'Your library is empty',
                        isScanning: isScanning,
                        discoveredCount: discoveredCount,
                        onChooseSongs: () => _openSelectionSheet(context),
                      ),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => ref.read(libraryScanProvider.notifier).scan(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 88),
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
                        onLongPress: () => _showTrackMenu(context, ref, track),
                      );
                    },
                  ),
                ),
        );
      },
    );
  }

  void _showTrackMenu(BuildContext context, WidgetRef ref, TrackModel track) {
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
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit Metadata'),
              onTap: () {
                Navigator.of(ctx).pop();
                showMetadataEditorSheet(context, track);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cell_tower),
              title: const Text('Start Radio'),
              onTap: () async {
                Navigator.of(ctx).pop();
                await ref.read(federatedRadioProvider.notifier).startSeeded(track.artist);
                ref.read(playbackProvider.notifier).initiateRadio().ignore();
                if (context.mounted) context.push(AppRoutes.nowPlaying);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openSelectionSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const SongsSelectionSheet(),
    );
  }
}
