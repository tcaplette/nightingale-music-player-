## 1. Connection Banner — MastodonImportScreen

- [x] 1.1 Watch `mastodonAccountProvider` in `_MastodonImportScreenState` using `ref.watch`
- [x] 1.2 Build a `_ConnectionBanner` widget that accepts a `String handle` and renders a checkmark icon + "Connected as @handle" text using the app's existing theme tokens
- [x] 1.3 Insert the banner into the `MastodonImportScreen` `ListView`, above the `TextField` — render it only when the provider resolves to a non-null value; render nothing during loading or when null

## 2. Mastodon Account Tile — SettingsScreen

- [x] 2.1 Convert `SettingsScreen` to a `ConsumerWidget` (it already is one — confirm and watch `mastodonAccountProvider`)
- [x] 2.2 Add a `ListTile` for "Mastodon account" under the Federation & Discovery section: subtitle shows the stored handle when non-null, otherwise "Not connected"; trailing is a chevron icon
- [x] 2.3 Wire the tile's `onTap` to push `AppRoutes.mastodonImport` (or the equivalent named route for `MastodonImportScreen`)

## 3. Provider Invalidation on Handle Change

- [x] 3.1 Audit `MastodonImportScreen` (and any other callers of `SecureStorageService.setMastodonHandle`) to confirm `ref.invalidate(mastodonAccountProvider)` is called after storing a new handle — add it if missing so both the banner and the settings tile refresh automatically
