## ADDED Requirements

### Requirement: Nodes expose a chunk endpoint for peer serving
The system SHALL serve individual chunks from `ChunkCacheManager` via a `GET /chunks/{hash}` HTTP endpoint, subject to the same HTTP Signature verification and library sharing scope rules as the existing `/stream/{trackId}` endpoint.

#### Scenario: Chunk served to an authenticated follower
- **WHEN** a verified follower sends `GET /chunks/{hash}` for a hash present in the local `ChunkCacheManager`
- **THEN** the server returns HTTP 200 with the raw chunk bytes and `Content-Type: application/octet-stream`

#### Scenario: Chunk request for unknown hash returns 404
- **WHEN** `GET /chunks/{hash}` is received for a hash not in `ChunkCacheManager`
- **THEN** the server returns HTTP 404

#### Scenario: Anonymous request for followers-only chunk is rejected
- **WHEN** a request with no HTTP Signature is received for a chunk and the library scope is `followersOnly`
- **THEN** the server returns HTTP 403

#### Scenario: Seeding paused by power policy returns 503
- **WHEN** `GET /chunks/{hash}` is received and `SeedingPowerPolicy.canSeed()` returns false
- **THEN** the server returns HTTP 503 with a `Retry-After: 60` header

### Requirement: StreamResolver fetches missing chunks from peers before failing
The system SHALL extend `StreamResolver` to attempt chunk-by-chunk peer fetching when a track's manifest exists but one or more chunks are absent from the local `ChunkCacheManager`. Chunks are requested from any reachable node that is known to hold the source track.

#### Scenario: Missing chunks fetched from source node
- **WHEN** `StreamResolver.resolveRemoteTrack` is called, a manifest exists, but chunk index 3 is missing
- **THEN** `StreamResolver` requests `GET /chunks/{hash3}` from the source node, writes the received bytes to `ChunkCacheManager`, and proceeds with assembly

#### Scenario: Peer unavailable falls back to direct stream
- **WHEN** a missing chunk cannot be fetched because the source node returns 503 or is unreachable
- **THEN** `StreamResolver` falls back to a direct HTTP stream of the full track from the source node if reachable, otherwise returns `StreamPath.unavailable`

### Requirement: Chunk requests are signed with HTTP Signature
The system SHALL sign all outbound `GET /chunks/{hash}` requests using the local node's Ed25519 key, matching the signing behaviour of existing federation requests.

#### Scenario: Outbound chunk request includes Signature header
- **WHEN** `StreamResolver` makes a `GET /chunks/{hash}` request to a remote node
- **THEN** the request includes a valid `Signature` header signed by the local node's private key

### Requirement: Nodes only seed chunks they legitimately hold
The system SHALL only serve a chunk via `/chunks/{hash}` if that hash exists in the local `ChunkCacheManager`. A node SHALL NOT proxy chunk requests to other peers.

#### Scenario: Proxied chunk request is not forwarded
- **WHEN** a chunk is requested that the node does not have in its local cache
- **THEN** the node returns HTTP 404 and does NOT attempt to fetch the chunk from another peer on the requester's behalf
