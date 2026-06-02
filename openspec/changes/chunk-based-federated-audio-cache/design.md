## Context

Nightingale nodes communicate over ActivityPub, serve audio via an embedded `shelf` HTTP server on port 7777, and cache remote tracks using `AudioCacheManager` — a service that downloads whole audio files to the device filesystem and records their paths in a Drift SQLite table (`audio_cache`). `StreamResolver` uses a direct-stream → local-cache → unavailable fallback chain; `stream_handler` serves the local library over HTTP with range-request support.

The problem: cached files are whole-track blobs on the filesystem, identified by `trackId + sourceActorUrl`, with no content-addressing and no way to share them back to the network. The architecture change replaces this with a chunk-based, hash-addressed cache that makes every cached track a seedable asset.

Key constraints:
- `just_audio` requires either a URI or a `StreamAudioSource` — it cannot consume an arbitrary Dart `Stream<List<int>>` directly without a custom source adapter.
- Flutter/Dart on Android and iOS has no persistent background execution beyond platform-specific job schedulers; seeding must be opportunistic.
- The Drift database already holds the federation data model; extending it for chunk storage avoids introducing a second storage dependency.
- The existing 500 MB LRU cap, pin/unpin mechanism, and `StreamResolver` fallback chain must survive the migration unchanged from the perspective of callers.

## Goals / Non-Goals

**Goals:**
- Replace whole-file cache storage with a content-addressed chunk store (SQLite BLOBs, keyed by SHA-256).
- Introduce a `ChunkManifest` model that binds an ordered chunk list to a track.
- Enable nodes to serve cached chunks (not just locally owned tracks) via a new `/chunks/{hash}` HTTP endpoint.
- Extend `StreamResolver` to fetch missing chunks from reachable peers before declaring a track unavailable.
- Provide a `ChunkStreamAssembler` that feeds assembled chunk sequences into `just_audio`'s `StreamAudioSource`.
- Gate all outbound chunk-serving on charging + Wi-Fi via a `SeedingPowerPolicy` service with a user-visible toggle.
- Preserve the public API surface of `StreamResolver` and the pin/eviction semantics of the current cache.

**Non-Goals:**
- Full BitTorrent-compatible protocol or tracker infrastructure.
- Serving chunks to unauthenticated anonymous peers (seeding respects the same privacy/follower scope as the library).
- Encrypting cached chunk data at rest (out of scope; a separate hardening concern).
- Exposing cached chunks to the OS media scanner or other apps.
- Variable-size (rolling-hash) chunking — fixed-size simplifies seeking and is sufficient.

## Decisions

### D1 — Fixed chunk size: 512 KB

**Decision:** Split tracks into 512 KB fixed-size chunks (last chunk may be smaller).

**Rationale:** 512 KB balances seek granularity against SQLite transaction overhead. At 128 kbps MP3, 512 KB ≈ 32 seconds — fine-grained enough for most seek targets without creating thousands of rows per track. 256 KB would double the row count and transaction frequency for identical audio; 1 MB would make seeking coarser and increase the "wasted" fetch on a seek jump.

**Alternatives considered:**
- *256 KB*: better granularity, but roughly 2× the DB I/O and index size.
- *1 MB*: fewer rows, but a seek near a chunk boundary can require fetching ~1 MB of unwanted data.
- *Content-defined chunking (rolling hash)*: deduplication across tracks with similar audio segments; significantly more complex to implement and marginal benefit for a music app where track content is fixed.

---

### D2 — Store chunks as SQLite BLOBs in Drift

**Decision:** Add two new Drift tables — `chunks` (hash BLOB PK, data BLOB, size, last_accessed, is_pinned) and `chunk_manifests` (track_id, source_actor_url, ordered JSON array of hashes, total_size, fetched_at).

**Rationale:** The existing Drift database already holds all federation state. Keeping chunks in the same database gives transactional consistency between manifest writes and chunk writes, uses the battle-tested WAL mode already configured, and avoids a second storage abstraction. SQLite BLOB I/O is well-understood on both Android and iOS and handles gigabyte-scale caches without issue.

**Alternatives considered:**
- *Files named by hex hash in a hidden directory*: avoids BLOB overhead but reintroduces individual files on the filesystem — the problem we're trying to solve.
- *A separate SQLite database for chunks*: cleaner separation but requires managing two Drift databases and cross-DB transactions.
- *LevelDB / Hive*: good key-value stores but add new native dependencies and lose Drift's type-safe query layer.

---

### D3 — `ChunkStreamAssembler` extends `just_audio`'s `StreamAudioSource`

**Decision:** Implement a `ChunkStreamAssembler` that extends `StreamAudioSource` and overrides `request(start, end)` to read the required chunk range from `ChunkCacheManager`, assembling a `Stream<List<int>>` for the requested byte window.

**Rationale:** `StreamAudioSource` is `just_audio`'s official extension point for custom byte-stream sources. It receives `(start, end)` byte range requests (matching HTTP 206 semantics) and expects a `StreamAudioResponse`. This maps cleanly onto the chunk model: convert `start` → chunk index, fetch that chunk and subsequent chunks, trim the boundary bytes, and stream. This is the correct integration point — using a URI source for a local chunk store would require exposing a local HTTP server just to talk to ourselves.

**Alternatives considered:**
- *Temporary file assembly*: write all chunks to a temp file before playing. Adds latency, writes every byte twice, and defeats the memory-only playback goal.
- *`LockCachingAudioSource`*: `just_audio_cache` plugin — wraps a URI source with file caching. Doesn't help for chunk-based storage and would conflict with our cache layer.

---

### D4 — New `/chunks/{hash}` HTTP endpoint for peer serving

**Decision:** Add a `GET /chunks/{hash}` route to `FederationRouter`. The handler reads the chunk from `ChunkCacheManager` and streams the raw bytes, subject to the same privacy/follower scope check as `/stream/{trackId}`.

**Rationale:** This is the minimal addition needed for swarming. A peer that has the manifest for a track (fetched via the library collection) can request individual chunks it is missing. Using the hash as the route parameter makes the endpoint naturally content-addressed and idempotent.

**Alternatives considered:**
- *Serving chunks only as part of the existing `/stream/{trackId}` range requests*: would require the serving node to reassemble the full file, negating the chunk architecture.
- *A separate swarming protocol (BitTorrent, IPFS)*: large dependency, out of scope for this change.

---

### D5 — `SeedingPowerPolicy` as a singleton service, checked before each outbound chunk response

**Decision:** A `SeedingPowerPolicy` service wraps `battery_plus` and `connectivity_plus`. It exposes a single `canSeed()` → `bool` method. `stream_handler`'s `/chunks/{hash}` handler calls `canSeed()` at request time; if false, it returns HTTP 503 (Service Unavailable, retry-able) rather than 403 (forbidden). Battery threshold and the on/off toggle are persisted as user settings.

**Rationale:** Checking at request time (rather than disabling the route) lets the policy change dynamically as the device is plugged in/out without restarting the server. 503 (with a `Retry-After` hint) is semantically correct — the resource exists but the node is conserving resources — and allows the requesting node's `StreamResolver` to try a different peer or fall back gracefully.

**Alternatives considered:**
- *Checking in a background isolate and toggling a flag*: more complex, still needs a check at request time to be race-free.
- *Returning 403*: semantically wrong (not a permissions issue) and would prevent retry from the requesting side.

---

### D6 — Migration: write manifests on first cache hit, not upfront

**Decision:** No bulk migration. Existing `audio_cache` entries are left intact. When `StreamResolver` resolves a track, if no `ChunkManifest` exists, it falls through to the old `AudioCacheManager` path (whole-file cache or direct stream). New downloads are chunked automatically. Old cached files are evicted by LRU as space is needed.

**Rationale:** A bulk migration would require re-reading every cached file, re-chunking, and re-writing — expensive on device and risky if interrupted. Lazy migration (on first access) spreads the cost, keeps the app functional during the transition, and lets the old `audio_cache` table drain naturally.

## Risks / Trade-offs

**[SQLite BLOB write amplification]** → Storing large BLOBs in SQLite can cause write amplification as WAL pages are copied. Mitigation: use a chunk size (512 KB) large enough that the page-copy overhead is proportional to a small number of 4 KB WAL pages per chunk; vacuum only on idle + charging.

**[Seek latency at chunk boundaries]** → A seek that lands near a chunk boundary may require fetching the next chunk before audio resumes. Mitigation: `ChunkStreamAssembler` prefetches the next 2 chunks ahead of the current playback position.

**[Memory pressure from in-memory assembly]** → Holding multiple 512 KB chunks in memory while assembling. Mitigation: the assembler maintains at most 3 chunks in memory at once (current + 2 prefetch); older chunks are dropped from memory once the `StreamAudioSource` consumer has read past them.

**[Peer chunk requests when seeding is off]** → A node may fail to seed due to power policy mid-playlist, causing the requesting node's assembler to stall. Mitigation: `StreamResolver` on the requesting side treats a 503 from a chunk endpoint as "peer temporarily unavailable" and falls back to direct stream or another peer if available.

**[Database size]** → A 500 MB chunk store with 512 KB chunks = ~1000 rows. SQLite handles this comfortably. The existing 500 MB cap is enforced by `ChunkCacheManager`'s LRU eviction across all stored chunks.

**[`battery_plus` / `connectivity_plus` permissions]** → Require `ACCESS_NETWORK_STATE` (Android, already present) and no special iOS entitlement. Battery state requires no special permission on either platform.

## Migration Plan

1. Add `chunks` and `chunk_manifests` tables to the Drift schema via a new migration version.
2. Register `ChunkCacheManager`, `ChunkStreamAssembler`, and `SeedingPowerPolicy` in the service locator alongside (not replacing) the existing `AudioCacheManager` initially.
3. Update `StreamResolver` to prefer the chunk path when a manifest exists, falling back to the legacy file path if not.
4. Register `/chunks/{hash}` in `FederationRouter`.
5. After validation, remove `AudioCacheManager` registration from the service locator and delete the old `audio_cache` table in a follow-up migration.

**Rollback:** Because the chunk path is additive and the legacy path remains active until step 5, rolling back is a matter of removing the new service registrations and route — no data loss.

## Open Questions

- **Chunk hash scope:** Should the manifest hash be over the raw audio bytes, or should it include track metadata? Raw bytes preferred (enables cross-track deduplication for identical audio), but needs a decision before `ChunkManifest` schema is finalised.
- **Seeding scope:** Should nodes seed chunks to any authenticated peer, or only to followers? Current proposal defaults to matching the library sharing scope (followers-only if the library is followers-only). Confirm this is the desired behaviour.
- **Prefetch depth:** 2 chunks ahead is a guess. Should this be configurable or tied to network speed detection?
