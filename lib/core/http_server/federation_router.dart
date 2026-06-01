import 'package:shelf_router/shelf_router.dart';

// Handler imports — added as each handler is implemented.
import 'package:nightingale/features/federation/serving/webfinger_handler.dart';
import 'package:nightingale/features/federation/serving/actor_handler.dart';
import 'package:nightingale/features/federation/serving/avatar_handler.dart';
import 'package:nightingale/features/federation/serving/inbox_handler.dart';
import 'package:nightingale/features/federation/serving/outbox_handler.dart';
import 'package:nightingale/features/federation/serving/followers_handler.dart';
import 'package:nightingale/features/federation/serving/following_handler.dart';
import 'package:nightingale/features/federation/serving/library_handler.dart';
import 'package:nightingale/features/federation/serving/playlist_handler.dart';
import 'package:nightingale/features/federation/serving/stream_handler.dart';

Router buildFederationRouter() {
  final router = Router();

  router.get('/.well-known/webfinger', webFingerHandler);
  router.get('/users/<username>', actorHandler);
  router.get('/users/<username>/avatar', avatarHandler);
  router.get('/users/<username>/library', libraryHandler);
  // Phase 5 — playlist endpoint
  router.get('/users/<username>/playlists/<playlistId>', playlistHandler);
  router.post('/users/<username>/inbox', inboxHandler);
  router.get('/users/<username>/outbox', outboxHandler);
  router.get('/users/<username>/followers', followersHandler);
  router.get('/users/<username>/following', followingHandler);
  router.get('/stream/<trackId>', streamHandler);

  return router;
}
