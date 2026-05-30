import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:shelf/shelf.dart';
import 'package:nightingale/core/activitypub/models/ap_collection.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/features/node_identity/node_identity_repository.dart';

const _pageSize = 20;

Future<Response> outboxHandler(Request request, String username) async {
  final repo = sl<NodeIdentityRepository>();
  final actor = await repo.getLocalActor();

  if (actor.preferredUsername != username) {
    return Response.notFound('Not found');
  }

  final outboxUrl = actor.outbox;
  final pageParam = request.requestedUri.queryParameters['page'];

  if (pageParam == null) {
    // Return the OrderedCollection wrapper
    final db = sl<AppDatabase>();
    final count = await (db.selectOnly(db.outboxActivitiesTable)
          ..addColumns([db.outboxActivitiesTable.rowId.count()])
          ..where(
            db.outboxActivitiesTable.status.equals('delivered'),
          ))
        .map((r) => r.read(db.outboxActivitiesTable.rowId.count()))
        .getSingle();

    final collection = ApOrderedCollection(
      id: outboxUrl,
      totalItems: count ?? 0,
      first: '$outboxUrl?page=1',
    );
    return _apResponse(jsonEncode(collection.toJson()));
  }

  final page = int.tryParse(pageParam) ?? 1;
  final offset = (page - 1) * _pageSize;

  final db = sl<AppDatabase>();
  final rows = await (db.select(db.outboxActivitiesTable)
        ..where((t) => t.status.equals('delivered'))
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
        ..limit(_pageSize, offset: offset))
      .get();

  final items = rows
      .map((r) => jsonDecode(r.payloadJson))
      .toList();

  final hasNext = rows.length == _pageSize;
  final hasPrev = page > 1;

  final collectionPage = ApOrderedCollectionPage(
    id: '$outboxUrl?page=$page',
    partOf: outboxUrl,
    orderedItems: items,
    next: hasNext ? '$outboxUrl?page=${page + 1}' : null,
    prev: hasPrev ? '$outboxUrl?page=${page - 1}' : null,
  );
  return _apResponse(jsonEncode(collectionPage.toJson()));
}

Response _apResponse(String body) => Response.ok(
      body,
      headers: {HttpHeaders.contentTypeHeader: 'application/activity+json'},
    );
