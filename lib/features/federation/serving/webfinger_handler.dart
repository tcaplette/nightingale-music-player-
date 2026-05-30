import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/core/activitypub/models/webfinger_jrd.dart';
import 'package:nightingale/features/node_identity/node_identity_repository.dart';

Future<Response> webFingerHandler(Request request) async {
  final resource = request.requestedUri.queryParameters['resource'];
  if (resource == null) {
    return Response(HttpStatus.badRequest, body: 'Missing resource parameter');
  }

  final repo = sl<NodeIdentityRepository>();
  final actor = await repo.getLocalActor();
  final expectedAcct = 'acct:${actor.preferredUsername}@'
      '${request.requestedUri.host}';

  if (resource != expectedAcct && resource != actor.id) {
    return Response.notFound('Not found');
  }

  final jrd = WebFingerJrd(
    subject: expectedAcct,
    aliases: [actor.id],
    links: [
      WebFingerLink(
        rel: 'self',
        type: 'application/activity+json',
        href: actor.id,
      ),
    ],
  );

  return Response.ok(
    jsonEncode(jrd.toJson()),
    headers: {HttpHeaders.contentTypeHeader: 'application/jrd+json'},
  );
}
