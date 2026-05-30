## ADDED Requirements

### Requirement: Audio streamed from remote nodes
The playback engine SHALL resolve a federated track reference to a stream URL on a hosting node and play it via `just_audio`. When the host is unreachable, the engine SHALL fall back to a cached copy or skip the track.

#### Scenario: Streaming from reachable host
- **WHEN** the user selects a remote track to play
- **AND** the hosting node is reachable
- **THEN** the playback engine streams audio from the remote node

#### Scenario: Host unreachable with cached copy
- **WHEN** the user selects a remote track to play
- **AND** the hosting node is unreachable
- **AND** a cached copy exists locally
- **THEN** the playback engine plays the cached copy

#### Scenario: Host unreachable without cache
- **WHEN** the user selects a remote track to play
- **AND** the hosting node is unreachable
- **AND** no cached copy exists
- **THEN** the playback engine skips the track and surfaces "Host offline" state to the user

### Requirement: Aggressive local caching
The app SHALL cache recently played and likely-to-be-played remote audio locally. Cached files SHALL be stored on disk with LRU eviction. The cache SHALL have a configurable maximum size.

#### Scenario: Cache hit
- **WHEN** a remote track is played
- **AND** the track exists in the local cache
- **THEN** playback starts immediately from the cached file

#### Scenario: Cache eviction
- **WHEN** the cache exceeds its maximum size
- **THEN** the least-recently-accessed cached file is deleted
- **AND** the cache metadata is updated

#### Scenario: Pin active playback
- **WHEN** a cached file is currently being played
- **THEN** the file is marked as "in-use" and excluded from eviction

### Requirement: Adaptive buffering
The playback engine SHALL use adaptive buffering for remote streams to handle variable network conditions.

#### Scenario: Slow network
- **WHEN** network throughput drops below the audio bitrate
- **THEN** the playback engine increases buffer size and surfaces "Buffering" state

#### Scenario: Network recovery
- **WHEN** network throughput recovers
- **THEN** the playback engine resumes normal playback and clears buffering state

### Requirement: Stream URL resolution
The app SHALL resolve a federated track reference (actor URL + track ID) to a stream URL by fetching the track's `Audio` object from the hosting node's library Collection.

#### Scenario: Resolve stream URL
- **WHEN** the user selects a remote track
- **THEN** the app fetches the track's `Audio` object from the hosting node
- **AND** extracts the `url` field as the stream endpoint
