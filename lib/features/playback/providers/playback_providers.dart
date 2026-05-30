import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale/core/audio/playback_engine.dart';
import 'package:nightingale/core/audio/playback_state_model.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/core/repositories/activity_repository.dart';
import 'package:nightingale/features/library/models/track_model.dart';
import 'package:nightingale/features/social/providers/now_playing_broadcast_provider.dart';

class PlaybackNotifier extends AsyncNotifier<PlaybackStateModel> {
  PlaybackEngine? _engine;
  String? _lastBroadcastTrackId;

  @override
  Future<PlaybackStateModel> build() async {
    _engine = sl<PlaybackEngine>();
    // Mirror the engine's ValueNotifier into Riverpod state so widgets rebuild
    _engine!.state.addListener(_onEngineState);
    ref.onDispose(() {
      _engine?.state.removeListener(_onEngineState);
    });
    return _engine!.state.value;
  }

  void _onEngineState() {
    if (_engine == null) return;
    final engineState = _engine!.state.value;
    state = AsyncData(engineState);
    _maybeBroadcastNowPlaying(engineState);
  }

  void _maybeBroadcastNowPlaying(PlaybackStateModel engineState) {
    final track = engineState.currentTrack;
    if (track == null) return;

    final broadcastOn = ref.read(nowPlayingBroadcastProvider);
    if (!broadcastOn) return;

    final trackId = track.id.toString();
    if (trackId == _lastBroadcastTrackId) return; // already emitted for this track
    _lastBroadcastTrackId = trackId;

    // Fire-and-forget — delivery failure is handled by the federation layer
    sl<ActivityRepository>().emitNowPlaying(
      trackId: trackId,
      trackTitle: track.title,
      trackArtist: track.artist,
      hostingNodeUrl: '',
    ).ignore();
  }

  // ── Transport ──────────────────────────────────────────────────────────────

  Future<void> loadAndPlay(List<TrackModel> tracks, {int startIndex = 0}) =>
      _engine!.loadAndPlay(tracks, startIndex: startIndex);

  Future<void> play() => _engine!.play();
  Future<void> pause() => _engine!.pause();
  Future<void> stop() => _engine!.stop();
  Future<void> skipNext() => _engine!.skipNext();
  Future<void> skipPrevious() => _engine!.skipPrevious();
  Future<void> seekTo(Duration position) => _engine!.seekTo(position);

  // ── Queue ──────────────────────────────────────────────────────────────────

  Future<void> enqueue(TrackModel track) => _engine!.enqueue(track);
  Future<void> playNext(TrackModel track) => _engine!.playNext(track);
  Future<void> removeAt(int index) => _engine!.removeAt(index);
  Future<void> reorder(int from, int to) => _engine!.reorder(from, to);
  Future<void> clearAll() => _engine!.clearAll();

  // ── Modes ──────────────────────────────────────────────────────────────────

  Future<void> setShuffleMode(ShuffleMode mode) =>
      _engine!.setShuffleMode(mode);
  void setRepeatMode(RepeatMode mode) => _engine!.setRepeatMode(mode);

  void toggleShuffle() {
    final current = _engine!.state.value.shuffleMode;
    setShuffleMode(
      current == ShuffleMode.off ? ShuffleMode.on : ShuffleMode.off,
    );
  }

  void cycleRepeat() {
    final current = _engine!.state.value.repeatMode;
    setRepeatMode(switch (current) {
      RepeatMode.off => RepeatMode.all,
      RepeatMode.all => RepeatMode.one,
      RepeatMode.one => RepeatMode.off,
    });
  }
}

final playbackProvider =
    AsyncNotifierProvider<PlaybackNotifier, PlaybackStateModel>(
      PlaybackNotifier.new,
    );
