## Why

Nightingale is a federated music player where each app is a node on the network. Phases 1–3 established the local player, design system, node identity, ActivityPub federation core, and moderation defenses. Phase 4 is the inflection point where the app becomes a true network participant: each node publishes its library to the fediverse, discovers other nodes' libraries, and streams audio from peers when they are reachable. Without Phase 4, Nightingale is just a local music player with an identity; with it, the product thesis — "federated music player" — is realized.

## What Changes

- **Library Publishing**: Nodes publish their library metadata (tracks, albums, artists, artwork) as ActivityPub Collections. Users control what is shared (full library, selected playlists, or nothing). Privacy levels (public, followers-only, private) are enforced at the node level on every request.
- **Best-Effort Audio Streaming**: Stream audio from any currently reachable node. When a host is offline, fall back cleanly (cache, alternate source, or local copy) rather than failing. The playback engine already supports remote streams from Phase 2; Phase 4 wires the federation layer into that path.
- **Subscribing / Following**: Follow any actor to subscribe to their library activity. Fetch and cache remote library Collections so users can browse other libraries even when hosts are offline.
- **Listening Activities**: Publish `Listen` activities to the network so followers see what the user is playing. These become recommendation signals for Phase 6.
- **Acoustic Fingerprinting & Deduplication**: Use Chromaprint / AcoustID to deduplicate tracks across the network. Metadata matching is insufficient — "artist + title + duration" both over-merges and under-merges. Fingerprinting is the data-quality backbone of the recommendation engine.
- **Authenticated Streaming**: Hosting nodes verify requesting node identity via HTTP Signatures (already implemented in Phase 3) before serving audio bytes.
- **Relay Fallback**: When direct P2P streaming fails, attempt relay-assisted delivery (leveraging the relay client from Phase 3).
- **Debug Overlay — Phase 4 Tab**: Library sync inspector, stream inspector (active streams, host reachability, bytes received, cache hits, buffer health, relay vs. direct), incoming library feed viewer, deduplication trace viewer.

## Capabilities

### New Capabilities
- `library-publishing`: Publishing local library metadata as ActivityPub Collections with privacy controls
- `audio-streaming`: Best-effort audio streaming from remote nodes with caching, authentication, and fallback
- `social-subscribing`: Following actors, fetching remote libraries, and caching them for offline browsing
- `listening-activities`: Publishing `Listen` activities to the network and ingesting them as signals
- `acoustic-deduplication`: Chromaprint/AcoustID fingerprinting for cross-node track deduplication with reversible merges
- `stream-authentication`: HTTP Signature-based authentication for audio stream requests
- `relay-streaming`: Relay-assisted streaming fallback when direct P2P fails

### Modified Capabilities
- `playback-engine`: Extend to resolve federated track references to remote stream sources (currently only supports local files and generic URIs)
- `activitypub-outbox`: Extend to include `Listen` activities and library Collection objects in the outbox
- `activitypub-inbox`: Extend to process `Listen` activities and library subscription/follow activities
- `debug-overlay`: Add Phase 4 tabs (library sync, stream, deduplication trace)

## Impact

- **New dependencies**: `chromaprint` / `acoustid` client library for fingerprinting; `just_audio` already supports remote streams but may need cache configuration tuning
- **Database schema**: New tables for remote libraries, cached audio, listening activity signals, fingerprint index, merge provenance
- **Network layer**: New endpoints for audio streaming (`/stream/<track-id>`), library Collection serving, and authenticated access control
- **Playback engine**: `PlaybackEngine._resolveSource()` must handle `RemoteAudioSource` with node reachability checks and cache fallback
- **UI**: New screens for browsing remote libraries, following users, viewing network activity feed, and stream status indicators
- **Security**: Every audio stream request is authenticated via HTTP Signatures; followers-only tracks verified against followers collection
