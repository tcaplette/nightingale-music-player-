## Why

The current `AudioCacheManager` stores remote audio as whole files on disk, referenced by plain filesystem paths. This prevents deduplication across tracks or peers, makes cached files visible outside the app, and means a node can only serve its own local library — cached copies from other nodes sit idle and can never contribute back to the network. The architecture needs to evolve from a passive download cache into an active, peer-contributing chunk store that matches the federated philosophy of the rest of the app.

## What Changes

- **BREAKING** `AudioCacheManager` is replaced by `ChunkCacheManager`: storage moves from individual files to a single SQLite BLOB table keyed by SHA-256 chunk hash.
- A `ChunkManifest` model replaces the flat `trackId → filePath` reference, recording the ordered list of chunk hashes that make up a track.
- The `stream_handler` gains a `/chunks/{hash}` endpoint so nodes can serve individual chunks they hold in their cache — whether originally local or received from a peer.
- `StreamResolver` is extended to attempt chunk-by-chunk peer fetching before declaring a track unavailable, using the manifest as a guide.
- A `ChunkStreamAssembler` adapter sits between `ChunkCacheManager` and `just_audio`, assembling chunks into a contiguous byte stream with prefetch and chunk-boundary-aware seeking.
- A seeding power policy restricts background chunk-serving to charging + Wi-Fi conditions, with a user-configurable battery threshold and a UI toggle in Settings.
- LRU eviction, the 500 MB cap, pin protection, and the `StreamResolver` direct → cache → unavailable fallback chain are all preserved and adapted to operate on chunks rather than files.

## Capabilities

### New Capabilities

- `chunk-store`: Content-addressed SQLite BLOB storage for audio chunks. Replaces file-based `AudioCacheManager`. Handles write, lookup by hash, LRU eviction, size cap, and pin/unpin at the chunk and manifest level.
- `chunk-manifest`: Model and persistence layer for the ordered list of SHA-256 chunk hashes that constitute a track. Acts as the contract between the chunk store, the assembler, and the stream resolver.
- `chunk-swarming`: Nodes serve chunks from their local `ChunkCacheManager` (not just their own library files) via a new `/chunks/{hash}` HTTP endpoint. `StreamResolver` walks the manifest and fetches any missing chunks from reachable peers before playback.
- `chunk-stream-assembler`: In-memory adapter that reads chunk sequences from `ChunkCacheManager`, assembles a `Stream<List<int>>` compatible with `just_audio`'s `StreamAudioSource`, handles prefetch of upcoming chunks, and maps byte-offset seeks to chunk indices.
- `seeding-power-policy`: Runtime policy service that gates outbound chunk-serving on device charging state and network type (Wi-Fi vs. cellular). Exposes a user-configurable minimum battery level and an on/off toggle. Surfaced in the Settings screen.

### Modified Capabilities

<!-- No existing spec-level requirements change — this is entirely additive infrastructure. -->

## Impact

**Modified files:**
- `lib/features/federation/streaming/audio_cache_manager.dart` — replaced by `chunk_cache_manager.dart`
- `lib/features/federation/streaming/stream_resolver.dart` — extended for chunk-level peer fetching
- `lib/features/federation/serving/stream_handler.dart` — new `/chunks/{hash}` route added
- `lib/core/http_server/federation_router.dart` — register new chunks route
- `lib/core/di/service_locator.dart` — wire new services
- `lib/features/settings/screens/settings_screen.dart` — seeding power policy UI toggle

**New files:**
- `lib/features/federation/streaming/chunk_cache_manager.dart`
- `lib/features/federation/streaming/chunk_manifest.dart`
- `lib/features/federation/streaming/chunk_stream_assembler.dart`
- `lib/features/federation/streaming/seeding_power_policy.dart`
- `lib/core/database/tables/chunks_table.dart`
- `lib/core/database/tables/chunk_manifests_table.dart`

**Dependencies:**
- `crypto` package (already available via Flutter SDK) — SHA-256 hashing
- `connectivity_plus` — Wi-Fi vs. cellular detection for power policy
- `battery_plus` — charging state detection for power policy
- `just_audio` `StreamAudioSource` API — chunk assembler feeds bytes into this
