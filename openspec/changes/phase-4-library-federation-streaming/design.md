## Context

Nightingale is a Flutter app using Riverpod for state management, Drift (SQLite) for local persistence, and an embedded shelf HTTP server for ActivityPub federation. Phase 3 completed the node identity layer (Ed25519 key generation, secure enclave storage, HTTP Signatures, actor resolution, moderation, rate limiting, and relay-assisted delivery). The playback engine (`just_audio` + `just_audio_background`) already handles both local files and remote streams through a unified `AudioSource` abstraction.

Phase 4 connects these pieces: the local library becomes publishable, remote libraries become discoverable, and the playback engine's remote-stream path is wired to authenticated, best-effort federation.

## Goals / Non-Goals

**Goals:**
- Publish local library metadata as ActivityPub Collections with user-controlled privacy (public / followers-only / private)
- Stream audio from reachable remote nodes with HTTP Signature authentication
- Cache remote audio aggressively so playback survives host disconnection
- Follow/subscribe to other actors and browse their libraries offline via cached Collections
- Publish `Listen` activities to the network as recommendation signals
- Deduplicate tracks across nodes using Chromaprint/AcoustID fingerprinting
- Provide comprehensive debug tooling for library sync, streaming, and deduplication

**Non-Goals:**
- Guaranteed streaming availability (best-effort only, per the product thesis)
- Real-time sync (collections are fetched on demand, not pushed)
- Transcoding or bitrate adaptation (serve original files only)
- Playlist federation ( playlists are Phase 5)
- Recommendation engine (Phase 6)
- Social interactions beyond follow/unfollow (likes, shares, saves are Phase 5)

## Decisions

### 1. Library Publishing Format: ActivityPub `OrderedCollection` of `Audio` objects
**Rationale**: ActivityPub already defines `Collection` and `Audio` types. Reusing them means any ActivityPub consumer can understand Nightingale libraries without custom parsing. Each track is an `Audio` object with `name`, `artist`, `duration`, and `url` pointing to the stream endpoint. Albums are `OrderedCollection` pages grouping `Audio` objects.

**Alternative considered**: Custom JSON schema — rejected because it breaks federation interoperability.

### 2. Privacy Enforcement at the Node Level, Not the Protocol Level
**Rationale**: The protocol always serves the full collection object; the node filters what goes into it based on the requesting actor's relationship (public = anyone, followers-only = verified follower, private = nothing). This keeps the protocol simple and puts the access-control boundary in one place: the HTTP handler that serves the collection.

**Alternative considered**: Encrypted collections — rejected as overkill for metadata; audio bytes are the sensitive path and are already authenticated per-request.

### 3. Audio Cache: File-system cache with LRU eviction, not database BLOBs
**Rationale**: `just_audio` can stream directly from files. Storing cached audio as files on disk (in the app's cache directory) lets the playback engine treat them as `LocalAudioSource` without modification. LRU eviction keeps cache size bounded. Database tracks cache metadata (original URL, local path, fetched-at, last-accessed, size).

**Alternative considered**: SQLite BLOBs — rejected because `just_audio` cannot stream from memory/BLOBs efficiently on Android.

### 4. Fingerprinting: Chromaprint native bridge via FFI, not platform channels
**Rationale**: Chromaprint is a C library. Using `dart:ffi` to call it directly avoids the latency and complexity of platform channels. The fingerprint is computed once per track at scan time and stored in the database.

**Alternative considered**: Pure-Dart port — rejected because no mature port exists and the C library is well-tested.

### 5. Stream Endpoint: Dedicated `/stream/<track-id>` GET endpoint, not inbox
**Rationale**: Audio streaming is a read operation, not an ActivityPub activity. A dedicated endpoint keeps the semantics clean: the inbox handles activities, `/stream` handles byte delivery. The endpoint accepts an `Authorization` header with an HTTP Signature.

**Alternative considered**: Deliver audio via ActivityPub `Audio` object attachment URLs — rejected because it conflates metadata delivery with byte delivery and makes authentication awkward.

### 6. Deduplication Merges Are Reversible with Stored Provenance
**Rationale**: Bad merges are a data-quality nightmare. Every merge decision records the two fingerprints, the similarity score, and the reason. A merge can be undone without losing data.

**Alternative considered**: Permanent merges — rejected because cross-node metadata quality is unpredictable.

## Risks / Trade-offs

- **[Risk] Chromaprint FFI adds native build complexity** → Mitigation: Use `flutter_rust_bridge` or `ffigen` to generate bindings; test on both Android and iOS CI before merging.
- **[Risk] Cache eviction during active playback** → Mitigation: Pin active playback files (mark as "in-use" in cache metadata); evict only after playback ends.
- **[Risk] Fingerprinting all tracks at scan time slows library import** → Mitigation: Fingerprint asynchronously after scan completes; show progress in UI; skip fingerprinting for tracks already fingerprinted.
- **[Risk] Serving audio from mobile drains battery and data** → Mitigation: Best-effort serving only — the app serves when reachable, but users can disable serving entirely; aggressive cache on the consumer side reduces re-streaming.
- **[Risk] Copyrighted content streaming exposes legal liability** → Mitigation: This is a product-level decision (see ROADMAP.md Content & Licensing Position). The technical layer respects whatever scope is active; Phase 4 does not change the licensing position.

## Migration Plan

1. **Database migration**: Add new tables (`remote_libraries`, `audio_cache`, `listen_activities`, `fingerprints`, `merge_provenance`). Existing tables are untouched.
2. **Feature flag**: All Phase 4 features are gated behind a compile-time or runtime flag so they can be disabled if issues arise.
3. **Backwards compatibility**: Phase 3 nodes that do not implement Phase 4 endpoints are handled gracefully — unreachable endpoints are treated as "host offline" and fallback applies.

## Open Questions

1. What is the maximum cache size? (default: 2GB? user-configurable?)
2. Should the app pre-emptively fetch followed users' libraries in the background, or only on-demand?
3. How often should `Listen` activities be batched vs. sent immediately? (real-time vs. periodic sync)
4. What Chromaprint similarity threshold constitutes a match? (needs empirical testing)
