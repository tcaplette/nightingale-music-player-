## ADDED Requirements

### Requirement: Migration token includes full profile
The `MigrationService.exportToken()` method SHALL include `displayName`, `preferredUsername`, `summary` (nullable), and `avatarJpeg` (nullable, base64-encoded JPEG bytes) in the signed payload JSON. The token format remains a base64url-encoded JSON string containing `payload` and `signature` fields.

#### Scenario: Token exported with avatar
- **WHEN** the user has set a display name, bio, and avatar and triggers export
- **THEN** the token payload includes `displayName`, `preferredUsername`, `summary`, and `avatarJpeg` as a base64 string

#### Scenario: Token exported without avatar
- **WHEN** the user has a display name but no avatar set and triggers export
- **THEN** the token payload includes `displayName` and `preferredUsername`; `avatarJpeg` is absent or null; the token is still valid

---

### Requirement: Profile restored on migration import
The `MigrationService.initiateMove()` method SHALL read `displayName`, `summary`, and `avatarJpeg` from the token payload and call `NodeIdentityRepository.updateProfile()` on the new device after validating the token. Fields absent from the token SHALL be treated as empty/null (graceful degradation for tokens produced by older app versions).

#### Scenario: Full profile round-trips through migration
- **WHEN** a token carrying name, bio, and avatar is scanned on a new device
- **THEN** `updateProfile` is called with the decoded values and the new device's identity reflects the original profile

#### Scenario: Old token without profile fields
- **WHEN** a token produced by an older app version (no `displayName` field) is imported
- **THEN** the import succeeds without error; the display name and avatar remain at their defaults

---

### Requirement: QR code suppressed for large tokens
The migration export screen SHALL display the QR code only when the token is ≤ 2048 bytes. When the token exceeds 2048 bytes (as will happen when an avatar is present), the QR code widget SHALL be hidden and only the copy-to-clipboard and share-sheet options SHALL be shown. A brief explanatory note SHALL inform the user why the QR code is unavailable.

#### Scenario: Token small enough for QR
- **WHEN** the exported token is ≤ 2048 bytes (no avatar, short name)
- **THEN** the QR code widget is displayed alongside the copy option

#### Scenario: Token too large for QR
- **WHEN** the exported token exceeds 2048 bytes (avatar present)
- **THEN** the QR code widget is hidden; the screen shows only the copy-to-clipboard button and the note "Your profile photo makes this code too large for a QR — use the copy button instead"
