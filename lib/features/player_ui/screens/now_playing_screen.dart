import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nightingale/core/audio/audio_source.dart';
import 'package:nightingale/core/audio/playback_state_model.dart' as ps;
import 'package:nightingale/core/router/app_router.dart';
import 'package:nightingale/features/playback/providers/playback_providers.dart';
import 'package:nightingale/features/social/providers/now_playing_broadcast_provider.dart';
import 'package:nightingale/shared/components/network_state/buffering_widget.dart';
import 'package:nightingale/shared/components/network_state/host_offline_widget.dart';
import 'package:nightingale/shared/theme/app_colors.dart';
import 'package:nightingale/shared/theme/app_motion.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

class NowPlayingScreen extends ConsumerStatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  ConsumerState<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends ConsumerState<NowPlayingScreen> {
  bool _isDraggingScrubber = false;
  double _scrubValue = 0.0;

  @override
  Widget build(BuildContext context) {
    final playbackAsync = ref.watch(playbackProvider);
    final state = playbackAsync.valueOrNull ?? ps.PlaybackStateModel.empty;
    final track = state.currentTrack;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => context.pop(),
        ),
        actions: [
          _NowPlayingBroadcastToggle(),
          IconButton(
            icon: const Icon(Icons.queue_music),
            tooltip: 'Queue',
            onPressed: () => context.push(AppRoutes.queue),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.md),
              // Artwork — large, dominant, animated crossfade on track change
              Expanded(
                child: RepaintBoundary(
                  child: AnimatedSwitcher(
                    duration: AppMotion.standard,
                    switchInCurve: AppMotion.curveStandard,
                    switchOutCurve: AppMotion.curveStandard,
                    child: _ArtworkWidget(
                      key: ValueKey(track?.id),
                      artworkPath: track?.artworkPath,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              // Track info — typographic hierarchy
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track?.title ?? '—',
                          style: textTheme.displayLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          track?.artist ?? '—',
                          style: textTheme.titleMedium?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (track?.albumName != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            track!.albumName!,
                            style: textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.4),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              // Network-state components (Phase 1 primitives)
              _NetworkStateIndicator(state: state),
              // Scrubber
              _Scrubber(
                state: state,
                isDragging: _isDraggingScrubber,
                scrubValue: _scrubValue,
                onDragStart: (v) => setState(() {
                  _isDraggingScrubber = true;
                  _scrubValue = v;
                }),
                onDragUpdate: (v) => setState(() => _scrubValue = v),
                onDragEnd: (v) {
                  setState(() => _isDraggingScrubber = false);
                  final duration = state.duration;
                  final pos = Duration(
                    milliseconds: (v * duration.inMilliseconds).round(),
                  );
                  ref.read(playbackProvider.notifier).seekTo(pos);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              // Transport controls
              _TransportControls(state: state),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArtworkWidget extends StatelessWidget {
  const _ArtworkWidget({super.key, required this.artworkPath});
  final String? artworkPath;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (artworkPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          artworkPath!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(scheme),
        ),
      );
    }
    return _placeholder(scheme);
  }

  Widget _placeholder(ColorScheme scheme) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.music_note,
          size: 80,
          color: scheme.onSurface.withValues(alpha: 0.15),
        ),
      ),
    );
  }
}

class _NetworkStateIndicator extends StatelessWidget {
  const _NetworkStateIndicator({required this.state});
  final ps.PlaybackStateModel state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Phase 4: Stream status indicators
    if (state.status == ps.PlaybackStatus.loading) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: const BufferingWidget(statusLabel: 'Buffering…'),
      );
    }

    // Remote stream indicators
    if (state.streamSourceType is RemoteAudioSource) {
      final remoteSource = state.streamSourceType as RemoteAudioSource;

      // Host offline
      if (state.status == ps.PlaybackStatus.error) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: const HostOfflineWidget(displayName: 'Remote node'),
        );
      }

      // Show remote indicator with buffer health
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud, size: 14, color: scheme.primary),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Remote • ${_bufferLabel(state.bufferStatus)}',
              style: TextStyle(
                fontSize: 11,
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    // Cached indicator
    if (state.streamSourceType is LocalAudioSource &&
        state.currentTrack?.sourceActorUrl != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.offline_bolt, size: 14, color: Colors.green),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Cached',
              style: TextStyle(
                fontSize: 11,
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  String _bufferLabel(ps.BufferStatus? status) {
    if (status == null) return '—';
    return switch (status.health) {
      ps.BufferHealth.healthy => 'Healthy',
      ps.BufferHealth.low => 'Fair',
      ps.BufferHealth.empty => 'Buffering',
    };
  }
}

class _Scrubber extends StatelessWidget {
  const _Scrubber({
    required this.state,
    required this.isDragging,
    required this.scrubValue,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final ps.PlaybackStateModel state;
  final bool isDragging;
  final double scrubValue;
  final ValueChanged<double> onDragStart;
  final ValueChanged<double> onDragUpdate;
  final ValueChanged<double> onDragEnd;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final totalMs = state.duration.inMilliseconds;
    final posMs = state.position.inMilliseconds;
    final progress = totalMs > 0
        ? (isDragging ? scrubValue : posMs / totalMs).clamp(0.0, 1.0)
        : 0.0;

    final displayPos = isDragging
        ? Duration(milliseconds: (scrubValue * totalMs).round())
        : state.position;

    return Column(
      children: [
        Semantics(
          label: 'Seek bar. Current position: ${_formatDuration(displayPos)}',
          slider: true,
          child: Slider(
            value: progress,
            onChangeStart: onDragStart,
            onChanged: onDragUpdate,
            onChangeEnd: onDragEnd,
            activeColor: scheme.primary,
            inactiveColor: scheme.onSurface.withValues(alpha: 0.15),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(displayPos), style: textTheme.labelSmall),
              Text(_formatDuration(state.duration), style: textTheme.labelSmall),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _TransportControls extends ConsumerWidget {
  const _TransportControls({required this.state});
  final ps.PlaybackStateModel state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final notifier = ref.read(playbackProvider.notifier);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Shuffle
        Semantics(
          label: state.shuffleMode == ps.ShuffleMode.on
              ? 'Shuffle: on'
              : 'Shuffle: off',
          button: true,
          child: IconButton(
            icon: Icon(
              Icons.shuffle,
              color: state.shuffleMode == ps.ShuffleMode.on
                  ? scheme.primary
                  : scheme.onSurface.withValues(alpha: 0.4),
            ),
            onPressed: () => notifier.toggleShuffle(),
          ),
        ),
        // Previous
        Semantics(
          label: 'Previous track',
          button: true,
          child: IconButton(
            iconSize: 36,
            icon: Icon(Icons.skip_previous, color: scheme.onSurface),
            onPressed: () => notifier.skipPrevious(),
          ),
        ),
        // Play/Pause
        Semantics(
          label: state.isPlaying ? 'Pause' : 'Play',
          button: true,
          child: Container(
            decoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              iconSize: 40,
              icon: Icon(
                state.isPlaying ? Icons.pause : Icons.play_arrow,
                color: scheme.onPrimary,
              ),
              onPressed: () {
                if (state.isPlaying) {
                  notifier.pause();
                } else {
                  notifier.play();
                }
              },
            ),
          ),
        ),
        // Next
        Semantics(
          label: 'Next track',
          button: true,
          child: IconButton(
            iconSize: 36,
            icon: Icon(Icons.skip_next, color: scheme.onSurface),
            onPressed: () => notifier.skipNext(),
          ),
        ),
        // Repeat
        Semantics(
          label: switch (state.repeatMode) {
            ps.RepeatMode.off => 'Repeat: off',
            ps.RepeatMode.one => 'Repeat: one',
            ps.RepeatMode.all => 'Repeat: all',
          },
          button: true,
          child: IconButton(
            icon: Icon(
              state.repeatMode == ps.RepeatMode.one
                  ? Icons.repeat_one
                  : Icons.repeat,
              color: state.repeatMode != ps.RepeatMode.off
                  ? scheme.primary
                  : scheme.onSurface.withValues(alpha: 0.4),
            ),
            onPressed: () => notifier.cycleRepeat(),
          ),
        ),
      ],
    );
  }
}

/// Now Playing broadcast toggle — shown in the app bar of the Now Playing screen.
/// Defaults to off each session; tapping toggles the session-scoped flag.
class _NowPlayingBroadcastToggle extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOn = ref.watch(nowPlayingBroadcastProvider);
    return IconButton(
      icon: Icon(
        isOn ? Icons.broadcast_on_personal : Icons.broadcast_on_personal_outlined,
        color: isOn ? AppColors.accent : null,
      ),
      tooltip: isOn ? 'Broadcasting Now Playing — tap to stop' : 'Share Now Playing',
      onPressed: () =>
          ref.read(nowPlayingBroadcastProvider.notifier).toggle(),
    );
  }
}
