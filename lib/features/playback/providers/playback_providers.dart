import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale/core/audio/playback_engine.dart';
import 'package:nightingale/core/audio/playback_state_model.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/core/repositories/activity_repository.dart';
import 'package:nightingale/features/federation/publishing/library_publisher.dart';
import 'package:nightingale/features/library/models/track_model.dart';
import 'package:nightingale/features/recommendations/domain/recommendation_engine_notifier.dart';
import 'package:nightingale/features/social/providers/federated_radio_provider.dart';

class PlaybackNotifier extends AsyncNotifier<PlaybackStateModel> {
  PlaybackEngine? _engine;
  String? _lastBroadcastTrackId;

  // Radio session tracking
  TrackModel? _trackedRadioTrack;
  DateTime? _trackedRadioStartTime;
  bool _isTopUpInFlight = false;

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
    _detectRadioSignal(engineState);
    _maybeTopUpRadioQueue(engineState);
  }

  void _detectRadioSignal(PlaybackStateModel engineState) {
    final radioState = ref.read(federatedRadioProvider).valueOrNull;
    if (radioState == null || !radioState.enabled) {
      _trackedRadioTrack = null;
      _trackedRadioStartTime = null;
      return;
    }

    final currentTrack = engineState.currentTrack;
    if (currentTrack == null) return;

    if (_trackedRadioTrack != null && _trackedRadioTrack!.id != currentTrack.id) {
      final startTime = _trackedRadioStartTime;
      if (startTime != null) {
        final elapsed = DateTime.now().difference(startTime);
        final fingerprint =
            '${_trackedRadioTrack!.artist.toLowerCase().trim()}:${_trackedRadioTrack!.title.toLowerCase().trim()}';
        ref
            .read(recommendationEngineProvider.notifier)
            .rescoreForRadio(
              fingerprint: fingerprint,
              wasSkipped: elapsed.inSeconds < 30,
            )
            .ignore();
      }
    }

    if (_trackedRadioTrack?.id != currentTrack.id) {
      _trackedRadioTrack = currentTrack;
      _trackedRadioStartTime = DateTime.now();
    }
  }

  void _maybeTopUpRadioQueue(PlaybackStateModel engineState) {
    final radioState = ref.read(federatedRadioProvider).valueOrNull;
    if (radioState == null || !radioState.enabled) return;
    if (_isTopUpInFlight) return;

    final remaining = engineState.queue.length - (engineState.currentIndex + 1);
    if (remaining > 5) return;

    _fetchRadioBatch().ignore();
  }

  Future<void> _fetchRadioBatch() async {
    _isTopUpInFlight = true;
    try {
      final radioState = ref.read(federatedRadioProvider).valueOrNull;
      print('NIGHTINGALE RADIO: _fetchRadioBatch — radioEnabled=${radioState?.enabled}');
      if (radioState == null || !radioState.enabled) return;

      var engineState = ref.read(recommendationEngineProvider).valueOrNull;
      if (engineState == null || engineState.results.isEmpty) {
        final seedArtist = radioState.seedArtist;
        print('NIGHTINGALE RADIO: engine empty — calling rescore(force=true, seed=$seedArtist)');
        await ref
            .read(recommendationEngineProvider.notifier)
            .rescore(force: true, seedArtist: seedArtist);
        engineState = ref.read(recommendationEngineProvider).valueOrNull;
        print('NIGHTINGALE RADIO: after rescore — results=${engineState?.results.length ?? 0} coldStart=${engineState?.usedColdStart}');
        if (engineState == null || engineState.results.isEmpty) {
          print('NIGHTINGALE RADIO: no results after rescore — giving up');
          return;
        }
      }

      final playedSet = radioState.playedFingerprints;
      final seedArtist = radioState.seedArtist?.toLowerCase();
      final total = engineState!.results.length;
      final withStreamUrl = engineState.results.where((r) => r.streamUrl != null).length;
      final withHostUrl = engineState.results.where((r) => r.hostNodeUrl != null).length;
      print('NIGHTINGALE RADIO: engine results=$total withStreamUrl=$withStreamUrl withHostUrl=$withHostUrl');

      var candidates = engineState.results
          .where((r) =>
              !playedSet.contains(r.trackFingerprint) &&
              r.streamUrl != null &&
              r.hostNodeUrl != null)
          .toList();

      print('NIGHTINGALE RADIO: candidates after filter=${candidates.length} (played=${playedSet.length})');

      if (seedArtist != null) {
        candidates.sort((a, b) {
          final aIsSeed = a.trackArtist.toLowerCase() == seedArtist;
          final bIsSeed = b.trackArtist.toLowerCase() == seedArtist;
          if (aIsSeed && !bIsSeed) return -1;
          if (!aIsSeed && bIsSeed) return 1;
          return b.score.compareTo(a.score);
        });
      }

      final batch = candidates.take(20).toList();
      print('NIGHTINGALE RADIO: batch size=${batch.length}');
      if (batch.isEmpty) {
        print('NIGHTINGALE RADIO: batch empty — nothing to enqueue');
        return;
      }

      for (final result in batch) {
        final track = TrackModel(
          id: result.trackFingerprint.hashCode,
          filePath: result.streamUrl!,
          title: result.trackTitle,
          artist: result.trackArtist,
          durationMs: 0,
          dateAdded: DateTime.now(),
          sourceActorUrl: result.hostNodeUrl,
          streamUrl: result.streamUrl,
        );
        await _engine!.enqueue(track);
        ref.read(federatedRadioProvider.notifier).markPlayed(result.trackFingerprint);
      }
    } finally {
      _isTopUpInFlight = false;
    }
  }

  /// Called when radio is enabled from the toggle — pre-loads the first batch.
  Future<void> initiateRadio() async {
    _isTopUpInFlight = false;
    await _fetchRadioBatch();
  }

  void _maybeBroadcastNowPlaying(PlaybackStateModel engineState) {
    final track = engineState.currentTrack;
    if (track == null) return;

    final sharingScope = sl<LibraryPublisher>().sharingScope;
    if (sharingScope == SharingScope.private) return;

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
