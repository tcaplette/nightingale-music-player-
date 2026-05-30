import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/features/federation/deduplication/acoustic_fingerprint_service.dart';

AppDatabase _inMemoryDb() => AppDatabase(NativeDatabase.memory());

void main() {
  group('AcousticFingerprintService', () {
    late AppDatabase db;
    late AcousticFingerprintService service;

    setUp(() async {
      db = _inMemoryDb();
      service = AcousticFingerprintService(db: db);
    });

    tearDown(() async {
      await db.close();
    });

    test('fingerprintTrack generates and stores fingerprint', () async {
      final fingerprint = await service.fingerprintTrack(1, '/music/test.mp3');
      expect(fingerprint, isNotNull);
      expect(fingerprint!.isNotEmpty, true);
    });

    test('findDuplicates finds identical fingerprints', () async {
      // Same file path should generate same fingerprint
      await service.fingerprintTrack(1, '/music/same.mp3');
      await service.fingerprintTrack(2, '/music/same.mp3');

      final duplicates = await service.findDuplicates(1, threshold: 1.0);
      expect(duplicates, contains(2));
    });

    test('findDuplicates excludes self', () async {
      await service.fingerprintTrack(1, '/music/test.mp3');

      final duplicates = await service.findDuplicates(1);
      expect(duplicates, isNot(contains(1)));
    });

    test('recordMerge stores provenance', () async {
      await service.recordMerge(
        canonicalTrackId: 1,
        duplicateTrackId: 2,
        sourceActorUrl: 'http://actor1',
        action: MergeAction.mergeToCanonical,
      );

      final history = await service.getMergeHistory(1);
      expect(history.length, 1);
      expect(history.first.fingerprintA, '1');
      expect(history.first.fingerprintB, '2');
    });

    test('unmerge removes provenance', () async {
      await service.recordMerge(
        canonicalTrackId: 1,
        duplicateTrackId: 2,
        sourceActorUrl: 'http://actor1',
        action: MergeAction.mergeToCanonical,
      );

      await service.unmerge(1);

      final history = await service.getMergeHistory(1);
      expect(history, isEmpty);
    });
  });
}
