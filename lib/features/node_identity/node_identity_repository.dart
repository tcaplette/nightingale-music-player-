import 'package:nightingale/core/activitypub/models/ap_actor.dart';

abstract class NodeIdentityRepository {
  Future<bool> hasIdentity();
  Future<void> generateIdentity({
    required String displayName,
    required String lanIp,
    required int port,
  });
  Future<ApActor> getLocalActor();
  Future<String> getActorUrl();
  Future<void> updatePublicAddress(String? publicAddress);
  Future<String?> getPublicAddress();
}
