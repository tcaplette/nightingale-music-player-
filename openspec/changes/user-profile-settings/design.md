## Context

Nightingale is a fully peer-to-peer music federation app — every device runs its own ActivityPub HTTP server (shelf). There is no central backend. User identity is stored in the `node_identity` SQLite table (one row per device), and the actor JSON it produces is the authoritative source of truth for what remote peers see.

Currently the `NodeIdentityTable` has `display_name` and `preferred_username` but no avatar. `_rowToActor()` builds an `ApActor` that never sets `icon`, so every actor JSON served to the network has no profile picture. The `MigrationService` export token contains only `actorUrl` + `issuedAt`, so a device restore loses the display name.

## Goals / Non-Goals

**Goals:**
- User can set and update display name, bio, and avatar from Settings
- Avatar is served directly from the device over the existing shelf HTTP server
- Remote peers see the `icon` URL in actor JSON and can fetch + cache the image
- A backup token carries the full profile so restore is lossless
- Avatar bytes are constrained to a small size at write time (256×256 JPEG max)

**Non-Goals:**
- Avatar CDN, proxy, or relay — the image is served from the user's device only
- Changing `preferredUsername` after identity creation — it is part of the actor URL and would break all federation links
- Profile visibility controls — avatar and bio are always public (same as ActivityPub norm)
- Remote avatar caching to disk — remote `PersonDisplay` widgets already load from the `icon` URL; HTTP-level caching (`CachedNetworkImage` or similar) is not in scope here

## Decisions

### D1 — Store avatar bytes in the database, not the filesystem

**Decision**: Add a nullable `BlobColumn avatar_jpeg` to `NodeIdentityTable`. Avatar bytes live in the same SQLite database as all other identity data.

**Rationale**: Keeps the identity self-contained. A single DB file is what the backup token reconstructs, and there are no file-path or permission edge cases across Android/iOS. Profile images are small (target ≤ 30 KB after resize), so blob storage overhead is negligible.

**Alternative considered**: Store as a file in the app's documents directory and keep the path in DB. Rejected because file paths complicate backup (you'd need to bundle the file too), and app storage directories differ between platforms.

---

### D2 — Serve avatar from the existing shelf HTTP server

**Decision**: Add a new shelf route `GET /users/:username/avatar` that reads the blob from the DB and returns it as `image/jpeg`. The actor JSON `icon.url` points to this endpoint.

**Rationale**: The shelf server is already running and exposed via STUN for cross-network reachability. Adding one route is the minimal path to making `icon` work. No new infrastructure.

**Alternative considered**: Serve as a data URL embedded in the actor JSON itself. Rejected — ActivityPub spec uses a URL for `icon`, and embedding multi-KB base64 in every actor fetch would bloat every peer discovery request.

---

### D3 — Resize to 256×256 JPEG at write time, not read time

**Decision**: When the user picks a photo, compress and resize it to a 256×256 JPEG (quality 85) before storing. The DB blob is always the final-size image.

**Rationale**: Keeps storage and serving simple — no resize pipeline at serve time, no quality variants. 256×256 is sufficient for avatar display at all current UI sizes.

**Alternative considered**: Store original and resize on the fly at serve time. Rejected — adds complexity and latency to every avatar fetch by every peer.

---

### D4 — Backup token is a self-contained JSON blob, avatar base64-encoded inline

**Decision**: Extend the migration token payload to include `displayName`, `preferredUsername`, `summary`, and `avatarJpeg` (base64 of the JPEG bytes). The token remains a single base64url-encoded JSON string.

**Rationale**: Keeps the restore path simple — scan the QR code (or paste the token), and the new device has everything it needs. No need to separately transfer an image file.

**Trade-off**: A 256×256 JPEG at quality 85 is typically 15–25 KB, which base64-encodes to ~20–33 KB. The full token becomes ~35–45 KB. That is well within QR code capacity (up to ~4 KB for binary QR, so we stick with the existing copy-paste / share-sheet flow for large tokens rather than QR for avatar-bearing tokens).

---

### D5 — `preferredUsername` is read-only in the profile settings screen

**Decision**: Display `preferredUsername` as a non-editable label. Only `displayName` and `summary` are editable text fields.

**Rationale**: `preferredUsername` is baked into the actor URL (`http://device:port/users/:username`). Changing it after identity creation would invalidate every existing follower relationship and every cached actor URL on the network. The cost of allowing it far exceeds the benefit.

## Risks / Trade-offs

**Avatar unreachable when device is offline** → Mitigation: This is inherent to the peer-to-peer model. Remote clients should treat a failed avatar fetch as non-fatal and fall back to initials/placeholder. The `PersonDisplay` widget already handles `null` avatarUrl gracefully; a 404/timeout on a live URL should be treated the same way.

**QR code too large for avatar-bearing tokens** → Mitigation: The existing migration export screen shows both a QR code and a copy-to-clipboard option. For tokens with an avatar, the QR code may exceed readable size; we suppress the QR and show only the copy/share option when the token exceeds ~2 KB. The UI already truncates display to 60 chars.

**DB blob migration on existing installs** → Mitigation: Standard Drift `addColumn` with `nullable()` — no data backfill needed. Existing rows get `null` for `avatar_jpeg`, which is the correct default (no avatar set).

**`image_picker` permissions (camera + gallery)** → Mitigation: Both Android (`READ_MEDIA_IMAGES`) and iOS (`NSPhotoLibraryUsageDescription`) permissions are required. These need to be added to `AndroidManifest.xml` and `Info.plist`.

## Migration Plan

1. Add `avatar_jpeg` column to `NodeIdentityTable` (nullable blob)
2. Bump `AppDatabase.schemaVersion` to 10, add `from < 10` migration block (`addColumn`)
3. Run `dart run build_runner build` to regenerate `app_database.g.dart`
4. Add `GET /users/:username/avatar` route to the shelf router
5. Update `_rowToActor()` to set `icon` when bytes are present
6. Add `updateProfile()` and `getAvatarBytes()` to repository interface + impl
7. Build `ProfileSettingsScreen` and wire route + settings tile
8. Update `MigrationService` export/import for full profile payload

No rollback needed — the column is nullable and the token format change is additive (old tokens without profile fields still parse correctly).

## Open Questions

- Should the profile settings screen be gated behind identity existence (i.e., only reachable if `hasIdentity()` is true)? The rest of the settings screen is already gated by the onboarding flow, so this is likely fine as-is.
- Should updating `displayName` broadcast an `Update(Person)` ActivityPub activity to followers so their cached actor records refresh? Out of scope for this change but worth a follow-up.
