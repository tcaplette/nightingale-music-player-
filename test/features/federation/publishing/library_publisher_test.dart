import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightingale/core/activitypub/models/ap_actor.dart';
import 'package:nightingale/core/activitypub/models/ap_audio.dart';
import 'package:nightingale/core/activitypub/models/ap_collection.dart';
import 'package:nightingale/core/activitypub/models/ap_public_key.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/features/federation/publishing/library_publisher.dart';
import 'package:nightingale/features/library/library_repository.dart';
import 'package:nightingale/features/library/models/album_model.dart';
import 'package:nightingale/features/library/models/artist_model.dart';
import 'package:nightingale/features/library/models/scan_result.dart';
import 'package:nightingale/features/library/models/track_model.dart';
import 'package:nightingale/features/node_identity/node_identity_repository.dart';

AppDatabase _inMemoryDb() => AppDatabase(NativeDatabase.memory());

class _FakeLibraryRepo implements LibraryRepository {
  @override
  Future<List<TrackModel>> getAllTracks() async => [
    TrackModel(
      id: 1,
      filePath: '/music/song1.mp3',
      title: 'Song One',
      artist: 'Artist A',
      durationMs: 180000,
      dateAdded: DateTime.now(),
    ),
    TrackModel(
      id: 2,
      filePath: '/music/song2.mp3',
      title: 'Song Two',
      artist: 'Artist B',
      durationMs: 240000,
      dateAdded: DateTime.now(),
    ),
  ];

  @override
  Future<ScanResult> scanLibrary() async => ScanResult(totalFound: 0, parsed: 0, rejected: 0, errors: [], durationMs: 0, completedAt: DateTime.now());
  @override
  Stream<List<TrackModel>> watchAllTracks() async* { yield <TrackModel>[]; }
  @override
  Future<List<AlbumModel>> getAlbums() async => <AlbumModel>[];
  @override
  Stream<List<AlbumModel>> watchAlbums() async* { yield <AlbumModel>[]; }
  @override
  Future<List<TrackModel>> getTracksByAlbum(int albumId) async => <TrackModel>[];
  @override
  Future<AlbumModel?> getAlbumById(int albumId) async => null;
  @override
  Future<List<ArtistModel>> getArtists() async => <ArtistModel>[];
  @override
  Stream<List<ArtistModel>> watchArtists() async* { yield <ArtistModel>[]; }
  @override
  Future<List<AlbumModel>> getAlbumsByArtist(String artist) async => <AlbumModel>[];
  @override
  Future<List<TrackModel>> getTracksByArtist(String artist) async => <TrackModel>[];
  @override
  Future<List<String>> getGenres() async => <String>[];
  @override
  Future<List<TrackModel>> getTracksByGenre(String genre) async => <TrackModel>[];
  @override
  Future<({List<TrackModel> tracks, List<AlbumModel> albums, List<ArtistModel> artists})> searchLibrary(String query) async => (tracks: <TrackModel>[], albums: <AlbumModel>[], artists: <ArtistModel>[]);
}

class _FakeIdentityRepo implements NodeIdentityRepository {
  @override
  Future<String> getActorUrl() async => 'http://localhost/users/node';

  @override
  Future<ApActor> getLocalActor() async => ApActor(
    id: 'http://localhost/users/node',
    type: 'Person',
    inbox: 'http://localhost/inbox',
    outbox: 'http://localhost/outbox',
    followers: 'http://localhost/followers',
    following: 'http://localhost/following',
    preferredUsername: 'node',
    name: 'Node',
    publicKey: ApPublicKey(
      id: 'http://localhost/users/node#main-key',
      owner: 'http://localhost/users/node',
      publicKeyPem: '-----BEGIN PUBLIC KEY-----\nMCowBQYDK2VwAyEA\n-----END PUBLIC KEY-----',
    ),
  );

  @override
  Future<bool> hasIdentity() async => true;

  @override
  Future<void> generateIdentity({
    required String displayName,
    required String lanIp,
    required int port,
  }) async {}

  @override
  Future<void> updatePublicAddress(String? publicAddress) async {}

  @override
  Future<String?> getPublicAddress() async => null;
}

void main() {
  group('LibraryPublisher', () {
    late LibraryPublisher publisher;
    late AppDatabase db;

    setUp(() {
      db = _inMemoryDb();
      publisher = LibraryPublisher(
        libraryRepo: _FakeLibraryRepo(),
        identityRepo: _FakeIdentityRepo(),
        db: db,
      );
    });

    tearDown(() => db.close());

    test('defaults to private scope', () {
      expect(publisher.sharingScope, SharingScope.private);
    });

    test('setSharingScope updates scope', () {
      publisher.setSharingScope(SharingScope.public);
      expect(publisher.sharingScope, SharingScope.public);
    });

    test('buildCollection returns null when private', () async {
      publisher.setSharingScope(SharingScope.private);
      final collection = await publisher.buildCollection();
      expect(collection, isNull);
    });

    test('buildCollection returns collection when public', () async {
      publisher.setSharingScope(SharingScope.public);
      final collection = await publisher.buildCollection();
      expect(collection, isNotNull);
      expect(collection!.totalItems, 2);
      expect(collection.first, 'http://localhost/users/node/library?page=1');
    });

    test('buildCollectionPage returns null when private', () async {
      publisher.setSharingScope(SharingScope.private);
      final page = await publisher.buildCollectionPage(page: 1);
      expect(page, isNull);
    });

    test('buildCollectionPage returns Audio objects when public', () async {
      publisher.setSharingScope(SharingScope.public);
      final page = await publisher.buildCollectionPage(page: 1, pageSize: 10);
      expect(page, isNotNull);
      expect(page!.orderedItems.length, 2);
      
      final firstAudio = ApAudio.fromJson(page.orderedItems.first as Map<String, dynamic>);
      expect(firstAudio.name, 'Song One');
      expect(firstAudio.artist, 'Artist A');
      expect(firstAudio.url, 'http://localhost/users/node/stream/1');
    });

    test('privacy filtering rejects non-followers when followers-only', () async {
      publisher.setSharingScope(SharingScope.followersOnly);
      final collection = await publisher.buildCollection(requesterActorUrl: 'http://other/users/someone');
      expect(collection, isNull);
    });
  });
}
