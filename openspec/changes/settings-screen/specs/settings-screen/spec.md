## ADDED Requirements

### Requirement: Settings screen is reachable from the app shell
The app SHALL provide a persistent settings entry point visible from all three bottom-nav tabs. Tapping it SHALL navigate to `/settings` without altering the current bottom-nav branch state.

#### Scenario: Settings icon visible on all tabs
- **WHEN** the user is on any bottom-nav tab (Library, Feed, Discover)
- **THEN** a settings gear icon is visible in the shell's AppBar

#### Scenario: Tapping settings navigates to settings screen
- **WHEN** the user taps the settings icon
- **THEN** the app pushes the `/settings` route over the current shell

#### Scenario: Back navigation returns to previous tab
- **WHEN** the user is on the settings screen and taps the system/nav back button
- **THEN** the app pops `/settings` and returns to the tab the user was on

---

### Requirement: Settings screen displays all sections
The SettingsScreen SHALL display a scrollable list of labelled sections: **Playback**, **Privacy & Sharing**, **Federation & Discovery**, **Notifications**, **Appearance**, and **Account**. Each section SHALL contain one or more list tiles.

#### Scenario: All sections render on first open
- **WHEN** the user opens the settings screen for the first time
- **THEN** all six sections are visible (possibly requiring scroll) with their labels and tiles

#### Scenario: Sections with sub-screens show a trailing chevron
- **WHEN** a settings section navigates to a dedicated sub-screen
- **THEN** the tile displays a trailing chevron icon

---

### Requirement: Privacy & Sharing section links to SharingSettingsScreen
The settings hub SHALL include a **Library Visibility** tile in the Privacy & Sharing section that pushes `SharingSettingsScreen`.

#### Scenario: Library visibility tile navigates correctly
- **WHEN** the user taps the Library Visibility tile
- **THEN** `SharingSettingsScreen` is pushed onto the navigation stack

---

### Requirement: Federation & Discovery section links to FederationSettingsScreen
The settings hub SHALL include a **Federation** tile that pushes `FederationSettingsScreen`.

#### Scenario: Federation tile navigates correctly
- **WHEN** the user taps the Federation tile
- **THEN** `FederationSettingsScreen` is pushed onto the navigation stack

---

### Requirement: Account section provides identity export and block/mute management
The Account section SHALL contain tiles for **Export Identity** and **Blocked & Muted**.

#### Scenario: Export identity navigates to MigrationExportScreen
- **WHEN** the user taps Export Identity
- **THEN** `MigrationExportScreen` is pushed

#### Scenario: Blocked & muted navigates to BlockedMutedScreen
- **WHEN** the user taps Blocked & Muted
- **THEN** `BlockedMutedScreen` is pushed

---

### Requirement: Account section provides sign-out action
The Account section SHALL contain a **Sign Out** tile. Tapping it SHALL show a confirmation dialog before performing sign-out.

#### Scenario: Sign-out requires confirmation
- **WHEN** the user taps Sign Out
- **THEN** a confirmation dialog is shown with Cancel and Confirm actions

#### Scenario: Cancelling sign-out returns to settings
- **WHEN** the user taps Cancel in the sign-out confirmation dialog
- **THEN** the dialog dismisses and the settings screen remains visible

#### Scenario: Confirming sign-out clears identity and restarts onboarding
- **WHEN** the user taps Confirm in the sign-out confirmation dialog
- **THEN** the app clears identity state and navigates to the onboarding flow
