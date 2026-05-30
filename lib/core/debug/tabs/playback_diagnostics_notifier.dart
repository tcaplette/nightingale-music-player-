import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale/core/audio/playback_state_model.dart';
import 'package:nightingale/features/library/models/track_model.dart';

class PlaybackDiagnosticsState {
  const PlaybackDiagnosticsState({
    required this.status,
    required this.queue,
    required this.currentIndex,
    required this.position,
    required this.duration,
    required this.bufferStatus,
    required this.shuffleMode,
    required this.repeatMode,
    this.streamSourceDescription,
    this.audioFormat,
  });

  final PlaybackStatus status;
  final List<TrackModel> queue;
  final int currentIndex;
  final Duration position;
  final Duration duration;
  final BufferStatus bufferStatus;
  final ShuffleMode shuffleMode;
  final RepeatMode repeatMode;
  final String? streamSourceDescription;
  final String? audioFormat;

  static const empty = PlaybackDiagnosticsState(
    status: PlaybackStatus.stopped,
    queue: [],
    currentIndex: -1,
    position: Duration.zero,
    duration: Duration.zero,
    bufferStatus: BufferStatus.empty,
    shuffleMode: ShuffleMode.off,
    repeatMode: RepeatMode.off,
  );
}

// Gate at compile time — this provider is never registered in release builds.
// Registration is conditional on kDebugMode in debug_overlay_tabs.dart.
final playbackDiagnosticsProvider =
    StateProvider<PlaybackDiagnosticsState>((_) {
      assert(kDebugMode, 'playbackDiagnosticsProvider must only be used in debug builds');
      return PlaybackDiagnosticsState.empty;
    });
