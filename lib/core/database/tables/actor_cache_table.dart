import 'package:drift/drift.dart';

class ActorCacheTable extends Table {
  @override
  String get tableName => 'actor_cache';

  IntColumn get rowId => integer().autoIncrement()();
  TextColumn get actorUrl => text().unique()();
  TextColumn get actorJson => text()();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get ttlSeconds => integer().withDefault(const Constant(900))();
  // How this actor was first discovered. Priority (high→low):
  // manual > mDNS > mastodonImport > stun > peerExchange
  TextColumn get discoverySource =>
      text().withDefault(const Constant('manual'))();
}
