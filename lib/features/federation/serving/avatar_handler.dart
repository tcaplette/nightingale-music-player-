import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/features/node_identity/node_identity_repository.dart';

Future<Response> avatarHandler(Request request, String username) async {
  final repo = sl<NodeIdentityRepository>();
  final actor = await repo.getLocalActor();

  if (actor.preferredUsername != username) {
    return Response.notFound('Not found');
  }

  final bytes = await repo.getAvatarBytes();
  if (bytes == null) {
    return Response.notFound('No avatar set');
  }

  return Response.ok(
    bytes,
    headers: {HttpHeaders.contentTypeHeader: 'image/jpeg'},
  );
}
