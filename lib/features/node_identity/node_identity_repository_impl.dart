import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:nightingale/core/activitypub/models/ap_actor.dart';
import 'package:nightingale/core/activitypub/models/ap_public_key.dart';
import 'package:nightingale/core/crypto/crypto_service.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/features/node_identity/node_identity_repository.dart';

class NodeIdentityRepositoryImpl implements NodeIdentityRepository {
  NodeIdentityRepositoryImpl({
    required this.db,
    required this.crypto,
  });

  final AppDatabase db;
  final CryptoService crypto;

  @override
  Future<bool> hasIdentity() async {
    final count = await (db.selectOnly(db.nodeIdentityTable)
          ..addColumns([db.nodeIdentityTable.rowId.count()]))
        .map((r) => r.read(db.nodeIdentityTable.rowId.count()))
        .getSingle();
    return (count ?? 0) > 0;
  }

  @override
  Future<void> generateIdentity({
    required String displayName,
    required String username,
    required String lanIp,
    required int port,
  }) async {
    await crypto.generateKeyPair();
    final publicKeyPem = await crypto.getPublicKeyPem();
    final safeUsername = _sanitizeUsername(username);
    final actorUrl = 'http://$lanIp:$port/users/$safeUsername';

    await db.into(db.nodeIdentityTable).insert(
          NodeIdentityTableCompanion.insert(
            actorUrl: actorUrl,
            publicKeyPem: publicKeyPem,
            preferredUsername: safeUsername,
            displayName: displayName,
          ),
        );
  }

  /// Sanitizes a username for use in URLs and ActivityPub identifiers.
  /// Allows lowercase letters, digits, underscores, and hyphens only.
  String _sanitizeUsername(String username) {
    return username
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_-]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  @override
  Future<ApActor> getLocalActor() async {
    final row = await (db.select(db.nodeIdentityTable)).getSingle();
    return _rowToActor(row);
  }

  @override
  Future<String> getActorUrl() async {
    final row = await (db.select(db.nodeIdentityTable)).getSingle();
    return row.actorUrl;
  }

  @override
  Future<void> updatePublicAddress(String? publicAddress) async {
    await (db.update(db.nodeIdentityTable)).write(
      NodeIdentityTableCompanion(
        nodePublicAddress: Value(publicAddress),
      ),
    );
  }

  @override
  Future<String?> getPublicAddress() async {
    final row = await (db.select(db.nodeIdentityTable)).getSingle();
    return row.nodePublicAddress;
  }

  @override
  Future<void> updateProfile({
    required String displayName,
    String? summary,
    Uint8List? avatarBytes,
  }) async {
    await (db.update(db.nodeIdentityTable)).write(
      NodeIdentityTableCompanion(
        displayName: Value(displayName),
        summary: Value(summary),
        avatarJpeg: Value(avatarBytes),
      ),
    );
  }

  @override
  Future<Uint8List?> getAvatarBytes() async {
    final row = await (db.select(db.nodeIdentityTable)).getSingle();
    return row.avatarJpeg;
  }

  @override
  Future<String?> getShareableHandle() async {
    final row = await (db.select(db.nodeIdentityTable)).getSingle();
    final publicAddress = row.nodePublicAddress;
    if (publicAddress == null || publicAddress.isEmpty) return null;
    return '@${row.preferredUsername}@$publicAddress';
  }

  ApActor _rowToActor(NodeIdentityTableData row) {
    final url = row.actorUrl;
    return ApActor(
      id: url,
      type: 'Person',
      inbox: '$url/inbox',
      outbox: '$url/outbox',
      followers: '$url/followers',
      following: '$url/following',
      preferredUsername: row.preferredUsername,
      name: row.displayName,
      publicKey: ApPublicKey(
        id: '$url#main-key',
        owner: url,
        publicKeyPem: row.publicKeyPem,
      ),
      summary: row.summary,
      icon: row.avatarJpeg != null ? '$url/avatar' : null,
    );
  }

}
