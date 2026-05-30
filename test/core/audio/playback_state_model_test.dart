import 'package:flutter_test/flutter_test.dart';
import 'package:nightingale/core/audio/playback_state_model.dart';
import 'package:nightingale/features/library/models/track_model.dart';

TrackModel _track(int id) => TrackModel(
  id: id,
  filePath: '/music/track_$id.mp3',
  title: 'Track $id',
  artist: 'Artist',
  durationMs: 180000,
  dateAdded: DateTime(2024),
);

void main() {
  group('PlaybackStateModel queue logic (via copyWith)', () {
    test('empty state has no current track', () {
      expect(PlaybackStateModel.empty.currentTrack, isNull);
      expect(PlaybackStateModel.empty.hasQueue, isFalse);
    });

    test('hasQueue is true when tracks are present', () {
      final state = PlaybackStateModel.empty.copyWith(
        queue: [_track(1), _track(2)],
        currentIndex: 0,
        currentTrack: _track(1),
        status: PlaybackStatus.playing,
      );
      expect(state.hasQueue, isTrue);
      expect(state.isPlaying, isTrue);
    });

    test('copyWith status only changes status', () {
      final state = PlaybackStateModel.empty.copyWith(
        queue: [_track(1)],
        currentIndex: 0,
        currentTrack: _track(1),
        status: PlaybackStatus.playing,
      );
      final paused = state.copyWith(status: PlaybackStatus.paused);
      expect(paused.status, PlaybackStatus.paused);
      expect(paused.currentTrack, state.currentTrack);
      expect(paused.queue, state.queue);
    });

    test('shuffle and repeat modes default to off', () {
      expect(PlaybackStateModel.empty.shuffleMode, ShuffleMode.off);
      expect(PlaybackStateModel.empty.repeatMode, RepeatMode.off);
    });

    test('buffer health transitions', () {
      expect(
        BufferStatus.healthFor(const Duration(seconds: 0)),
        BufferHealth.empty,
      );
      expect(
        BufferStatus.healthFor(const Duration(seconds: 3)),
        BufferHealth.low,
      );
      expect(
        BufferStatus.healthFor(const Duration(seconds: 15)),
        BufferHealth.healthy,
      );
    });
  });
}
