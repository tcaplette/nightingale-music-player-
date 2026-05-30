import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/core/logging/app_logger.dart';
import 'package:nightingale/features/federation/publishing/library_publisher.dart';
import 'package:nightingale/features/node_identity/node_identity_repository.dart';

const _tag = 'library_handler';

Future<Response> libraryHandler(Request request, String username) async {
  final identityRepo = sl<NodeIdentityRepository>();
  final actor = await identityRepo.getLocalActor();

  if (actor.preferredUsername != username) {
    return Response.notFound('Not found');
  }

  final publisher = sl<LibraryPublisher>();

  // Extract requester from HTTP Signature if present
  final requesterActorUrl = _extractRequester(request);

  final pageParam = request.url.queryParameters['page'];
  if (pageParam != null) {
    final page = int.tryParse(pageParam);
    if (page == null || page < 1) {
      return Response.badRequest(body: 'Invalid page parameter');
    }

    final collectionPage = await publisher.buildCollectionPage(
      page: page,
      requesterActorUrl: requesterActorUrl,
    );

    if (collectionPage == null) {
      return Response.forbidden('Forbidden');
    }

    return Response.ok(
      jsonEncode(collectionPage.toJson()),
      headers: {
        HttpHeaders.contentTypeHeader: 'application/activity+json',
      },
    );
  }

  // Collection root
  final collection = await publisher.buildCollection(
    requesterActorUrl: requesterActorUrl,
  );

  if (collection == null) {
    return Response.forbidden('Forbidden');
  }

  return Response.ok(
    jsonEncode(collection.toJson()),
    headers: {
      HttpHeaders.contentTypeHeader: 'application/activity+json',
    },
  );
}

String? _extractRequester(Request request) {
  // TODO: Extract the actor URL from the verified HTTP Signature
  // This will be wired in Task 7.2 when signature verification middleware is added
  final signatureHeader = request.headers['signature'];
  if (signatureHeader == null) return null;
  AppLogger.debug('Library request signature: $signatureHeader', tag: _tag);
  return null; // Placeholder — will return verified actor URL
}
