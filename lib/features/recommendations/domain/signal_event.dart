enum SignalEventType {
  play,
  skip,
  save,
  like,
  playlistAdd,
  networkListen,
  networkLike;

  static SignalEventType fromString(String s) => switch (s) {
    'play' => play,
    'skip' => skip,
    'save' => save,
    'like' => like,
    'playlist_add' => playlistAdd,
    'network_listen' => networkListen,
    'network_like' => networkLike,
    _ => throw ArgumentError('Unknown signal type: $s'),
  };

  String get value => switch (this) {
    play => 'play',
    skip => 'skip',
    save => 'save',
    like => 'like',
    playlistAdd => 'playlist_add',
    networkListen => 'network_listen',
    networkLike => 'network_like',
  };

  static const Map<SignalEventType, double> defaultWeights = {
    play: 1.0,
    skip: -0.5,
    save: 3.0,
    like: 2.5,
    playlistAdd: 2.0,
    networkListen: 0.5,
    networkLike: 1.5,
  };

  double get defaultWeight => defaultWeights[this] ?? 0.0;
}

class SignalEvent {
  const SignalEvent({
    required this.trackFingerprint,
    required this.eventType,
    this.sourceActorId,
    required this.timestampUtc,
    required this.weight,
  });

  final String trackFingerprint;
  final SignalEventType eventType;
  final String? sourceActorId;
  final DateTime timestampUtc;
  final double weight;
}
