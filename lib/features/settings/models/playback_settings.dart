enum BufferPreset {
  efficient,
  normal,
  generous;

  String get label => switch (this) {
        BufferPreset.efficient => 'Efficient',
        BufferPreset.normal => 'Normal',
        BufferPreset.generous => 'Generous',
      };
}

enum SkipThreshold {
  one,
  three,
  five,
  ten;

  String get label => switch (this) {
        SkipThreshold.one => '1 second',
        SkipThreshold.three => '3 seconds',
        SkipThreshold.five => '5 seconds',
        SkipThreshold.ten => '10 seconds',
      };

  Duration get duration => switch (this) {
        SkipThreshold.one => const Duration(seconds: 1),
        SkipThreshold.three => const Duration(seconds: 3),
        SkipThreshold.five => const Duration(seconds: 5),
        SkipThreshold.ten => const Duration(seconds: 10),
      };
}

enum AudioFocusBehaviour {
  duck,
  pause,
  doNothing;

  String get label => switch (this) {
        AudioFocusBehaviour.duck => 'Duck (reduce volume)',
        AudioFocusBehaviour.pause => 'Pause',
        AudioFocusBehaviour.doNothing => 'Do nothing',
      };
}

class PlaybackSettings {
  const PlaybackSettings({
    required this.bufferPreset,
    required this.skipThreshold,
    required this.audioFocusBehaviour,
  });

  final BufferPreset bufferPreset;
  final SkipThreshold skipThreshold;
  final AudioFocusBehaviour audioFocusBehaviour;

  static const defaults = PlaybackSettings(
    bufferPreset: BufferPreset.normal,
    skipThreshold: SkipThreshold.three,
    audioFocusBehaviour: AudioFocusBehaviour.duck,
  );
}
