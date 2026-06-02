## ADDED Requirements

### Requirement: Chunks are stored as content-addressed SQLite BLOBs
The system SHALL store audio chunk data as binary BLOBs in a `chunks` Drift table, keyed by the SHA-256 hash of the chunk bytes. No chunk data SHALL be written to the device filesystem as individual files.

#### Scenario: Write a new chunk
- **WHEN** `ChunkCacheManager.writeChunk(hash, data)` is called with a hash and byte data
- **THEN** the chunk is inserted into the `chunks` table with `last_accessed` set to now and `is_pinned` set to false

#### Scenario: Duplicate chunk write is idempotent
- **WHEN** `writeChunk` is called with a hash that already exists in the table
- **THEN** the existing row is not duplicated and no error is thrown

### Requirement: Chunks are retrieved by hash
The system SHALL allow retrieval of a chunk's raw bytes by its SHA-256 hash in O(1) time via the primary key index.

#### Scenario: Read a cached chunk
- **WHEN** `ChunkCacheManager.readChunk(hash)` is called for a hash that exists
- **THEN** the raw byte data is returned and `last_accessed` is updated to now

#### Scenario: Read a missing chunk
- **WHEN** `readChunk` is called for a hash not in the table
- **THEN** null is returned

### Requirement: Total cache size is capped at a configurable limit
The system SHALL enforce a maximum total size across all stored chunk data (default 500 MB). Before writing a new chunk, the store SHALL evict the least-recently-accessed unpinned chunks until sufficient space is available.

#### Scenario: Eviction triggered by size cap
- **WHEN** writing a new chunk would exceed the size cap
- **THEN** the LRU unpinned chunks are deleted (oldest `last_accessed` first) until the new chunk fits, before the write proceeds

#### Scenario: Pinned chunks are not evicted
- **WHEN** eviction is triggered and all candidates are pinned
- **THEN** no eviction occurs and an `InsufficientCacheSpaceException` is thrown

### Requirement: Chunks can be pinned to prevent eviction
The system SHALL support pinning individual chunks so they are excluded from LRU eviction. Pinning is used to protect chunks belonging to tracks currently in the playback queue.

#### Scenario: Pin a chunk
- **WHEN** `ChunkCacheManager.pinChunk(hash)` is called
- **THEN** the chunk's `is_pinned` flag is set to true and it is excluded from all subsequent eviction passes

#### Scenario: Unpin a chunk
- **WHEN** `ChunkCacheManager.unpinChunk(hash)` is called
- **THEN** the chunk's `is_pinned` flag is set to false and it becomes eligible for eviction

### Requirement: Cache size limit is user-configurable
The system SHALL allow the maximum cache size to be updated at runtime without restarting the app.

#### Scenario: Update the size cap
- **WHEN** `ChunkCacheManager.setMaxSize(bytes)` is called with a new value
- **THEN** the new cap is applied to all subsequent write and eviction operations
