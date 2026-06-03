import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:nightingale/core/database/daos/album_dao.dart';
import 'package:nightingale/core/database/daos/artist_dao.dart';
import 'package:nightingale/core/database/daos/track_dao.dart';
import 'package:nightingale/features/recommendations/data/signal_dao.dart';
import 'package:nightingale/core/database/tables/actor_cache_table.dart';
import 'package:nightingale/core/database/tables/albums_table.dart';
import 'package:nightingale/core/database/tables/artists_table.dart';
import 'package:nightingale/core/database/tables/audio_cache_table.dart';
import 'package:nightingale/core/database/tables/blocks_table.dart';
import 'package:nightingale/core/database/tables/defederated_nodes_table.dart';
import 'package:nightingale/core/database/tables/fingerprints_table.dart';
import 'package:nightingale/core/database/tables/follow_requests_table.dart';
import 'package:nightingale/core/database/tables/followers_table.dart';
import 'package:nightingale/core/database/tables/following_table.dart';
import 'package:nightingale/core/database/tables/follows_table.dart';
import 'package:nightingale/core/database/tables/inbox_activities_table.dart';
import 'package:nightingale/core/database/tables/listen_activities_table.dart';
import 'package:nightingale/core/database/tables/merge_provenance_table.dart';
import 'package:nightingale/core/database/tables/migration_tokens_table.dart';
import 'package:nightingale/core/database/tables/mutes_table.dart';
import 'package:nightingale/core/database/tables/node_allow_deny_list_table.dart';
import 'package:nightingale/core/database/tables/node_identity_table.dart';
import 'package:nightingale/core/database/tables/notifications_table.dart';
import 'package:nightingale/core/database/tables/outbox_activities_table.dart';
import 'package:nightingale/core/database/tables/playlists_table.dart';
import 'package:nightingale/core/database/tables/remote_libraries_table.dart';
import 'package:nightingale/core/database/tables/signal_events_table.dart';
import 'package:nightingale/core/database/tables/social_activities_table.dart';
import 'package:nightingale/core/database/tables/taste_scores_table.dart';
import 'package:nightingale/core/database/tables/activity_queue_table.dart';
import 'package:nightingale/core/database/tables/chunks_table.dart';
import 'package:nightingale/core/database/tables/chunk_manifests_table.dart';
import 'package:nightingale/core/database/tables/tracks_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    TracksTable,
    AlbumsTable,
    ArtistsTable,
    // Phase 3 — federation tables
    NodeIdentityTable,
    InboxActivitiesTable,
    OutboxActivitiesTable,
    ActorCacheTable,
    FollowersTable,
    FollowingTable,
    DefederatedNodesTable,
    NodeAllowDenyListTable,
    MigrationTokensTable,
    // Phase 4 — library federation & streaming tables
    RemoteLibrariesTable,
    AudioCacheTable,
    ListenActivitiesTable,
    FingerprintsTable,
    MergeProvenanceTable,
    // Phase 5 — social layer tables
    FollowsTable,
    FollowRequestsTable,
    BlocksTable,
    MutesTable,
    SocialActivitiesTable,
    NotificationsTable,
    PlaylistsTable,
    // Phase 6 — recommendation signal tables (encrypted at rest)
    SignalEventsTable,
    TasteScoresTable,
    // Phase 7 — offline activity queue
    ActivityQueueTable,
    // Phase 8 — chunk-based federated audio cache
    ChunksTable,
    ChunkManifestsTable,
  ],
  daos: [TrackDao, AlbumDao, ArtistDao, SignalDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 13;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(nodeIdentityTable);
        await m.createTable(inboxActivitiesTable);
        await m.createTable(outboxActivitiesTable);
        await m.createTable(actorCacheTable);
        await m.createTable(followersTable);
        await m.createTable(followingTable);
        await m.createTable(defederatedNodesTable);
        await m.createTable(nodeAllowDenyListTable);
        await m.createTable(migrationTokensTable);
      }
      if (from < 3) {
        await m.createTable(remoteLibrariesTable);
        await m.createTable(audioCacheTable);
        await m.createTable(listenActivitiesTable);
        await m.createTable(fingerprintsTable);
        await m.createTable(mergeProvenanceTable);
      }
      if (from < 4) {
        await m.createTable(followsTable);
        await m.createTable(followRequestsTable);
        await m.createTable(blocksTable);
        await m.createTable(mutesTable);
        await m.createTable(socialActivitiesTable);
        await m.createTable(notificationsTable);
        await m.createTable(playlistsTable);
      }
      if (from < 5) {
        await m.createTable(signalEventsTable);
        await m.createTable(tasteScoresTable);
      }
      if (from < 6) {
        await m.createTable(activityQueueTable);
      }
      if (from < 7) {
        // Phase 0b: add STUN-discovered public address to node identity.
        await m.addColumn(
          nodeIdentityTable,
          nodeIdentityTable.nodePublicAddress,
        );
      }
      if (from < 8) {
        // Phase 0c: discovery source tag on actor cache entries.
        await m.addColumn(
          actorCacheTable,
          actorCacheTable.discoverySource,
        );
      }
      if (from < 9) {
        // Metadata validation: ISRC read-only field for deduplication.
        await m.addColumn(tracksTable, tracksTable.isrc);
      }
      if (from < 10) {
        // User profile: bio and avatar photo.
        await m.addColumn(nodeIdentityTable, nodeIdentityTable.summary);
        await m.addColumn(nodeIdentityTable, nodeIdentityTable.avatarJpeg);
      }
      if (from < 11) {
        // Phase 8: chunk-based federated audio cache.
        await m.createTable(chunksTable);
        await m.createTable(chunkManifestsTable);
      }
      if (from < 12) {
        // User-controlled library import: existing tracks default to included
        // so upgrading users don't lose their library.
        await customStatement(
          'ALTER TABLE tracks ADD COLUMN is_included INTEGER NOT NULL DEFAULT 1',
        );
      }
      if (from < 13) {
        // Artist FK columns: replace string-match artist relationships with
        // integer foreign keys for correct deduplication and navigation.
        await customStatement(
          'ALTER TABLE tracks ADD COLUMN artist_id INTEGER REFERENCES artists(id)',
        );
        await customStatement(
          'ALTER TABLE tracks ADD COLUMN album_artist_id INTEGER REFERENCES artists(id)',
        );
        await transaction(() async {
          await customStatement(
            'UPDATE tracks SET artist_id = ('
            '  SELECT id FROM artists WHERE artists.name = tracks.artist'
            ')',
          );
          await customStatement(
            'UPDATE tracks SET album_artist_id = ('
            '  SELECT id FROM artists WHERE artists.name = tracks.album_artist'
            ')',
          );
        });
      }
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'nightingale_library');
  }
}
