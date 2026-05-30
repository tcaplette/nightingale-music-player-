import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/core/resilience/database_integrity_service.dart';

void main() {
  late AppDatabase db;
  late DatabaseIntegrityService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service = DatabaseIntegrityService(db: db);
  });

  tearDown(() async => db.close());

  test('checkAndRepair returns ok for a healthy in-memory database', () async {
    final result = await service.checkAndRepair();
    expect(result, IntegrityCheckResult.ok);
  });
}
