## ADDED Requirements

### Requirement: Connection banner displayed when handle is stored
`MastodonImportScreen` SHALL display a connection status banner above the handle input field. When a Mastodon handle is stored in secure storage, the banner SHALL show a checkmark icon and the text "Connected as @handle" (using the full stored handle). When no handle is stored, no banner is shown.

#### Scenario: Handle stored — banner visible on screen open
- **WHEN** the user opens `MastodonImportScreen` and a Mastodon handle is stored
- **THEN** a banner is displayed above the input field showing a checkmark icon and "Connected as @handle@instance.social"

#### Scenario: No handle stored — no banner shown
- **WHEN** the user opens `MastodonImportScreen` and no Mastodon handle has been stored
- **THEN** no connection banner is rendered; the input field is the first visible element

#### Scenario: Banner visible while loading
- **WHEN** `mastodonAccountProvider` is in the loading state on screen entry
- **THEN** no banner is rendered until the value resolves (no flash of incorrect content)

### Requirement: Banner persists across result states
The connection banner SHALL remain visible regardless of whether search results are loading, showing matches, showing the empty state, or the input is idle. The banner represents account linkage, not search state.

#### Scenario: Banner visible while results are loading
- **WHEN** the user has submitted a search and results are loading
- **THEN** the connection banner remains visible above the input field

#### Scenario: Banner visible when match list is shown
- **WHEN** the import search completes and a list of matches is displayed
- **THEN** the connection banner remains visible above the input field

#### Scenario: Banner visible when empty state is shown
- **WHEN** the import search completes with zero matches
- **THEN** the connection banner remains visible above the input field

### Requirement: Banner updates after handle change
If the user submits a new handle and it is stored (replacing the previous value), the banner SHALL update to reflect the new handle without requiring a screen restart.

#### Scenario: Handle changed — banner shows new value
- **WHEN** the user enters a new Mastodon handle, the import runs, and the new handle is stored and `mastodonAccountProvider` is invalidated
- **THEN** the banner updates to show "Connected as @newhandle@instance.social"
