## ADDED Requirements

### Requirement: ChunkStreamAssembler extends just_audio's StreamAudioSource
The system SHALL implement `ChunkStreamAssembler` as a subclass of `just_audio`'s `StreamAudioSource`. It SHALL override `request(start, end)` to serve byte ranges by reading the appropriate chunks from `ChunkCacheManager`, assembling a contiguous `Stream<List<int>>` for the requested window.

#### Scenario: Byte-range request maps to correct chunk indices
- **WHEN** `request(start: 1_048_576, end: 1_572_863)` is called on a track with 512 KB chunks
- **THEN** the assembler reads chunk index 2 (bytes 1_048_576–1_572_863) and streams those bytes in order

#### Scenario: Byte-range request spanning a chunk boundary
- **WHEN** `request(start: 500_000, end: 600_000)` is called, spanning the boundary between chunk 0 and chunk 1
- **THEN** the assembler reads the tail of chunk 0 and the head of chunk 1, streaming them as a single contiguous byte sequence

#### Scenario: Full-file request with no range
- **WHEN** `request()` is called with no start/end arguments
- **THEN** the assembler streams all chunks in manifest order from byte 0 to EOF

### Requirement: The assembler prefetches upcoming chunks
The system SHALL prefetch the next 2 chunks ahead of the current playback position into memory so that chunk boundaries do not cause audible pauses during normal playback.

#### Scenario: Prefetch triggers before the current chunk ends
- **WHEN** the assembler begins streaming chunk N
- **THEN** chunks N+1 and N+2 are loaded from `ChunkCacheManager` into memory before chunk N is exhausted

#### Scenario: Prefetch does not exceed 3 chunks in memory
- **WHEN** the assembler is actively streaming
- **THEN** at most 3 chunks (current + 2 prefetch) are held in memory simultaneously; previously consumed chunks are released

### Requirement: Seek operations are handled without full re-fetch
The system SHALL resolve a seek to a target byte offset by computing the target chunk index from the manifest, discarding in-memory chunks that are no longer needed, and requesting the new range from `ChunkCacheManager`. No full-track re-download SHALL be initiated for a seek.

#### Scenario: User seeks forward across multiple chunks
- **WHEN** playback is at chunk 2 and the user seeks to a position in chunk 7
- **THEN** chunks 3–6 are discarded from memory, chunk 7 is loaded, and prefetch resumes from chunk 8

#### Scenario: User seeks to the beginning
- **WHEN** `request(start: 0)` is called during active playback
- **THEN** the assembler resets to chunk 0 and streams from the start without re-downloading any chunks already in the cache

### Requirement: Missing chunks are fetched on demand during assembly
The system SHALL call `StreamResolver.resolveRemoteTrack` for any chunk that is missing from `ChunkCacheManager` at the time it is needed for assembly, writing the fetched bytes to the store before streaming them.

#### Scenario: On-demand fetch for a missing chunk during playback
- **WHEN** the assembler needs chunk N but it is not in `ChunkCacheManager`
- **THEN** the assembler fetches chunk N from the source node via `StreamResolver`, writes it to the cache, and continues streaming without interrupting playback beyond a brief buffer stall

#### Scenario: Fetch failure causes stream error
- **WHEN** chunk N cannot be fetched (source node unreachable, no cached copy)
- **THEN** the assembler emits a stream error and `just_audio` surfaces a playback error to the UI
