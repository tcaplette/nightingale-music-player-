import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:nightingale/core/database/daos/track_dao.dart';
import 'package:nightingale/features/recommendations/data/signal_dao.dart';
import 'package:nightingale/core/database/tables/actor_cache_table.dart';
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
  daos: [TrackDao, SignalDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 15;

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
        await m.addColumn(
          nodeIdentityTable,
          nodeIdentityTable.nodePublicAddress,
        );
      }
      if (from < 8) {
        await m.addColumn(
          actorCacheTable,
          actorCacheTable.discoverySource,
        );
      }
      if (from < 9) {
        await m.addColumn(tracksTable, tracksTable.isrc);
      }
      if (from < 10) {
        await m.addColumn(nodeIdentityTable, nodeIdentityTable.summary);
        await m.addColumn(nodeIdentityTable, nodeIdentityTable.avatarJpeg);
      }
      if (from < 11) {
        await m.createTable(chunksTable);
        await m.createTable(chunkManifestsTable);
      }
      if (from < 12) {
        await customStatement(
          'ALTER TABLE tracks ADD COLUMN is_included INTEGER NOT NULL DEFAULT 1',
        );
      }
      if (from < 13) {
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
      if (from < 15) {
        // Remove duplicate follows — keep the latest row per remote_actor_url.
        // Duplicates accumulate when the local identity changes across reinstalls
        // because followsTable had no unique constraint.
        await customStatement(
          'DELETE FROM follows WHERE row_id NOT IN ('
          '  SELECT MAX(row_id) FROM follows GROUP BY remote_actor_url'
          ')',
        );
        // Enforce uniqueness on remote_actor_url alone — local_actor_id changes
        // on reinstall and must not allow re-following the same peer.
        await customStatement(
          'CREATE UNIQUE INDEX IF NOT EXISTS idx_follows_remote_actor_unique '
          'ON follows(remote_actor_url)',
        );
      }
      if (from < 14) {
        // Flatten albums/artists tables into tracks: single source of truth.
        // Guard against a previous partial run that already added this column
        // but crashed before the schema version was bumped.
        try {
          await customStatement(
            'ALTER TABLE tracks ADD COLUMN album_name TEXT',
          );
        } catch (e) {
          if (!e.toString().contains('duplicate column name')) rethrow;
        }
        await transaction(() async {
          await customStatement(
            'UPDATE tracks SET '
            '  album_name = (SELECT name FROM albums WHERE albums.id = tracks.album_id), '
            '  album_artist = COALESCE(album_artist, (SELECT artist FROM albums WHERE albums.id = tracks.album_id)), '
            '  artwork_path = COALESCE(artwork_path, (SELECT artwork_path FROM albums WHERE albums.id = tracks.album_id)), '
            '  release_year = COALESCE(release_year, (SELECT release_year FROM albums WHERE albums.id = tracks.album_id)) '
            'WHERE album_id IS NOT NULL',
          );
          await customStatement(
            'UPDATE tracks SET '
            '  artist = (SELECT artist FROM albums WHERE albums.id = tracks.album_id) '
            'WHERE album_id IS NOT NULL '
            "  AND (LOWER(TRIM(artist)) IN ('unknown artist', '<unknown>', 'unknown') OR TRIM(artist) = '')",
          );
          await customStatement('DROP TABLE IF EXISTS albums');
          await customStatement('DROP TABLE IF EXISTS artists');
        });
        await m.alterTable(TableMigration(tracksTable));
      }
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'nightingale_library');
  }
}
