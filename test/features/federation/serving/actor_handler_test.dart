import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nightingale/core/activitypub/models/ap_actor.dart';
import 'package:nightingale/core/activitypub/models/ap_public_key.dart';
import 'package:nightingale/features/federation/serving/actor_handler.dart';
import 'package:nightingale/features/node_identity/node_identity_repository.dart';
import 'package:shelf/shelf.dart';

class _FakeIdentityRepo implements NodeIdentityRepository {
  _FakeIdentityRepo({this.publicAddress});
  final String? publicAddress;

  static const _actorUrl = 'http://192.168.1.10:7777/users/alice';

  @override
  Future<bool> hasIdentity() async => true;

  @override
  Future<void> generateIdentity({
    required String displayName,
    required String lanIp,
    required int port,
  }) async {}

  @override
  Future<ApActor> getLocalActor() async => ApActor(
        id: _actorUrl,
        type: 'Person',
        inbox: '$_actorUrl/inbox',
        outbox: '$_actorUrl/outbox',
        followers: '$_actorUrl/followers',
        following: '$_actorUrl/following',
        preferredUsername: 'alice',
        name: 'Alice',
        publicKey: ApPublicKey(
          id: '$_actorUrl#main-key',
          owner: _actorUrl,
          publicKeyPem: '-----BEGIN PUBLIC KEY-----\nfake\n-----END PUBLIC KEY-----',
        ),
      );

  @override
  Future<String> getActorUrl() async => _actorUrl;

  @override
  Future<void> updatePublicAddress(String? pa) async {}

  @override
  Future<String?> getPublicAddress() async => publicAddress;
  @override
  Future<String?> getShareableHandle() async => null;
  @override
  Future<void> updateProfile({required String displayName, String? summary, Uint8List? avatarBytes}) async {}
  @override
  Future<Uint8List?> getAvatarBytes() async => null;
}

void main() {
  final sl = GetIt.instance;

  tearDown(() => sl.reset());

  group('actorHandler', () {
    test('includes x-nightingale-public-address when nodePublicAddress is set',
        () async {
      sl.registerSingleton<NodeIdentityRepository>(
        _FakeIdentityRepo(publicAddress: '203.0.113.5:7777'),
      );

      final request = Request(
        'GET',
        Uri.parse('http://192.168.1.10:7777/users/alice'),
      );
      final response = await actorHandler(request, 'alice');
      expect(response.statusCode, 200);

      final body = jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      expect(body['x-nightingale-public-address'], '203.0.113.5:7777');
    });

    test('omits x-nightingale-public-address when nodePublicAddress is null',
        () async {
      sl.registerSingleton<NodeIdentityRepository>(
        _FakeIdentityRepo(publicAddress: null),
      );

      final request = Request(
        'GET',
        Uri.parse('http://192.168.1.10:7777/users/alice'),
      );
      final response = await actorHandler(request, 'alice');
      expect(response.statusCode, 200);

      final body = jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      expect(body.containsKey('x-nightingale-public-address'), isFalse);
    });

    test('returns 404 for unknown username', () async {
      sl.registerSingleton<NodeIdentityRepository>(
        _FakeIdentityRepo(publicAddress: null),
      );

      final request = Request(
        'GET',
        Uri.parse('http://192.168.1.10:7777/users/unknown'),
      );
      final response = await actorHandler(request, 'unknown');
      expect(response.statusCode, 404);
    });
  });
}
