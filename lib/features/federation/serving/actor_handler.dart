import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/features/node_identity/node_identity_repository.dart';

Future<Response> actorHandler(Request request, String username) async {
  final repo = sl<NodeIdentityRepository>();
  final actor = await repo.getLocalActor();

  if (actor.preferredUsername != username) {
    return Response.notFound('Not found');
  }

  return Response.ok(
    jsonEncode(actor.toJson()),
    headers: {
      HttpHeaders.contentTypeHeader: 'application/activity+json',
    },
  );
}
