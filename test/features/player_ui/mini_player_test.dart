import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightingale/core/audio/playback_state_model.dart';
import 'package:nightingale/features/library/models/track_model.dart';
import 'package:nightingale/features/playback/providers/playback_providers.dart';
import 'package:nightingale/features/player_ui/mini_player.dart';
import 'package:nightingale/shared/theme/app_theme.dart';

TrackModel _track({String title = 'Song', String artist = 'Artist'}) =>
    TrackModel(
      id: 1,
      title: title,
      artist: artist,
      filePath: '/tmp/test.mp3',
      durationMs: 180000,
      dateAdded: DateTime(2024),
    );

PlaybackStateModel _state({
  List<TrackModel>? queue,
  bool isPlaying = false,
}) {
  final tracks = queue ?? [_track()];
  return PlaybackStateModel(
    status: isPlaying ? PlaybackStatus.playing : PlaybackStatus.paused,
    queue: tracks,
    currentIndex: 0,
    currentTrack: tracks.isNotEmpty ? tracks[0] : null,
    position: Duration.zero,
    duration: const Duration(minutes: 3),
    bufferStatus: BufferStatus.empty,
    shuffleMode: ShuffleMode.off,
    repeatMode: RepeatMode.off,
  );
}

class _StubPlaybackNotifier extends AsyncNotifier<PlaybackStateModel>
    implements PlaybackNotifier {
  _StubPlaybackNotifier(this._fixedState);
  final PlaybackStateModel _fixedState;

  @override
  Future<PlaybackStateModel> build() async => _fixedState;

  @override
  Future<void> play() async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> skipNext() async {}
  @override
  Future<void> skipPrevious() async {}
  @override
  Future<void> seekTo(Duration position) async {}
  @override
  Future<void> loadAndPlay(List<TrackModel> tracks, {int startIndex = 0}) async {}
  @override
  Future<void> enqueue(TrackModel track) async {}
  @override
  Future<void> playNext(TrackModel track) async {}
  @override
  Future<void> removeAt(int index) async {}
  @override
  Future<void> reorder(int from, int to) async {}
  @override
  Future<void> clearAll() async {}
  @override
  Future<void> setShuffleMode(ShuffleMode mode) async {}
  @override
  void setRepeatMode(RepeatMode mode) {}
  @override
  void toggleShuffle() {}
  @override
  void cycleRepeat() {}
}

Widget _wrap(Widget child, {PlaybackStateModel? playbackState}) {
  final stubState = playbackState ?? _state();
  return ProviderScope(
    overrides: [
      playbackProvider.overrideWith(
        () => _StubPlaybackNotifier(stubState),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('MiniPlayer', () {
    testWidgets('renders nothing when queue is empty', (tester) async {
      await tester.pumpWidget(
        _wrap(const MiniPlayer(), playbackState: _state(queue: [])),
      );
      await tester.pump();
      // With empty queue, MiniPlayer returns SizedBox.shrink()
      expect(find.byType(GestureDetector), findsNothing);
    });

    testWidgets('shows track title and artist when playing', (tester) async {
      final track = _track(title: 'Nightingale', artist: 'The Birds');
      await tester.pumpWidget(
        _wrap(const MiniPlayer(),
            playbackState: _state(queue: [track], isPlaying: true)),
      );
      await tester.pump();
      expect(find.text('Nightingale'), findsOneWidget);
      expect(find.text('The Birds'), findsOneWidget);
    });

    testWidgets('play button has accessible Semantics label', (tester) async {
      await tester.pumpWidget(
        _wrap(const MiniPlayer(), playbackState: _state(isPlaying: false)),
      );
      await tester.pump();
      expect(find.bySemanticsLabel('Play'), findsOneWidget);
    });

    testWidgets('pause button has accessible Semantics label when playing',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const MiniPlayer(), playbackState: _state(isPlaying: true)),
      );
      await tester.pump();
      expect(find.bySemanticsLabel('Pause'), findsOneWidget);
    });
  });
}
