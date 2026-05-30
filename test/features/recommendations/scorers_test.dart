import 'package:flutter_test/flutter_test.dart';
import 'package:nightingale/features/recommendations/domain/network_trending_scorer.dart';
import 'package:nightingale/features/recommendations/domain/new_from_known_scorer.dart';
import 'package:nightingale/features/recommendations/domain/provenance_record.dart';
import 'package:nightingale/features/recommendations/domain/scoring_pipeline.dart';
import 'package:nightingale/features/recommendations/domain/signal_event.dart';
import 'package:nightingale/features/recommendations/domain/taste_affinity_scorer.dart';

void main() {
  group('NetworkTrendingScorer', () {
    final scorer = NetworkTrendingScorer();

    DateTime recent() => DateTime.now().toUtc().subtract(const Duration(days: 1));

    test('counts distinct actors, not raw event count', () {
      final events = [
        // actor1 listens 5 times to the same track
        for (var i = 0; i < 5; i++)
          SignalEvent(
            trackFingerprint: 'artist:track',
            eventType: SignalEventType.networkListen,
            sourceActorId: 'actor1',
            timestampUtc: recent(),
            weight: 0.5,
          ),
        // actor2 listens once
        SignalEvent(
          trackFingerprint: 'artist:track',
          eventType: SignalEventType.networkListen,
          sourceActorId: 'actor2',
          timestampUtc: recent(),
          weight: 0.5,
        ),
      ];

      final results = scorer.score(
        networkEvents: events,
        actorDisplayNames: {},
        ownedFingerprints: {},
      );

      expect(results, hasLength(1));
      expect(results.first.score, equals(2.0)); // 2 distinct actors
    });

    test('excludes tracks older than 7 days', () {
      final old = DateTime.now().toUtc().subtract(const Duration(days: 8));
      final events = [
        SignalEvent(
          trackFingerprint: 'old:track',
          eventType: SignalEventType.networkListen,
          sourceActorId: 'actor1',
          timestampUtc: old,
          weight: 0.5,
        ),
      ];

      final results = scorer.score(
        networkEvents: events,
        actorDisplayNames: {},
        ownedFingerprints: {},
      );

      expect(results, isEmpty);
    });

    test('excludes owned fingerprints', () {
      final events = [
        SignalEvent(
          trackFingerprint: 'owned:track',
          eventType: SignalEventType.networkListen,
          sourceActorId: 'actor1',
          timestampUtc: recent(),
          weight: 0.5,
        ),
      ];

      final results = scorer.score(
        networkEvents: events,
        actorDisplayNames: {},
        ownedFingerprints: {'owned:track'},
      );

      expect(results, isEmpty);
    });

    test('builds reason string with display name for single actor', () {
      final events = [
        SignalEvent(
          trackFingerprint: 'artist:track',
          eventType: SignalEventType.networkListen,
          sourceActorId: 'actor1',
          timestampUtc: recent(),
          weight: 0.5,
        ),
      ];

      final results = scorer.score(
        networkEvents: events,
        actorDisplayNames: {'actor1': 'Maya'},
        ownedFingerprints: {},
      );

      expect(results.first.provenance.reasonString, contains('Maya'));
      expect(results.first.provenance.topActorDisplayName, equals('Maya'));
    });
  });

  group('TasteAffinityScorer', () {
    final scorer = TasteAffinityScorer();

    test('returns empty list when local signals below minimum threshold', () {
      final localScores = {
        for (var i = 0; i < 9; i++) 'track$i:title': 1.0,
      }; // 9 < minimum 10

      final results = scorer.score(
        localScores: localScores,
        networkEvents: [],
        actorDisplayNames: {},
        ownedFingerprints: {},
      );

      expect(results, isEmpty);
    });

    test('returns results when local signals meet threshold', () {
      final localScores = {
        for (var i = 0; i < 10; i++) 'artist$i:track': 1.0,
      };

      final events = [
        SignalEvent(
          trackFingerprint: 'artist0:track', // overlap with local
          eventType: SignalEventType.networkListen,
          sourceActorId: 'actor1',
          timestampUtc: DateTime.now().toUtc(),
          weight: 0.5,
        ),
        SignalEvent(
          trackFingerprint: 'new:discovery', // not in local library
          eventType: SignalEventType.networkListen,
          sourceActorId: 'actor1',
          timestampUtc: DateTime.now().toUtc(),
          weight: 0.5,
        ),
      ];

      final results = scorer.score(
        localScores: localScores,
        networkEvents: events,
        actorDisplayNames: {'actor1': 'Jordan'},
        ownedFingerprints: {'artist0:track'},
      );

      // new:discovery should appear (not owned), artist0:track should be excluded
      expect(results.any((r) => r.trackFingerprint == 'new:discovery'), isTrue);
      expect(results.any((r) => r.trackFingerprint == 'artist0:track'), isFalse);
    });
  });

  group('NewFromKnownScorer', () {
    final scorer = NewFromKnownScorer();

    test('surfaces tracks by known artists not in library', () {
      final events = [
        SignalEvent(
          trackFingerprint: 'radiohead:karma police',
          eventType: SignalEventType.networkListen,
          sourceActorId: 'actor1',
          timestampUtc: DateTime.now().toUtc(),
          weight: 0.5,
        ),
      ];

      final results = scorer.score(
        localArtistsNormalized: {'radiohead'},
        networkEvents: events,
        ownedFingerprints: {},
      );

      expect(results, hasLength(1));
      expect(results.first.trackFingerprint, 'radiohead:karma police');
      expect(results.first.provenance.paths, contains(ScoringPath.newFromKnown));
    });

    test('excludes already-owned tracks', () {
      final events = [
        SignalEvent(
          trackFingerprint: 'radiohead:creep',
          eventType: SignalEventType.networkListen,
          sourceActorId: 'actor1',
          timestampUtc: DateTime.now().toUtc(),
          weight: 0.5,
        ),
      ];

      final results = scorer.score(
        localArtistsNormalized: {'radiohead'},
        networkEvents: events,
        ownedFingerprints: {'radiohead:creep'},
      );

      expect(results, isEmpty);
    });

    test('ignores tracks by artists not in local library', () {
      final events = [
        SignalEvent(
          trackFingerprint: 'unknown artist:some track',
          eventType: SignalEventType.networkListen,
          sourceActorId: 'actor1',
          timestampUtc: DateTime.now().toUtc(),
          weight: 0.5,
        ),
      ];

      final results = scorer.score(
        localArtistsNormalized: {'radiohead'},
        networkEvents: events,
        ownedFingerprints: {},
      );

      expect(results, isEmpty);
    });
  });

  group('ScoringPipeline', () {
    test('deduplicates fingerprint-matched candidates across paths', () {
      final events = [
        SignalEvent(
          trackFingerprint: 'shared:track',
          eventType: SignalEventType.networkListen,
          sourceActorId: 'actor1',
          timestampUtc: DateTime.now().toUtc().subtract(const Duration(days: 1)),
          weight: 0.5,
        ),
      ];

      final localScores = {
        for (var i = 0; i < 10; i++) 'artist$i:title': 1.0,
      };

      final pipeline = ScoringPipeline();
      final input = ScoringInput(
        localScores: localScores,
        networkEvents: events,
        actorDisplayNames: {'actor1': 'Maya'},
        localArtistsNormalized: {'shared'},
        ownedFingerprints: {},
        followingCount: 1,
      );

      final results = pipeline.run(input);
      final fps = results.map((r) => r.trackFingerprint).toList();
      // No duplicate fingerprints in final output
      expect(fps.toSet().length, equals(fps.length));
    });

    test('returns empty list when followingCount is 0', () {
      final pipeline = ScoringPipeline();
      final input = ScoringInput(
        localScores: {},
        networkEvents: [],
        actorDisplayNames: {},
        localArtistsNormalized: {},
        ownedFingerprints: {},
        followingCount: 0,
      );

      expect(pipeline.run(input), isEmpty);
    });
  });
}
