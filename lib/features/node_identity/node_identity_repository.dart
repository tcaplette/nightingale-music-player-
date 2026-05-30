import 'package:nightingale/core/activitypub/models/ap_actor.dart';

abstract class NodeIdentityRepository {
  Future<bool> hasIdentity();
  Future<void> generateIdentity({required String displayName});
  Future<ApActor> getLocalActor();
  Future<String> getActorUrl();
}
