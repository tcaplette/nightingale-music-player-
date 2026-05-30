## ADDED Requirements

### Requirement: Local playback continues uninterrupted when offline
When the device loses network connectivity, any in-progress local playback SHALL continue without interruption. Queue management (play, pause, skip, seek, shuffle, repeat) SHALL remain fully functional. Remote tracks that are cached locally SHALL be playable; remote tracks that are not cached SHALL show a `HostOfflineWidget` and be skipped in shuffle.

#### Scenario: Network drops during local track playback
- **WHEN** the device loses connectivity while playing a locally stored track
- **THEN** playback SHALL continue without interruption
- **THEN** the UI SHALL NOT show an error, spinner, or degraded-state overlay for this track

#### Scenario: Uncached remote track encountered while offline
- **WHEN** the queue reaches a remote track with no local cache and the device is offline
- **THEN** the track SHALL be skipped automatically with a non-alarming status message
- **THEN** playback SHALL advance to the next available track without stalling

### Requirement: Federated activities are queued durably when offline
When the device is offline, outgoing ActivityPub activities (Listen, Like, Share, Follow, Announce) SHALL be written to a durable `ActivityQueue` table in Drift rather than dropped. The queue SHALL flush in FIFO order when connectivity is restored. The queue SHALL survive app termination and device restart.

#### Scenario: Like activity queued while offline
- **WHEN** the user likes a track while offline
- **THEN** the `Like` activity SHALL be written to the `ActivityQueue` table
- **THEN** the UI SHALL optimistically reflect the like
- **THEN** on reconnect, the activity SHALL be delivered to the target node and removed from the queue

#### Scenario: Queue flushes on reconnect
- **WHEN** the device regains network connectivity
- **THEN** the `OfflineModeCoordinator` SHALL begin flushing the `ActivityQueue` in FIFO order
- **THEN** each delivered activity SHALL be removed from the queue on HTTP 2xx from the recipient node
- **THEN** failed deliveries SHALL be retried with exponential backoff up to 3 attempts before being marked as `dead`

#### Scenario: Queue survives app restart
- **WHEN** the app is terminated while activities are in the queue and then relaunched
- **THEN** the `ActivityQueue` table SHALL contain all undelivered activities from the prior session
- **THEN** the queue SHALL begin flushing automatically when the next online state is detected

### Requirement: Graceful degradation cascades through available sources before failing
When a remote track is requested and the hosting node is unreachable, the playback engine SHALL attempt sources in order: (1) local cache hit, (2) relay path, (3) alternate node hosting the same track (by fingerprint match). Only if all three paths fail SHALL the engine surface a failure state and move to the next queue item.

#### Scenario: Cache hit on offline host
- **WHEN** the user plays a remote track and the hosting node is offline but the track is in the local cache
- **THEN** playback SHALL start from the cache with no buffering delay
- **THEN** the Now Playing screen SHALL show `StreamFailedPlayingLocalWidget` to indicate the source

#### Scenario: All fallback paths fail
- **WHEN** a remote track has no local cache, no relay path, and no alternate host
- **THEN** the track SHALL be marked unavailable in the queue
- **THEN** `HostOfflineWidget` SHALL be shown on the Now Playing screen
- **THEN** `HapticFeedback.heavyImpact()` SHALL fire once
- **THEN** the app SHALL advance to the next track automatically after a 3 s pause

### Requirement: Library database corruption is detected and recovered on startup
On every app launch, the app SHALL run `PRAGMA integrity_check` against the Drift/SQLite library database. A failure SHALL trigger a staged recovery: (1) WAL checkpoint and database re-open; (2) index rebuild while preserving track rows; (3) if unrecoverable, full library clear and re-scan. The user SHALL be notified of any recovery action that alters or clears library data.

#### Scenario: Integrity check passes
- **WHEN** the app launches and `PRAGMA integrity_check` returns `ok`
- **THEN** startup SHALL proceed normally with no visible recovery UI

#### Scenario: Index corruption recovered silently
- **WHEN** the app launches and integrity check fails but track rows are intact
- **THEN** the app SHALL rebuild indices and proceed to the main UI
- **THEN** a non-intrusive toast or status message SHALL inform the user that the library was repaired

#### Scenario: Unrecoverable corruption triggers re-scan with user notification
- **WHEN** the app launches and the database is fully unrecoverable
- **THEN** the app SHALL show a modal informing the user that the library needs to be rebuilt
- **THEN** after user acknowledgment, the app SHALL clear the database and initiate a fresh library scan
- **THEN** the user SHALL NOT lose any data that was not already in the local database (remote library caches are re-fetched after reconnect)
