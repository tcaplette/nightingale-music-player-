import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Session-scoped Now Playing broadcast toggle.
/// Defaults to off on every app launch per spec.
class NowPlayingBroadcastNotifier extends StateNotifier<bool> {
  NowPlayingBroadcastNotifier() : super(false);

  void enable() => state = true;
  void disable() => state = false;
  void toggle() => state = !state;
}

final nowPlayingBroadcastProvider =
    StateNotifierProvider<NowPlayingBroadcastNotifier, bool>(
  (ref) => NowPlayingBroadcastNotifier(),
);
