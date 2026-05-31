## ADDED Requirements

### Requirement: Metadata completeness badge on track tiles
Track tiles in library views SHALL display a small circular badge indicating metadata completeness, but ONLY for tracks that are members of the user's published library (i.e. the user has sharing enabled and the track is in the sharing scope). Tracks outside the published library SHALL render no badge.

#### Scenario: Incomplete track in published library
- **WHEN** a track tile is rendered for a track that is in the user's published library
- **AND** `MetadataValidator.validate()` returns `MetadataIncomplete` for that track
- **THEN** a red dot badge is rendered on the track tile

#### Scenario: Complete track in published library
- **WHEN** a track tile is rendered for a track that is in the user's published library
- **AND** `MetadataValidator.validate()` returns `MetadataComplete` for that track
- **THEN** a green dot badge is rendered on the track tile

#### Scenario: Track not in published library
- **WHEN** a track tile is rendered for a track that is NOT in the user's published library
- **THEN** no badge is rendered regardless of metadata completeness

#### Scenario: Sharing disabled globally
- **WHEN** the user's sharing setting is "private"
- **THEN** no track tiles display metadata badges (no tracks are in the published library)

---

### Requirement: Badge updates reflect real-time completeness
The badge state SHALL update without requiring a library rescan whenever the track's metadata is edited via the metadata editor.

#### Scenario: Badge transitions from red to green after editing
- **WHEN** the user completes all missing required fields in the metadata editor and saves
- **THEN** the track tile badge transitions from red to green on the next frame without an app restart or manual refresh

#### Scenario: Badge is consistent with validator result
- **WHEN** a track tile badge displays green
- **THEN** `MetadataValidator.validate()` for that track SHALL return `MetadataComplete`
- **AND** the track SHALL not be blocked by the federation gate
