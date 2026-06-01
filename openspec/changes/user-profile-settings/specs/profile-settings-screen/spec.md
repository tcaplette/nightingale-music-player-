## ADDED Requirements

### Requirement: Profile tile in Settings Account section
The Settings screen SHALL display a "Profile" tile in the Account section, above the existing "Export identity" tile. Tapping the tile SHALL navigate to `ProfileSettingsScreen` at route `/settings/profile`.

#### Scenario: Profile tile visible
- **WHEN** the user opens Settings
- **THEN** a "Profile" tile with subtitle "Name, photo, and bio" is visible in the Account section

#### Scenario: Profile tile navigates to screen
- **WHEN** the user taps the "Profile" tile
- **THEN** the app navigates to `ProfileSettingsScreen`

---

### Requirement: ProfileSettingsScreen displays current profile
The `ProfileSettingsScreen` SHALL load and display the current `displayName`, `summary`, and avatar on entry. It SHALL present:
- A circular avatar widget (64 dp) with a camera-icon overlay tap target for picking a new image
- A text field pre-filled with `displayName` (required, non-empty)
- A read-only label showing `preferredUsername` (prefixed with `@`)
- A text field pre-filled with `summary` (optional, multi-line, max 160 characters)
- A "Save" button that is enabled only when the form is dirty (user has changed at least one field)

#### Scenario: Screen loads with existing profile
- **WHEN** the user navigates to `ProfileSettingsScreen` and a name is already set
- **THEN** the display name field is pre-filled, the username label shows the current `@username`, and the avatar widget shows the stored avatar (or a placeholder initials avatar if none is set)

#### Scenario: Username is not editable
- **WHEN** the user taps the `@username` label
- **THEN** nothing happens — the field is not focusable

#### Scenario: Save button disabled on load
- **WHEN** the user opens `ProfileSettingsScreen` without making any changes
- **THEN** the Save button is disabled

#### Scenario: Save button enabled after change
- **WHEN** the user modifies any field (name, bio, or avatar)
- **THEN** the Save button becomes enabled

---

### Requirement: Avatar picker resizes before saving
Tapping the avatar widget SHALL open the system image picker (gallery). After the user selects an image, the system SHALL resize it to fit within 256×256 pixels, re-encode as JPEG at quality 85, and stage the result in memory. The staged bytes SHALL be committed to the DB only when the user taps Save.

#### Scenario: User picks an image
- **WHEN** the user taps the avatar widget and selects a photo from the gallery
- **THEN** the avatar widget updates to show the resized preview and the Save button becomes enabled

#### Scenario: User cancels image picker
- **WHEN** the user taps the avatar widget and dismisses the picker without selecting
- **THEN** the avatar widget is unchanged and Save button state is unchanged

---

### Requirement: Save commits profile changes
Tapping Save on `ProfileSettingsScreen` SHALL call `NodeIdentityRepository.updateProfile()` with the current field values. On success the screen SHALL show a brief confirmation snackbar and the Save button SHALL return to disabled. On error the screen SHALL show an error snackbar without navigating away.

#### Scenario: Successful save
- **WHEN** the user taps Save after editing the display name
- **THEN** `updateProfile` is called, a "Profile saved" snackbar appears, and the Save button is disabled

#### Scenario: Save failure
- **WHEN** `updateProfile` throws an exception
- **THEN** an error snackbar is shown and the user remains on the screen with their edits intact

---

### Requirement: Route registered for profile settings
The router SHALL register `GET /settings/profile` mapped to `ProfileSettingsScreen`. The route SHALL be a child of `/settings` and use the same fade-through page transition as other settings sub-routes. `AppRoutes.settingsProfile` SHALL be defined as the constant `'/settings/profile'`.

#### Scenario: Direct navigation to profile settings
- **WHEN** `context.push(AppRoutes.settingsProfile)` is called
- **THEN** `ProfileSettingsScreen` is displayed with a fade-through transition
