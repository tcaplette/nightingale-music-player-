import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:just_audio_background/just_audio_background.dart';
import 'package:nightingale/core/audio/audio_source.dart' as ng;
import 'package:nightingale/core/audio/playback_state_model.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/core/logging/app_logger.dart';
import 'package:nightingale/features/federation/streaming/chunk_cache_manager.dart';
import 'package:nightingale/features/federation/streaming/chunk_manifest.dart';
import 'package:nightingale/features/federation/streaming/chunk_stream_assembler.dart';
import 'package:nightingale/features/library/models/track_model.dart';
import 'package:nightingale/features/settings/models/playback_settings.dart';
import 'package:nightingale/shared/services/haptic_service.dart';

const _tag = 'playback';

class PlaybackEngine {
  PlaybackEngine._(PlaybackSettings settings)
      : _settings = settings,
        _audioFocusBehaviour = settings.audioFocusBehaviour;

  late final ja.AudioPlayer _player;
  late final ja.ConcatenatingAudioSource _playlist;
  final PlaybackSettings _settings;

  List<TrackModel> _queue = [];
  List<TrackModel> _originalQueue = [];
  int _currentIndex = -1;
  ShuffleMode _shuffleMode = ShuffleMode.off;
  RepeatMode _repeatMode = RepeatMode.off;

  AudioFocusBehaviour _audioFocusBehaviour;

  final ValueNotifier<PlaybackStateModel> state = ValueNotifier(
    PlaybackStateModel.empty,
  );

  static Future<PlaybackEngine> create({
    PlaybackSettings settings = PlaybackSettings.defaults,
  }) async {
    final engine = PlaybackEngine._(settings);
    await engine._init();
    return engine;
  }

  void setAudioFocusBehaviour(AudioFocusBehaviour behaviour) {
    _audioFocusBehaviour = behaviour;
  }

  void setSkipThreshold(SkipThreshold threshold) {
    _skipThreshold = threshold.duration;
  }

  Duration _skipThreshold = const Duration(seconds: 3);

  Future<void> _init() async {
    _skipThreshold = _settings.skipThreshold.duration;
    _audioFocusBehaviour = _settings.audioFocusBehaviour;

    final bufferConfig = _bufferConfig(_settings.bufferPreset);
    _player = ja.AudioPlayer(
      audioLoadConfiguration: ja.AudioLoadConfiguration(
        androidLoadControl: bufferConfig,
      ),
    );
    _playlist = ja.ConcatenatingAudioSource(children: []);

    // Configure audio session for music
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    // Audio focus callbacks driven by user preference
    session.interruptionEventStream.listen((event) {
      if (_audioFocusBehaviour == AudioFocusBehaviour.doNothing) return;
      if (event.begin) {
        if (event.type == AudioInterruptionType.duck &&
            _audioFocusBehaviour == AudioFocusBehaviour.duck) {
          _player.setVolume(0.5);
        } else if (_audioFocusBehaviour == AudioFocusBehaviour.pause) {
          _player.pause();
        }
      } else {
        if (event.type == AudioInterruptionType.duck &&
            _audioFocusBehaviour == AudioFocusBehaviour.duck) {
          _player.setVolume(1.0);
        } else if (event.type == AudioInterruptionType.pause &&
            _audioFocusBehaviour == AudioFocusBehaviour.pause) {
          _player.play();
        }
      }
    });

    // Forward position and buffer updates to state
    _player.positionStream.listen((pos) => _emitState());
    _player.bufferedPositionStream.listen((_) => _emitState());
    _player.playerStateStream.listen((ps) {
      AppLogger.debug(
        'Player state: ${ps.processingState} playing=${ps.playing}',
        tag: _tag,
      );
      _emitState();
      // Auto-advance at natural end (gapless via ConcatenatingAudioSource handles this,
      // but we update our index tracker when the player advances)
    });
    _player.currentIndexStream.listen((index) {
      if (index != null && index != _currentIndex) {
        _currentIndex = index;
        _emitState();
      }
    });
  }

  // ── Load & Play ────────────────────────────────────────────────────────────

  Future<void> loadAndPlay(
    List<TrackModel> tracks, {
    int startIndex = 0,
  }) async {
    print('NIGHTINGALE PLAYBACK: loadAndPlay called: ${tracks.length} tracks, startIndex=$startIndex');
    if (tracks.isEmpty) {
      print('NIGHTINGALE PLAYBACK: empty track list');
      return;
    }

    _queue = List.from(tracks);
    _originalQueue = List.from(tracks);
    _currentIndex = startIndex;

    await _playlist.clear();

    if (_shuffleMode == ShuffleMode.on) {
      _applyShuffleAroundIndex(startIndex);
    }

    final sources = await Future.wait(_queue.map(_resolveSourceAsync));
    print('NIGHTINGALE PLAYBACK: resolved ${sources.length} sources');
    for (var i = 0; i < sources.length && i < 3; i++) {
      print('NIGHTINGALE PLAYBACK:   source[$i]: ${sources[i]}');
    }

    await _playlist.addAll(sources);

    try {
      print('NIGHTINGALE PLAYBACK: setting audio source...');
      await _player.setAudioSource(_playlist, initialIndex: startIndex);
      print('NIGHTINGALE PLAYBACK: audio source set, calling play()');
      await _player.play();
      HapticService.trackStart();
      print('NIGHTINGALE PLAYBACK: play() called successfully');
    } catch (e, st) {
      print('NIGHTINGALE PLAYBACK ERROR: $e');
      print('NIGHTINGALE PLAYBACK STACK: $st');
      _emitState(error: true);
    }
  }

  // ── Transport controls ─────────────────────────────────────────────────────

  Future<void> play() async {
    await _player.play();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> stop() async {
    await _player.stop();
    _queue = [];
    _originalQueue = [];
    _currentIndex = -1;
    _emitState();
  }

  Future<void> skipNext() async {
    if (_currentIndex >= _queue.length - 1) {
      if (_repeatMode == RepeatMode.all) {
        await _player.seek(Duration.zero, index: 0);
        _currentIndex = 0;
      }
      // repeat-off: stop at end; do nothing
      return;
    }
    await _player.seekToNext();
  }

  Future<void> skipPrevious() async {
    if (_player.position > _skipThreshold) {
      await _player.seek(Duration.zero);
      return;
    }
    await _player.seekToPrevious();
  }

  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  // ── Queue operations ────────────────────────────────────────────────────────

  Future<void> enqueue(TrackModel track) async {
    _queue.add(track);
    _originalQueue.add(track);
    await _playlist.add(await _resolveSourceAsync(track));
    _emitState();
  }

  Future<void> playNext(TrackModel track) async {
    final insertAt = _currentIndex + 1;
    _queue.insert(insertAt, track);
    _originalQueue.add(track);
    await _playlist.insert(insertAt, await _resolveSourceAsync(track));
    _emitState();
  }

  Future<void> removeAt(int index) async {
    if (index < 0 || index >= _queue.length) return;
    final removingCurrent = index == _currentIndex;
    _queue.removeAt(index);
    await _playlist.removeAt(index);
    if (removingCurrent) {
      // just_audio advances automatically when the current source is removed
      if (_currentIndex >= _queue.length) {
        _currentIndex = _queue.length - 1;
      }
    } else if (index < _currentIndex) {
      _currentIndex--;
    }
    _emitState();
  }

  Future<void> reorder(int from, int to) async {
    if (from == to) return;
    final track = _queue.removeAt(from);
    _queue.insert(to, track);
    await _playlist.move(from, to);
    // Adjust current index
    if (from == _currentIndex) {
      _currentIndex = to;
    } else if (from < _currentIndex && to >= _currentIndex) {
      _currentIndex--;
    } else if (from > _currentIndex && to <= _currentIndex) {
      _currentIndex++;
    }
    _emitState();
  }

  Future<void> clearAll() async {
    await _player.stop();
    await _playlist.clear();
    _queue = [];
    _originalQueue = [];
    _currentIndex = -1;
    _emitState();
  }

  // ── Shuffle & repeat ───────────────────────────────────────────────────────

  Future<void> setShuffleMode(ShuffleMode mode) async {
    _shuffleMode = mode;
    if (mode == ShuffleMode.on) {
      _applyShuffleAroundIndex(_currentIndex);
    } else {
      // Restore original order; keep current track current
      final currentTrack = _currentIndex >= 0 ? _queue[_currentIndex] : null;
      _queue = List.from(_originalQueue);
      _currentIndex = currentTrack != null
          ? _queue.indexWhere((t) => t.id == currentTrack.id)
          : 0;
      await _playlist.clear();
      await _playlist.addAll(_queue.map(_resolveSource).toList());
      if (_currentIndex >= 0) {
        await _player.seek(Duration.zero, index: _currentIndex);
      }
    }
    _emitState();
  }

  void setRepeatMode(RepeatMode mode) {
    _repeatMode = mode;
    _player.setLoopMode(switch (mode) {
      RepeatMode.off => ja.LoopMode.off,
      RepeatMode.one => ja.LoopMode.one,
      RepeatMode.all => ja.LoopMode.all,
    });
    _emitState();
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  ja.AudioSource _resolveSource(TrackModel track) {
    final mediaItem = MediaItem(
      id: track.filePath,
      title: track.title,
      artist: track.artist,
      duration: track.duration,
    );

    // Phase 4: remote tracks — chunk path handled by _resolveSourceAsync
    if (track.isRemote) {
      final uri = track.streamUrl != null
          ? Uri.parse(track.streamUrl!)
          : Uri.parse(track.filePath);
      return ja.AudioSource.uri(uri, tag: mediaItem);
    }

    // Local tracks
    final ng.AudioSource source = ng.LocalAudioSource(track.filePath);
    return switch (source) {
      ng.LocalAudioSource(:final filePath) =>
        ja.AudioSource.uri(Uri.file(filePath), tag: mediaItem),
      ng.RemoteAudioSource(:final uri) =>
        ja.AudioSource.uri(uri, tag: mediaItem),
    };
  }

  /// Async version of [_resolveSource] — checks for a chunk manifest for
  /// remote tracks before falling back to a URI source.
  Future<ja.AudioSource> _resolveSourceAsync(TrackModel track) async {
    if (track.isRemote) {
      final chunkSource = await _tryChunkSource(track);
      if (chunkSource != null) return chunkSource;
    }
    return _resolveSource(track);
  }

  /// Returns a [ChunkStreamAssembler] source if the track has a cached manifest,
  /// otherwise null (falls through to URI-based streaming).
  Future<ja.AudioSource?> _tryChunkSource(TrackModel track) async {
    try {
      final manifests = sl<ChunkManifestRepository>();
      final chunkCache = sl<ChunkCacheManager>();
      final trackId = track.id;

      final manifest =
          await manifests.getManifest(trackId, track.sourceActorUrl ?? '');
      if (manifest == null) return null;

      final mediaItem = MediaItem(
        id: track.filePath,
        title: track.title,
        artist: track.artist,
        duration: track.duration,
      );

      return ChunkStreamAssembler(
        manifest: manifest,
        cache: chunkCache,
        onMissingChunk: (_) async => null,
        tag: mediaItem,
      );
    } catch (_) {
      return null;
    }
  }

  void _applyShuffleAroundIndex(int pivotIndex) {
    if (_queue.isEmpty) return;
    final current = pivotIndex >= 0 ? _queue[pivotIndex] : null;
    _queue.shuffle();
    if (current != null) {
      _queue.remove(current);
      _queue.insert(0, current);
      _currentIndex = 0;
    }
  }

  void _emitState({bool error = false}) {
    final ps = _player.playerState;
    final status = error
        ? PlaybackStatus.error
        : ps.playing
        ? PlaybackStatus.playing
        : ps.processingState == ja.ProcessingState.loading ||
                ps.processingState == ja.ProcessingState.buffering
        ? PlaybackStatus.loading
        : PlaybackStatus.paused;

    final buffered = _player.bufferedPosition;
    final pos = _player.position;
    final dur = _player.duration ?? Duration.zero;

    final currentTrack =
        (_currentIndex >= 0 && _currentIndex < _queue.length)
        ? _queue[_currentIndex]
        : null;

    final streamSource = currentTrack != null
        ? (currentTrack.isRemote
            ? ng.RemoteAudioSource(
                Uri.parse(currentTrack.streamUrl ?? currentTrack.filePath))
            : ng.LocalAudioSource(currentTrack.filePath))
        : null;

    state.value = PlaybackStateModel(
      status: status,
      currentTrack: currentTrack,
      queue: List.unmodifiable(_queue),
      currentIndex: _currentIndex,
      position: pos,
      duration: dur,
      bufferStatus: BufferStatus(
        bufferedDuration: buffered,
        health: BufferStatus.healthFor(buffered),
      ),
      shuffleMode: _shuffleMode,
      repeatMode: _repeatMode,
      streamSourceType: streamSource,
    );
  }

  static ja.AndroidLoadControl _bufferConfig(BufferPreset preset) {
    return switch (preset) {
      BufferPreset.efficient => const ja.AndroidLoadControl(
          minBufferDuration: Duration(seconds: 10),
          maxBufferDuration: Duration(seconds: 60),
          bufferForPlaybackDuration: Duration(seconds: 3),
          bufferForPlaybackAfterRebufferDuration: Duration(seconds: 5),
        ),
      BufferPreset.normal => const ja.AndroidLoadControl(
          minBufferDuration: Duration(seconds: 15),
          maxBufferDuration: Duration(seconds: 120),
          bufferForPlaybackDuration: Duration(seconds: 5),
          bufferForPlaybackAfterRebufferDuration: Duration(seconds: 8),
        ),
      BufferPreset.generous => const ja.AndroidLoadControl(
          minBufferDuration: Duration(seconds: 30),
          maxBufferDuration: Duration(seconds: 240),
          bufferForPlaybackDuration: Duration(seconds: 8),
          bufferForPlaybackAfterRebufferDuration: Duration(seconds: 12),
        ),
    };
  }

  Future<void> dispose() async {
    await _player.dispose();
    state.dispose();
  }
}
