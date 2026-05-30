import 'dart:async';

import 'package:nightingale/core/audio/playback_engine.dart';
import 'package:nightingale/core/audio/playback_state_model.dart';
import 'package:nightingale/core/logging/app_logger.dart';
import 'package:nightingale/features/library/models/track_model.dart';
import 'package:nightingale/features/recommendations/data/signal_repository.dart';
import 'package:nightingale/features/recommendations/domain/signal_event.dart';

const _kPlayThresholdSeconds = 30;
const _tag = 'signal_capturer';

/// Listens to playback state and emits play/skip signal events.
/// A track is "played" when it crosses 30 seconds of continuous playback.
/// A track is "skipped" when it changes before the 30-second threshold.
class PlaybackSignalCapturer {
  PlaybackSignalCapturer({
    required PlaybackEngine engine,
    required SignalRepository signals,
  })  : _engine = engine,
        _signals = signals;

  final PlaybackEngine _engine;
  final SignalRepository _signals;

  TrackModel? _currentTrack;
  bool _playEmitted = false;
  DateTime? _trackStartedAt;

  void start() {
    _engine.state.addListener(_onState);
    AppLogger.debug('PlaybackSignalCapturer started', tag: _tag);
  }

  void stop() {
    _engine.state.removeListener(_onState);
  }

  void _onState() {
    final state = _engine.state.value;
    final track = state.currentTrack;

    if (track == null) {
      _reset();
      return;
    }

    // Track changed
    if (_currentTrack?.id != track.id) {
      _maybeEmitSkipForPrevious(state.position);
      _currentTrack = track;
      _playEmitted = false;
      _trackStartedAt = DateTime.now();
      return;
    }

    // Same track — check 30-second threshold
    if (!_playEmitted && state.status == PlaybackStatus.playing) {
      final elapsed = state.position.inSeconds;
      if (elapsed >= _kPlayThresholdSeconds) {
        _playEmitted = true;
        _emitPlay(track);
      }
    }
  }

  void _maybeEmitSkipForPrevious(Duration positionAtChange) {
    final prev = _currentTrack;
    if (prev == null) return;
    if (_playEmitted) return;
    if (positionAtChange.inSeconds < _kPlayThresholdSeconds) {
      _emitSkip(prev);
    }
  }

  void _emitPlay(TrackModel track) {
    final fingerprint = _fingerprintFor(track);
    _signals
        .recordEvent(SignalEvent(
          trackFingerprint: fingerprint,
          eventType: SignalEventType.play,
          timestampUtc: DateTime.now().toUtc(),
          weight: SignalEventType.play.defaultWeight,
        ))
        .ignore();
    AppLogger.debug('Signal: play → $fingerprint', tag: _tag);
  }

  void _emitSkip(TrackModel track) {
    final fingerprint = _fingerprintFor(track);
    _signals
        .recordEvent(SignalEvent(
          trackFingerprint: fingerprint,
          eventType: SignalEventType.skip,
          timestampUtc: DateTime.now().toUtc(),
          weight: SignalEventType.skip.defaultWeight,
        ))
        .ignore();
    AppLogger.debug('Signal: skip → $fingerprint', tag: _tag);
  }

  void _reset() {
    _currentTrack = null;
    _playEmitted = false;
    _trackStartedAt = null;
  }

  // Public helpers called from UI actions

  void recordSave(String fingerprint) {
    _signals
        .recordEvent(SignalEvent(
          trackFingerprint: fingerprint,
          eventType: SignalEventType.save,
          timestampUtc: DateTime.now().toUtc(),
          weight: SignalEventType.save.defaultWeight,
        ))
        .ignore();
    AppLogger.debug('Signal: save → $fingerprint', tag: _tag);
  }

  void recordLike(String fingerprint) {
    _signals
        .recordEvent(SignalEvent(
          trackFingerprint: fingerprint,
          eventType: SignalEventType.like,
          timestampUtc: DateTime.now().toUtc(),
          weight: SignalEventType.like.defaultWeight,
        ))
        .ignore();
    AppLogger.debug('Signal: like → $fingerprint', tag: _tag);
  }

  void recordPlaylistAdd(String fingerprint) {
    _signals
        .recordEvent(SignalEvent(
          trackFingerprint: fingerprint,
          eventType: SignalEventType.playlistAdd,
          timestampUtc: DateTime.now().toUtc(),
          weight: SignalEventType.playlistAdd.defaultWeight,
        ))
        .ignore();
    AppLogger.debug('Signal: playlist_add → $fingerprint', tag: _tag);
  }

  // Use chromaprintHash if available, otherwise normalised "artist:title"
  static String _fingerprintFor(TrackModel track) =>
      '${track.artist.toLowerCase().trim()}:${track.title.toLowerCase().trim()}';
}
