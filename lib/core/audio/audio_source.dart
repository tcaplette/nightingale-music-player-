// Phase 4: remote streaming extends this — RemoteAudioSource is intentionally
// present here even though Phase 2 UI never produces it. It establishes the
// sealed type contract that the PlaybackEngine must honour so Phase 4 can slot
// in without a rewrite.
sealed class AudioSource {
  const AudioSource();
}

final class LocalAudioSource extends AudioSource {
  const LocalAudioSource(this.filePath);
  final String filePath;

  @override
  bool operator ==(Object other) =>
      other is LocalAudioSource && other.filePath == filePath;

  @override
  int get hashCode => filePath.hashCode;

  @override
  String toString() => 'LocalAudioSource($filePath)';
}

final class RemoteAudioSource extends AudioSource {
  const RemoteAudioSource(this.uri);
  final Uri uri;

  @override
  bool operator ==(Object other) =>
      other is RemoteAudioSource && other.uri == uri;

  @override
  int get hashCode => uri.hashCode;

  @override
  String toString() => 'RemoteAudioSource($uri)';
}
