## MODIFIED Requirements

### Requirement: Cross-node deduplication
The app SHALL use ISRC comparison as a first-pass deduplication check before fingerprint comparison. If both tracks have a non-null, non-empty `isrc` value and those values are equal, the tracks SHALL be treated as the same recording without computing Chromaprint similarity. If either track has a null or empty `isrc`, the system SHALL fall back to fingerprint similarity comparison as defined in the original requirement. When two tracks are identified as duplicates (by either path), they SHALL be treated as the same track for display and queue purposes.

#### Scenario: Both tracks have matching ISRC
- **WHEN** two tracks from different nodes both have a non-null, non-empty `isrc` and the values are equal
- **THEN** the app treats them as the same track without computing Chromaprint fingerprints

#### Scenario: ISRC present but does not match
- **WHEN** two tracks both have a non-null, non-empty `isrc` and the values differ
- **THEN** the app treats them as distinct tracks without computing Chromaprint fingerprints

#### Scenario: One or both tracks missing ISRC — fingerprint fallback
- **WHEN** either track has a null or empty `isrc`
- **THEN** the app falls back to Chromaprint fingerprint similarity comparison
- **AND** applies the existing >= 0.95 similarity threshold

#### Scenario: Identical tracks from two nodes — no ISRC
- **WHEN** two tracks from different nodes have no ISRC but fingerprint similarity >= 0.95
- **THEN** the app treats them as the same track (unchanged from original behaviour)

#### Scenario: Different versions preserved — no ISRC
- **WHEN** two tracks from different nodes have no ISRC and fingerprint similarity < 0.95
- **THEN** the app treats them as distinct tracks (unchanged from original behaviour)
