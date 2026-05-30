import 'package:nightingale/core/audio/audio_source.dart';
import 'package:nightingale/features/library/models/track_model.dart';

enum PlaybackStatus { stopped, playing, paused, loading, error }

enum ShuffleMode { off, on }

enum RepeatMode { off, one, all }

enum BufferHealth { healthy, low, empty }

class BufferStatus {
  const BufferStatus({
    required this.bufferedDuration,
    required this.health,
  });

  final Duration bufferedDuration;
  final BufferHealth health;

  static const empty = BufferStatus(
    bufferedDuration: Duration.zero,
    health: BufferHealth.empty,
  );

  static BufferHealth healthFor(Duration buffered) {
    if (buffered >= const Duration(seconds: 10)) return BufferHealth.healthy;
    if (buffered >= const Duration(seconds: 2)) return BufferHealth.low;
    return BufferHealth.empty;
  }
}

class PlaybackStateModel {
  const PlaybackStateModel({
    required this.status,
    this.currentTrack,
    required this.queue,
    required this.currentIndex,
    required this.position,
    required this.duration,
    required this.bufferStatus,
    required this.shuffleMode,
    required this.repeatMode,
    this.streamSourceType,
  });

  final PlaybackStatus status;
  final TrackModel? currentTrack;
  final List<TrackModel> queue;
  final int currentIndex;
  final Duration position;
  final Duration duration;
  final BufferStatus bufferStatus;
  final ShuffleMode shuffleMode;
  final RepeatMode repeatMode;
  final AudioSource? streamSourceType;

  bool get isPlaying => status == PlaybackStatus.playing;
  bool get hasQueue => queue.isNotEmpty;

  static const empty = PlaybackStateModel(
    status: PlaybackStatus.stopped,
    queue: [],
    currentIndex: -1,
    position: Duration.zero,
    duration: Duration.zero,
    bufferStatus: BufferStatus.empty,
    shuffleMode: ShuffleMode.off,
    repeatMode: RepeatMode.off,
  );

  PlaybackStateModel copyWith({
    PlaybackStatus? status,
    TrackModel? currentTrack,
    List<TrackModel>? queue,
    int? currentIndex,
    Duration? position,
    Duration? duration,
    BufferStatus? bufferStatus,
    ShuffleMode? shuffleMode,
    RepeatMode? repeatMode,
    AudioSource? streamSourceType,
  }) {
    return PlaybackStateModel(
      status: status ?? this.status,
      currentTrack: currentTrack ?? this.currentTrack,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      bufferStatus: bufferStatus ?? this.bufferStatus,
      shuffleMode: shuffleMode ?? this.shuffleMode,
      repeatMode: repeatMode ?? this.repeatMode,
      streamSourceType: streamSourceType ?? this.streamSourceType,
    );
  }
}
