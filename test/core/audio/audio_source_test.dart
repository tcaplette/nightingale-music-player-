import 'package:flutter_test/flutter_test.dart';
import 'package:nightingale/core/audio/audio_source.dart';

void main() {
  group('LocalAudioSource', () {
    test('equality — same path', () {
      const a = LocalAudioSource('/music/track.mp3');
      const b = LocalAudioSource('/music/track.mp3');
      expect(a, equals(b));
    });

    test('equality — different path', () {
      const a = LocalAudioSource('/music/a.mp3');
      const b = LocalAudioSource('/music/b.mp3');
      expect(a, isNot(equals(b)));
    });

    test('hashCode — same for equal instances', () {
      const a = LocalAudioSource('/music/track.mp3');
      const b = LocalAudioSource('/music/track.mp3');
      expect(a.hashCode, equals(b.hashCode));
    });

    test('toString contains path', () {
      const a = LocalAudioSource('/music/track.mp3');
      expect(a.toString(), contains('/music/track.mp3'));
    });
  });

  group('RemoteAudioSource', () {
    test('equality — same uri', () {
      final a = RemoteAudioSource(Uri.parse('https://node.example/track.mp3'));
      final b = RemoteAudioSource(Uri.parse('https://node.example/track.mp3'));
      expect(a, equals(b));
    });

    test('equality — different uri', () {
      final a = RemoteAudioSource(Uri.parse('https://node.example/a.mp3'));
      final b = RemoteAudioSource(Uri.parse('https://node.example/b.mp3'));
      expect(a, isNot(equals(b)));
    });

    test('toString contains uri', () {
      final a = RemoteAudioSource(Uri.parse('https://node.example/track.mp3'));
      expect(a.toString(), contains('https://node.example/track.mp3'));
    });
  });

  group('sealed class pattern matching', () {
    test('exhaustive switch — LocalAudioSource', () {
      const AudioSource source = LocalAudioSource('/music/track.mp3');
      final result = switch (source) {
        LocalAudioSource(:final filePath) => 'local:$filePath',
        RemoteAudioSource(:final uri) => 'remote:$uri',
      };
      expect(result, 'local:/music/track.mp3');
    });

    test('exhaustive switch — RemoteAudioSource', () {
      final AudioSource source =
          RemoteAudioSource(Uri.parse('https://node.example/track.mp3'));
      final result = switch (source) {
        LocalAudioSource(:final filePath) => 'local:$filePath',
        RemoteAudioSource(:final uri) => 'remote:$uri',
      };
      expect(result, startsWith('remote:'));
    });

    test('is-check — LocalAudioSource is AudioSource', () {
      const AudioSource source = LocalAudioSource('/music/track.mp3');
      expect(source, isA<AudioSource>());
      expect(source, isA<LocalAudioSource>());
      expect(source, isNot(isA<RemoteAudioSource>()));
    });
  });
}
