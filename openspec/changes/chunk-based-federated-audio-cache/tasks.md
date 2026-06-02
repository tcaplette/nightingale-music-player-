## 1. Database Schema

- [x] 1.1 Add `chunks` Drift table with columns: `hash` (BLOB PK), `data` (BLOB), `size_bytes` (int), `last_accessed` (DateTime), `is_pinned` (bool)
- [x] 1.2 Add `chunk_manifests` Drift table with columns: `track_id` (int), `source_actor_url` (text), `chunk_hashes` (JSON text array), `total_size_bytes` (int), `fetched_at` (DateTime), compound PK on (track_id, source_actor_url)
- [x] 1.3 Write Drift migration to add both tables at the next schema version
- [x] 1.4 Register both tables in `AppDatabase` and regenerate Drift code

## 2. ChunkCacheManager

- [x] 2.1 Create `lib/features/federation/streaming/chunk_cache_manager.dart` with `writeChunk(hash, data)` — inserts or ignores on conflict, updates `last_accessed`
- [x] 2.2 Implement `readChunk(hash)` — returns bytes or null, updates `last_accessed` on hit
- [x] 2.3 Implement `pinChunk(hash)` and `unpinChunk(hash)` — set `is_pinned` flag
- [x] 2.4 Implement `setMaxSize(bytes)` and `_ensureSpace(neededBytes)` — LRU eviction of unpinned chunks; throw `InsufficientCacheSpaceException` if all candidates are pinned
- [x] 2.5 Write unit tests covering: write/read round-trip, idempotent write, eviction order, pin protection, size cap enforcement

## 3. ChunkManifest Model and Repository

- [x] 3.1 Create `lib/features/federation/streaming/chunk_manifest.dart` — immutable model with `trackId`, `sourceActorUrl`, `chunkHashes` (List<String>), `totalSizeBytes`, `fetchedAt`
- [x] 3.2 Create `ChunkManifestRepository` with `saveManifest(manifest)`, `getManifest(trackId, sourceActorUrl)`, `deleteManifest(trackId, sourceActorUrl)`
- [x] 3.3 Implement chunk-splitting helper `ChunkSplitter.split(bytes)` → `List<({String hash, Uint8List data})>` using 512 KB fixed size and SHA-256 via the `crypto` package
- [x] 3.4 Add cascade delete logic: after any chunk eviction, delete manifests where all referenced hashes are gone from the `chunks` table
- [x] 3.5 Write unit tests for: manifest round-trip, split produces correct chunk count and hashes, partial eviction preserves manifest, full eviction removes manifest

## 4. ChunkStreamAssembler

- [x] 4.1 Create `lib/features/federation/streaming/chunk_stream_assembler.dart` extending `just_audio`'s `StreamAudioSource`
- [x] 4.2 Implement `request(start, end)` — compute chunk index range from byte offsets using manifest, trim boundary bytes, return `StreamAudioResponse` with assembled `Stream<List<int>>`
- [x] 4.3 Implement prefetch: when streaming chunk N, eagerly load chunks N+1 and N+2 into a memory buffer; drop chunks older than N-1 from the buffer
- [x] 4.4 Implement seek handling: on a new `request(start)` call, discard buffered chunks outside the new window and reset the prefetch cursor
- [x] 4.5 Implement on-demand fetch: if a required chunk is missing from `ChunkCacheManager`, call `StreamResolver.resolveRemoteTrack` for that specific chunk hash, write to cache, then stream
- [x] 4.6 Write unit tests for: byte-range spanning a chunk boundary, full-file request, forward seek discards old chunks, missing chunk triggers on-demand fetch, fetch failure emits stream error

## 5. Chunk Endpoint (Swarming Server-Side)

- [x] 5.1 Create `lib/features/federation/serving/chunk_handler.dart` — reads hash from route param, checks `SeedingPowerPolicy.canSeed()`, verifies HTTP Signature, enforces sharing scope, reads chunk from `ChunkCacheManager`, returns 200/404/403/503 as appropriate
- [x] 5.2 Register `GET /chunks/:hash` route in `lib/core/http_server/federation_router.dart`
- [x] 5.3 Write integration tests for: authenticated follower receives chunk bytes, unknown hash returns 404, anonymous request on followers-only returns 403, `canSeed() == false` returns 503 with `Retry-After: 60`

## 6. StreamResolver — Chunk-Aware Peer Fetching

- [x] 6.1 Extend `StreamResolver.resolveRemoteTrack` to check for a `ChunkManifest` after the direct-stream probe; if a manifest exists and all chunks are present, return the assembler source
- [x] 6.2 Add `_fetchMissingChunks(manifest, actorUrl)` — iterates manifest hashes, requests any missing ones via signed `GET /chunks/{hash}` from the source node, writes to `ChunkCacheManager`
- [x] 6.3 On 503 from chunk endpoint, fall back to direct HTTP stream of the full track; on full unavailability, return `StreamPath.unavailable`
- [x] 6.4 Ensure all outbound `/chunks/{hash}` requests are signed using `HttpSignatureService`
- [x] 6.5 Write unit tests for: full manifest hit returns assembler, partial manifest triggers peer fetch, peer 503 falls back to direct stream, peer unreachable returns unavailable

## 7. SeedingPowerPolicy

- [x] 7.1 Add `battery_plus` and `connectivity_plus` to `pubspec.yaml`
- [x] 7.2 Create `lib/features/federation/streaming/seeding_power_policy.dart` — `canSeed()` checks: toggle enabled AND charging AND Wi-Fi AND battery level ≥ threshold
- [x] 7.3 Persist `seedingEnabled` (bool) and `seedingBatteryThreshold` (int, 0–100) in user settings via the existing settings repository
- [x] 7.4 Expose `updateThreshold(int percent)` and `setSeedingEnabled(bool)` methods; both take effect immediately without app restart
- [x] 7.5 Write unit tests for: all permutations of charging/Wi-Fi/battery/toggle, threshold update takes effect on next `canSeed()` call

## 8. Settings UI

- [x] 8.1 Add a "Network Sharing" section to `lib/features/settings/screens/settings_screen.dart` with the seeding on/off toggle and battery threshold slider
- [x] 8.2 Add a status chip that reads from `SeedingPowerPolicy` and displays one of: "Active", "Paused – charging required", "Paused – Wi-Fi required", "Paused – battery low", or "Disabled"
- [x] 8.3 Wire toggle and slider changes to `SeedingPowerPolicy.setSeedingEnabled()` and `updateThreshold()`

## 9. Service Locator and Integration

- [x] 9.1 Register `ChunkCacheManager`, `ChunkManifestRepository`, `ChunkStreamAssembler` (factory), and `SeedingPowerPolicy` in `lib/core/di/service_locator.dart`
- [x] 9.2 Keep `AudioCacheManager` registered alongside `ChunkCacheManager` during the migration period; `StreamResolver` uses chunk path when manifest exists, legacy path otherwise
- [x] 9.3 Wire `PlaybackEngine` to use `ChunkStreamAssembler` for remote tracks that have a manifest, falling back to URI source for legacy cached files and direct streams

## 10. Cleanup (post-validation)

- [ ] 10.1 Remove `AudioCacheManager` registration from the service locator once chunk path is validated in production
- [ ] 10.2 Write a Drift migration to drop the old `audio_cache` table
- [ ] 10.3 Delete `lib/features/federation/streaming/audio_cache_manager.dart`
