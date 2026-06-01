## ADDED Requirements

### Requirement: Mastodon account tile in Federation & Discovery settings section
`SettingsScreen` SHALL display a **Mastodon account** tile inside the "Federation & Discovery" section. The tile SHALL show the stored Mastodon handle as its subtitle when a handle exists, or "Not connected" when no handle is stored. Tapping the tile SHALL navigate to `MastodonImportScreen`.

#### Scenario: Handle stored — tile shows connected handle
- **WHEN** the user opens the Settings screen and a Mastodon handle is stored
- **THEN** a "Mastodon account" tile is visible under Federation & Discovery with the handle (e.g. "@howard@mastodon.social") as the subtitle

#### Scenario: No handle stored — tile shows "Not connected"
- **WHEN** the user opens the Settings screen and no Mastodon handle has been stored
- **THEN** the "Mastodon account" tile is visible with subtitle "Not connected"

#### Scenario: Tapping tile navigates to MastodonImportScreen
- **WHEN** the user taps the Mastodon account tile
- **THEN** the app pushes `MastodonImportScreen` onto the navigation stack

#### Scenario: MastodonImportScreen opened from settings pre-fills handle
- **WHEN** the user taps the Mastodon account tile and a handle is already stored
- **THEN** `MastodonImportScreen` opens with the handle input pre-filled with the stored value

### Requirement: Tile reflects handle changes without app restart
When the user updates or connects a Mastodon account via `MastodonImportScreen` (reached from the tile), the subtitle on the settings tile SHALL reflect the new handle when the user returns to `SettingsScreen`.

#### Scenario: Handle added — tile subtitle updates on return
- **WHEN** the user navigates from the settings tile to `MastodonImportScreen`, connects an account, and navigates back
- **THEN** the Mastodon account tile subtitle shows the newly stored handle

#### Scenario: Handle changed — tile subtitle shows updated value on return
- **WHEN** the user navigates from the settings tile to `MastodonImportScreen`, enters a different handle, and navigates back
- **THEN** the Mastodon account tile subtitle shows the updated handle
