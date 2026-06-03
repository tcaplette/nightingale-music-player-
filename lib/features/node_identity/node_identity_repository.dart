import 'dart:typed_data';

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
  Future<void> updateProfile({
    required String displayName,
    String? summary,
    Uint8List? avatarBytes,
  });
  Future<Uint8List?> getAvatarBytes();

  /// Returns the shareable handle in @username@host:port format.
  /// Returns null if the STUN public address has not been resolved yet.
  Future<String?> getShareableHandle();
}
