## ADDED Requirements

### Requirement: Federation paths block tracks with incomplete metadata
All outbound federation operations SHALL pass through `MetadataGate` before emitting a track. If `MetadataValidator.validate()` returns `MetadataIncomplete` for the track, the operation SHALL be rejected with a typed `MetadataIncompleteException` that includes the list of missing fields. The following paths are gated: library Collection export, `Announce` activity dispatch, and any direct publish call via `LibraryPublisher`.

#### Scenario: Publishing a complete track
- **WHEN** a track passes `MetadataGate` and all 7 required fields are present
- **THEN** the federation operation proceeds normally

#### Scenario: Publishing an incomplete track — library Collection export
- **WHEN** the library Collection endpoint is requested and a track in the published set has missing required fields
- **THEN** that track is excluded from the Collection response
- **AND** no error is returned to the requesting actor (the incomplete track is silently omitted)

#### Scenario: Publishing an incomplete track — Announce activity
- **WHEN** the user attempts to dispatch an `Announce` activity for a track with missing required fields
- **THEN** the activity is blocked before dispatch
- **AND** the app displays a message identifying the missing fields
- **AND** the app offers to open the metadata editor for that track

#### Scenario: Library publish — incomplete track in scope
- **WHEN** the user enables library sharing and one or more tracks in scope have missing required fields
- **THEN** those tracks are excluded from the published Collection
- **AND** the Settings screen displays a count of tracks excluded due to incomplete metadata

---

### Requirement: User is guided to the metadata editor on gate rejection
When a federation operation is blocked by `MetadataGate`, the app SHALL present a non-dismissible prompt that names the missing fields and offers a direct action to open the metadata editor for the affected track.

#### Scenario: Gate rejection prompt shown
- **WHEN** a user-initiated federation action (e.g. Share track) is blocked by `MetadataGate`
- **THEN** a bottom sheet or dialog appears listing the missing required fields
- **AND** a primary action button opens the metadata editor for that track

#### Scenario: User edits and re-shares immediately
- **WHEN** the user completes the missing fields in the editor and saves
- **AND** returns to the share action
- **THEN** the federation operation proceeds without further gate rejection

---

### Requirement: Gate is applied at all outbound federation callsites
`MetadataGate` SHALL be the single enforcement point. Individual federation services (LibraryPublisher, ActivityService) SHALL call `MetadataGate.check()` before emitting any track. No track SHALL bypass the gate via a secondary code path.

#### Scenario: New federation path added in future
- **WHEN** a new outbound federation service is introduced
- **THEN** it SHALL call `MetadataGate.check()` — the compile-time API enforces this by requiring a validated `MetadataGateToken` to be passed to the emit method
