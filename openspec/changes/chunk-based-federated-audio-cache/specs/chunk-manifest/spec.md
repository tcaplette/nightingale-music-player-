## ADDED Requirements

### Requirement: A manifest records the ordered chunk sequence for a track
The system SHALL persist a `ChunkManifest` for each cached remote track, storing the ordered list of SHA-256 chunk hashes, the track's total byte size, the source actor URL, and the time the manifest was fetched. The manifest is the authoritative record of how to reconstruct the track from the chunk store.

#### Scenario: Manifest is written when a track finishes downloading
- **WHEN** all chunks for a remote track have been written to `ChunkCacheManager`
- **THEN** a `ChunkManifest` row is inserted into `chunk_manifests` with the track ID, source actor URL, ordered hash list, total size, and `fetched_at` timestamp

#### Scenario: Manifest lookup by track and actor
- **WHEN** `ChunkManifestRepository.getManifest(trackId, sourceActorUrl)` is called
- **THEN** the matching manifest is returned, or null if none exists

### Requirement: Manifests use SHA-256 hashes over raw audio bytes
The system SHALL compute chunk hashes over the raw audio byte content only, excluding any track metadata. This enables content-addressed deduplication across tracks that share identical audio segments.

#### Scenario: Identical audio bytes in two tracks share chunks
- **WHEN** two different tracks produce a chunk with identical raw bytes at the same offset
- **THEN** both manifests reference the same chunk hash and only one BLOB row exists in the `chunks` table

### Requirement: Chunk size is fixed at 512 KB
The system SHALL split track audio into sequential 512 KB chunks. The final chunk of a track MAY be smaller than 512 KB.

#### Scenario: Track splits into expected chunk count
- **WHEN** a 5 MB audio file is chunked
- **THEN** the manifest contains 10 chunk hashes: nine of exactly 524 288 bytes and one of the remainder

#### Scenario: Track smaller than one chunk
- **WHEN** an audio file is smaller than 512 KB
- **THEN** the manifest contains exactly one chunk hash covering the entire file

### Requirement: Manifests are deleted when all their chunks are evicted
The system SHALL delete a `ChunkManifest` row when the last chunk it references is removed from the `chunks` table, keeping the two tables consistent.

#### Scenario: Manifest removed on full eviction
- **WHEN** LRU eviction removes the last chunk referenced by a manifest
- **THEN** the corresponding manifest row is also deleted

#### Scenario: Partial eviction leaves manifest intact
- **WHEN** eviction removes some but not all chunks referenced by a manifest
- **THEN** the manifest row remains, marking the track as partially cached
