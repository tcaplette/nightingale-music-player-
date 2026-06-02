import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Session-scoped Now Playing broadcast toggle.
/// Defaults to on (opt-out) on every app launch.
class NowPlayingBroadcastNotifier extends StateNotifier<bool> {
  NowPlayingBroadcastNotifier() : super(true);

  void enable() => state = true;
  void disable() => state = false;
  void toggle() => state = !state;
}

final nowPlayingBroadcastProvider =
    StateNotifierProvider<NowPlayingBroadcastNotifier, bool>(
  (ref) => NowPlayingBroadcastNotifier(),
);
