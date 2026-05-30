## ADDED Requirements

### Requirement: Chromaprint fingerprinting
The app SHALL compute a Chromaprint acoustic fingerprint for every track in the local library at scan time. Fingerprints SHALL be stored in the local database.

#### Scenario: Fingerprint new track
- **WHEN** a new track is added to the library during scan
- **THEN** the app computes its Chromaprint fingerprint asynchronously
- **AND** stores it in the fingerprint database

#### Scenario: Skip already fingerprinted
- **WHEN** a track already has a fingerprint in the database
- **THEN** the app skips recomputing the fingerprint

### Requirement: Cross-node deduplication
The app SHALL use fingerprint comparison to identify the same track across different nodes. When two tracks have a fingerprint similarity above the configured threshold, they SHALL be treated as the same track.

#### Scenario: Identical tracks from two nodes
- **WHEN** two tracks from different nodes have fingerprint similarity >= 0.95
- **THEN** the app treats them as the same track for display and queue purposes

#### Scenario: Different versions preserved
- **WHEN** two tracks from different nodes have fingerprint similarity < 0.95
- **THEN** the app treats them as distinct tracks

### Requirement: Reversible merges with provenance
Every deduplication decision SHALL be recorded with the two fingerprints, similarity score, and reason. Merges SHALL be reversible without data loss.

#### Scenario: Merge two tracks
- **WHEN** the system decides two tracks are the same
- **THEN** a merge record is created containing both fingerprints, similarity score, and timestamp

#### Scenario: Undo merge
- **WHEN** the user or system undoes a merge
- **THEN** the merge record is marked as undone
- **AND** the two tracks are displayed as separate again

### Requirement: Fingerprint index for remote libraries
When fetching a remote library, the app SHALL compute fingerprints for remote tracks (or use provided fingerprints) and match them against the local fingerprint index.

#### Scenario: Remote track matches local
- **WHEN** a remote track's fingerprint matches a local track
- **THEN** the app displays the local copy as available and skips fetching the remote stream URL
