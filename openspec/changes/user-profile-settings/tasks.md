## 1. Database — schema v10

- [x] 1.1 Add nullable `BlobColumn get avatarJpeg` to `NodeIdentityTable` in `lib/core/database/tables/node_identity_table.dart`
- [x] 1.2 Bump `schemaVersion` to `10` in `lib/core/database/app_database.dart`
- [x] 1.3 Add `from < 10` migration block calling `addColumn(nodeIdentityTable, nodeIdentityTable.avatarJpeg)` in the `onUpgrade` handler
- [x] 1.4 Run `dart run build_runner build --delete-conflicting-outputs` to regenerate `app_database.g.dart`

## 2. Repository — interface and implementation

- [x] 2.1 Add `updateProfile({ required String displayName, String? summary, Uint8List? avatarBytes })` to `NodeIdentityRepository` abstract class
- [x] 2.2 Add `getAvatarBytes()` returning `Future<Uint8List?>` to `NodeIdentityRepository` abstract class
- [x] 2.3 Implement `updateProfile` in `NodeIdentityRepositoryImpl` — writes `displayName`, `summary` (future column, see 2.6), and `avatarJpeg` to the DB row
- [x] 2.4 Implement `getAvatarBytes` in `NodeIdentityRepositoryImpl` — reads `avatarJpeg` from the single identity row
- [x] 2.5 Update `_rowToActor()` in `NodeIdentityRepositoryImpl` to set `icon: '$actorUrl/avatar'` when `row.avatarJpeg != null`
- [x] 2.6 Add nullable `TextColumn get summary` to `NodeIdentityTable`; add `from < 10` addColumn for it alongside the avatar column (same migration block); regenerate

## 3. Avatar HTTP endpoint

- [x] 3.1 Create `lib/features/federation/serving/avatar_handler.dart` — reads `getAvatarBytes()` from `NodeIdentityRepository`; returns 200 `image/jpeg` with bytes, or 404 if null or username mismatch
- [x] 3.2 Register `GET /users/<username>/avatar` in the shelf router (wherever `actor_handler` is wired up) pointing to `avatarHandler`

## 4. Dependencies

- [x] 4.1 Add `image_picker` to `pubspec.yaml` if not already present
- [x] 4.2 Add `flutter_image_compress` to `pubspec.yaml` for JPEG resize/re-encode
- [x] 4.3 Add `READ_MEDIA_IMAGES` permission to `android/app/src/main/AndroidManifest.xml`
- [x] 4.4 Add `NSPhotoLibraryUsageDescription` to `ios/Runner/Info.plist`
- [x] 4.5 Run `flutter pub get`

## 5. Profile settings screen

- [x] 5.1 Create `lib/features/settings/screens/profile_settings_screen.dart` with: circular avatar widget (64 dp) + camera overlay, display name text field (required), read-only `@username` label, bio text field (optional, max 160 chars), Save button (disabled when clean)
- [x] 5.2 On avatar tap: call `ImagePicker().pickImage(source: ImageSource.gallery)`, compress with `FlutterImageCompress` to 256×256 JPEG quality 85, stage bytes in local state
- [x] 5.3 On Save: call `NodeIdentityRepository.updateProfile(...)` with staged values; show "Profile saved" snackbar on success; show error snackbar on failure; reset dirty flag
- [x] 5.4 Add `static const String settingsProfile = '/settings/profile'` to `AppRoutes` in `lib/core/router/app_router.dart`
- [x] 5.5 Register `GoRoute(path: 'profile', builder: ...)` as a child of the `/settings` route in `app_router.dart`, using `_fadePage` builder

## 6. Settings screen — profile tile

- [x] 6.1 Add a "Profile" `ListTile` (icon: `Icons.person_outline`, subtitle: "Name, photo, and bio") to the Account section of `SettingsScreen`, above the "Export identity" tile, navigating to `AppRoutes.settingsProfile`

## 7. Backup — migration token

- [x] 7.1 Update `MigrationService.exportToken()` to read `displayName`, `preferredUsername`, `summary`, and `avatarJpeg` (via `getAvatarBytes()`) from the repository and include them in the payload JSON; `avatarJpeg` SHALL be base64-encoded when present
- [x] 7.2 Update `MigrationService.initiateMove()` to decode and apply `displayName`, `summary`, and `avatarJpeg` (base64-decoded) from the token payload by calling `updateProfile()`; absent fields SHALL be handled gracefully without error
- [x] 7.3 Update `MigrationExportScreen` in `lib/features/node_identity/screens/migration_export_screen.dart`: hide the `QrImageView` and show a note when the token length exceeds 2048 bytes; keep the copy-to-clipboard path always visible
