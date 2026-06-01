## ADDED Requirements

### Requirement: Avatar stored as JPEG blob in node identity
The system SHALL store the user's avatar as a JPEG byte array in the `node_identity` database table. The column SHALL be nullable (no avatar is a valid state). Before storage, the image SHALL be resized to fit within 256×256 pixels and re-encoded as JPEG at quality 85. The stored bytes SHALL always represent the final-size image — no further processing occurs at serve time.

#### Scenario: Avatar saved within size bounds
- **WHEN** the user selects an image larger than 256×256 pixels
- **THEN** the system resizes it to fit within 256×256 (preserving aspect ratio) and stores the resulting JPEG bytes in `node_identity.avatar_jpeg`

#### Scenario: Avatar saved when already small
- **WHEN** the user selects an image that is already 256×256 or smaller
- **THEN** the system re-encodes it as JPEG at quality 85 and stores the result without upscaling

#### Scenario: No avatar on new identity
- **WHEN** a new identity is generated
- **THEN** `node_identity.avatar_jpeg` SHALL be null and no `icon` field is present in the served actor JSON

---

### Requirement: Avatar HTTP endpoint
The HTTP server SHALL expose `GET /users/:username/avatar` that serves the stored JPEG bytes for the local user. The endpoint SHALL return `Content-Type: image/jpeg` and the raw bytes. If no avatar is stored, the endpoint SHALL return HTTP 404.

#### Scenario: Avatar present
- **WHEN** a remote peer sends `GET /users/alice/avatar`
- **THEN** the server responds HTTP 200 with `Content-Type: image/jpeg` and the JPEG bytes

#### Scenario: No avatar stored
- **WHEN** a remote peer sends `GET /users/alice/avatar` and no avatar is set
- **THEN** the server responds HTTP 404

#### Scenario: Wrong username
- **WHEN** a remote peer requests an avatar for a username that does not match the local identity
- **THEN** the server responds HTTP 404

---

### Requirement: Actor JSON includes icon when avatar is set
The actor JSON served at `GET /users/:username` SHALL include an `icon` field whenever an avatar is stored. The `icon` field SHALL follow the ActivityPub Image object format: `{ "type": "Image", "url": "<actorUrl>/avatar" }`. When no avatar is stored, the `icon` field SHALL be omitted.

#### Scenario: Actor served with avatar
- **WHEN** the local identity has an avatar stored and a peer fetches `GET /users/alice`
- **THEN** the response JSON includes `"icon": { "type": "Image", "url": "http://<host>:<port>/users/alice/avatar" }`

#### Scenario: Actor served without avatar
- **WHEN** the local identity has no avatar stored and a peer fetches `GET /users/alice`
- **THEN** the response JSON does not contain an `icon` field

---

### Requirement: Repository exposes profile update and avatar read
The `NodeIdentityRepository` interface SHALL expose:
- `updateProfile({ String displayName, String? summary, Uint8List? avatarBytes })` — writes display name, bio, and avatar to the DB. Passing `null` for `avatarBytes` clears the stored avatar.
- `getAvatarBytes()` — returns the stored JPEG bytes or `null` if none.

#### Scenario: Profile update persists all fields
- **WHEN** `updateProfile` is called with a new display name, summary, and avatar bytes
- **THEN** all three values are persisted in `node_identity` and reflected in the next `getLocalActor()` call

#### Scenario: Clearing avatar
- **WHEN** `updateProfile` is called with `avatarBytes: null`
- **THEN** `node_identity.avatar_jpeg` is set to null and subsequent `getLocalActor()` calls return an actor with no `icon` field

---

### Requirement: Database migration to schema version 10
The database migration strategy SHALL include a `from < 10` block that calls `addColumn(nodeIdentityTable, nodeIdentityTable.avatarJpeg)`. Existing rows SHALL receive `null` for the new column.

#### Scenario: Upgrade from schema 9
- **WHEN** the app is launched on a device with an existing schema-9 database
- **THEN** the migration adds the `avatar_jpeg` column without error and the existing identity row has `avatar_jpeg = null`
