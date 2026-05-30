import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:shelf/shelf.dart';
import 'package:nightingale/core/activitypub/models/ap_collection.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/features/node_identity/node_identity_repository.dart';

Future<Response> followersHandler(Request request, String username) async {
  final repo = sl<NodeIdentityRepository>();
  final actor = await repo.getLocalActor();

  if (actor.preferredUsername != username) {
    return Response.notFound('Not found');
  }

  final db = sl<AppDatabase>();
  final countExpr = db.followersTable.rowId.count();
  final count = await (db.selectOnly(db.followersTable)
        ..addColumns([countExpr]))
      .map((r) => r.read(countExpr))
      .getSingle();

  final collection = ApOrderedCollection(
    id: actor.followers,
    totalItems: count ?? 0,
    first: '${actor.followers}?page=1',
  );

  return Response.ok(
    jsonEncode(collection.toJson()),
    headers: {HttpHeaders.contentTypeHeader: 'application/activity+json'},
  );
}
