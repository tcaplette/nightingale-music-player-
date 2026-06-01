## Why

Nightingale nodes currently have no profile identity beyond a display name — there is no avatar, no bio, no way for a user to edit their name after onboarding, and no way to back up that information when moving to a new device. This gap makes it hard for users to recognise each other across the federated network and means a device migration silently drops the user's display name entirely.

## What Changes

- Add a `profile_settings` screen (name, bio, avatar picker) reachable from the Account section of Settings
- Store avatar as a resized JPEG blob in the `node_identity` DB table (new `avatar_jpeg` column, schema v10 migration)
- Expose a new HTTP endpoint `GET /users/:username/avatar` so remote peers can resolve the `icon` URL in the ActivityPub actor JSON
- Populate `icon` in `_rowToActor()` so the actor JSON served to peers actually advertises the avatar URL
- Extend `NodeIdentityRepository` with `updateProfile()` and `getAvatarBytes()`
- Update the migration token payload to include `displayName`, `preferredUsername`, `summary`, and `avatarJpeg` (base64) so a full profile round-trips through backup/restore

## Capabilities

### New Capabilities

- `user-profile`: Core profile data model — DB column, repository interface/impl, actor JSON icon field, and avatar HTTP endpoint. Everything that makes a profile exist on the network.
- `profile-settings-screen`: Settings UI — profile tile in the Account section, new `ProfileSettingsScreen` (name, bio, avatar picker with 256×256 resize), and the `/settings/profile` route.
- `profile-backup`: Migration token extended to carry the full profile (display name, username, bio, base64 avatar) so restore produces an identical identity on the new device.

### Modified Capabilities

<!-- No existing spec-level requirements are changing. -->

## Impact

- **Database**: `NodeIdentityTable` gains `avatar_jpeg` (nullable blob); schema version bumps to 10
- **HTTP server**: New shelf route `GET /users/:username/avatar`; actor JSON `icon` field now populated
- **`NodeIdentityRepository`** interface + `NodeIdentityRepositoryImpl`
- **`MigrationService`**: export token payload and import restoration logic
- **Router**: new route constant `AppRoutes.settingsProfile`
- **`SettingsScreen`**: new tile in Account section
- **New dependency**: `image_picker` (already likely present) + `flutter_image_compress` for JPEG resize
