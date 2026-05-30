## ADDED Requirements

### Requirement: Unit tests cover all federated-player algorithm modules
Unit tests SHALL exist for: recommendation logic (network trending, taste affinity, new-from-known), cold-start bootstrap (node discovery scoring, genre/library overlap), ActivityPub serialization (Actor, Listen, Like, Announce, OrderedCollection round-trips), HTTP Signature signing and verification, replay-protection nonce/timestamp window enforcement, Chromaprint acoustic fingerprinting deduplication logic, stream authentication token generation and verification, and Ed25519 key migration (`Move` activity generation and ingestion).

#### Scenario: Recommendation engine unit test
- **WHEN** a unit test provides a mock signal store with known play counts and network listens
- **THEN** the recommendation engine SHALL return candidates in the expected ranked order
- **THEN** the test SHALL assert on both the candidate set and the provenance reason string for each

#### Scenario: HTTP Signature replay protection unit test
- **WHEN** a unit test replays a valid signed request with a timestamp outside the ±30 s window
- **THEN** the verifier SHALL return `SignatureVerificationResult.expired`
- **THEN** the verifier SHALL return `SignatureVerificationResult.valid` for a request within the window

#### Scenario: Acoustic deduplication unit test
- **WHEN** a unit test presents two track fingerprints that are within the similarity threshold
- **THEN** the deduplicator SHALL return a merge decision with a stored provenance record
- **WHEN** the merge is undone
- **THEN** both tracks SHALL be restored to separate entries with their original metadata

### Requirement: Widget tests cover all primary interactive components
Widget tests SHALL exist for: player controls (play/pause, skip, seek, shuffle, repeat), social feed rendering (list items, avatar display, activity type icons), library list views (all songs, albums, artists), and all four network-state components (`BufferingWidget`, `HostOfflineWidget`, `StreamFailedPlayingLocalWidget`, `PartialLibraryWidget`).

#### Scenario: Play/pause widget test
- **WHEN** a widget test pumps the `PlayerControls` widget with a paused state
- **THEN** the play icon SHALL be visible
- **WHEN** the play button is tapped
- **THEN** the state SHALL transition to playing and the pause icon SHALL be visible

#### Scenario: Network-state widget test
- **WHEN** a widget test pumps `HostOfflineWidget` with `displayName: "Maya"` and `lastSeenAt: DateTime.now()`
- **THEN** the widget SHALL display "Maya" as the host name
- **THEN** the widget SHALL NOT display a raw `@user@node` handle
- **THEN** no exception SHALL be thrown

### Requirement: Integration tests validate the full federation round-trip including host-drop fallback
Integration tests SHALL use an in-process two-node harness (`NightingaleNode` with in-memory Drift and stubbed HTTP transport). Tests SHALL cover: publishing a `Listen` activity from node A and receiving it on node B; streaming audio from node A to node B; node A dropping offline mid-stream and node B falling back to cache. All tests SHALL run without device infrastructure and complete in under 60 s.

#### Scenario: Listen activity round-trip
- **WHEN** node A publishes a `Listen` activity via the in-process harness
- **THEN** node B's inbox SHALL receive the activity within the test's synchronous flush
- **THEN** node B's social feed store SHALL contain the `Listen` event from node A

#### Scenario: Host-drop fallback during streaming
- **WHEN** node B begins streaming a track from node A's library via the in-process harness
- **THEN** if node A is dropped from the harness mid-stream
- **THEN** node B's playback engine SHALL detect the failure and fall back to the local cache copy
- **THEN** the `StreamFailedPlayingLocalWidget` SHALL be visible in node B's Now Playing state

#### Scenario: Replay-protection integration test
- **WHEN** the in-process harness delivers a signed activity to node B's inbox twice
- **THEN** the second delivery SHALL be rejected with a replay-protection error
- **THEN** node B's inbox SHALL contain exactly one copy of the activity
