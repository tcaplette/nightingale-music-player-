## ADDED Requirements

### Requirement: Local signal capture
The system SHALL record a signal event every time the user plays, skips, saves, likes, or adds a track to a playlist. Each event SHALL store: track identity (acoustic fingerprint hash), event type, timestamp (UTC), and the weight assigned to that event type at time of recording.

#### Scenario: Play event recorded
- **WHEN** a track plays for more than 30 seconds
- **THEN** a play signal event is written to the signal store with type `play`, the current UTC timestamp, and the configured play weight

#### Scenario: Skip event recorded
- **WHEN** a track is skipped before 30 seconds have elapsed
- **THEN** a skip signal event is written to the signal store with type `skip`, the current UTC timestamp, and the configured skip weight (negative)

#### Scenario: Save event recorded
- **WHEN** the user saves a track to their library from any surface (Discover screen, social feed, remote library)
- **THEN** a save signal event is written to the signal store with type `save`, the current UTC timestamp, and the configured save weight

#### Scenario: Like event recorded
- **WHEN** the user sends a Like activity to a track
- **THEN** a like signal event is written to the signal store with type `like`, the current UTC timestamp, and the configured like weight

#### Scenario: Playlist add event recorded
- **WHEN** the user adds a track to any playlist
- **THEN** a playlist-add signal event is written to the signal store with type `playlist_add`, the current UTC timestamp, and the configured playlist-add weight

---

### Requirement: Network signal ingestion
The system SHALL process incoming Listen, Like, Save, and Announce activities from followed nodes and store them as network signal events. Each network signal event SHALL record: source actor ID, track identity, event type, timestamp, and the weight assigned to network signals of that type.

#### Scenario: Inbound Listen activity ingested as signal
- **WHEN** a Listen activity arrives from a followed node
- **THEN** a network signal event is written with type `network_listen`, source actor ID, track fingerprint, and the current UTC timestamp

#### Scenario: Inbound Like activity ingested as signal
- **WHEN** a Like activity arrives from a followed node targeting a track
- **THEN** a network signal event is written with type `network_like`, source actor ID, and track fingerprint

#### Scenario: Activities from blocked or muted actors are excluded
- **WHEN** a Listen or Like activity arrives from an actor the user has blocked or muted
- **THEN** no signal event is written for that activity

---

### Requirement: Taste profile aggregation
The system SHALL maintain a per-track taste score for the local user, computed by summing the weights of all local signal events for that track. The taste profile SHALL be structured as a queryable table, not a flat blob, so the recommendation engine can perform similarity comparisons.

#### Scenario: Score updated on new event
- **WHEN** a new local signal event is written
- **THEN** the taste score for the corresponding track is updated by adding the event's weight to the existing score

#### Scenario: Negative score from skips
- **WHEN** the user repeatedly skips a track
- **THEN** the track's taste score MAY become negative, and the recommendation engine SHALL exclude tracks with scores below zero from results

---

### Requirement: Taste profile encrypted at rest
The taste profile table (signal events + aggregated scores) SHALL be encrypted at rest using an AES-256 key stored exclusively in the platform secure enclave (iOS Keychain / Android Keystore). The key SHALL never appear in plaintext in app storage or be transmitted over the network.

#### Scenario: Signal store inaccessible without key
- **WHEN** the app attempts to read signal data before the taste profile key has been loaded from the secure enclave
- **THEN** the read SHALL fail with a clear error; the app SHALL NOT fall back to unencrypted access

#### Scenario: First-launch key generation
- **WHEN** no taste profile key exists in the secure enclave on app launch
- **THEN** the app generates a new AES-256 key, stores it in the secure enclave, and initializes an empty encrypted signal store

---

### Requirement: Signal data never leaves the device
The signal store and taste profile SHALL NOT be transmitted to any remote node, server, or relay unless the user explicitly triggers a share action (future feature). No background sync, no telemetry, no passive upload.

#### Scenario: Signal data absent from outbox
- **WHEN** the ActivityPub outbox is serialized for any request
- **THEN** no signal events or taste scores are included in the outbox payload

#### Scenario: Signal data absent from federation diagnostics
- **WHEN** the federation debug inspector logs outgoing HTTP requests
- **THEN** no signal or taste profile data appears in any logged payload
