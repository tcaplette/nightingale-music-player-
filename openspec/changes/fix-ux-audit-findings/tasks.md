## 1. Critical Bug Fixes

- [x] 1.1 Remove `backgroundColor: Colors.green` from `LibraryScreen` in `lib/features/library/screens/library_screen.dart:65` (remove the line entirely — let the theme scaffold background apply)
- [x] 1.2 Replace `Colors.green` with `AppColors.accent` for the cached stream indicator icon in `lib/features/player_ui/screens/now_playing_screen.dart:242`

## 2. Deduplicate miniPlayerHeight

- [x] 2.1 Add `static const double miniPlayerHeight = 64.0;` to `lib/shared/theme/app_spacing.dart` (or a new `lib/shared/theme/app_dimensions.dart` if spacing feels like the wrong file)
- [x] 2.2 Remove the `const double miniPlayerHeight = 64.0;` top-level constant from `lib/features/player_ui/mini_player.dart` and import from the shared location
- [x] 2.3 Remove the duplicate `const double miniPlayerHeight = 64.0;` from `lib/features/player_ui/player_shell.dart` and import from the shared location

## 3. Typography Fixes

- [x] 3.1 In `lib/shared/theme/app_typography.dart`, change `static const String _fontFamily = 'System';` to remove the constant and replace all `fontFamily: _fontFamily` usages with `fontFamily: null` (or simply remove the `fontFamily:` lines, which defaults to null)
- [x] 3.2 In `lib/shared/theme/app_typography.dart`, bump `bodyMd` fontSize from `14` to `16`
- [x] 3.3 In `lib/shared/theme/app_typography.dart`, bump `bodyMedium` (inside `buildTextTheme`) fontSize from `14` to `16`

## 4. Semantic Color Fixes

- [x] 4.1 In `lib/features/library/screens/library_screen.dart`, replace `color: Colors.red` with `color: Theme.of(context).colorScheme.error` and `color: Colors.white` with `color: Theme.of(context).colorScheme.onError` in the `_NotificationsBadgeButton` widget

## 5. Fix HostOfflineWidget Display Name

- [x] 5.1 In `lib/features/player_ui/screens/now_playing_screen.dart`, update `_NetworkStateIndicator` to extract the display name from `state.currentTrack?.sourceActorUrl` — parse the hostname/path from the URL as a fallback label (e.g. extract `music.example` from `https://music.example/users/maya`), and pass it to `HostOfflineWidget(displayName: ...)` instead of the hardcoded `'Remote node'`

## 6. Bottom Navigation Bar

- [x] 6.1 Create `lib/shared/components/navigation/app_bottom_nav.dart` — a `NavigationBar` (Material 3) widget with three destinations: Library (icon: `Icons.library_music_outlined` / selected: `Icons.library_music`), Feed (icon: `Icons.people_outline` / selected: `Icons.people`), Discover (icon: `Icons.explore_outlined` / selected: `Icons.explore`). Accept `StatefulNavigationShell` and delegate tab switching to `shell.goBranch(index)`.
- [x] 6.2 In `lib/core/router/app_router.dart`, replace the existing inner `ShellRoute` (wrapping Library + Search under `PlayerShell`) with a `StatefulShellRoute` containing three branches: Branch 0 — `/library` (+ album/artist detail sub-routes + `/search`), Branch 1 — `/feed`, Branch 2 — `/discover`. The `StatefulShellRoute` builder wraps the shell in `PlayerShell` and renders `AppBottomNav` below the child.
- [x] 6.3 Move the Feed and Discover `GoRoute` entries from the top-level routes list into the `StatefulShellRoute` branches (Branch 1 and Branch 2 respectively). Remove their duplicate top-level route entries.
- [x] 6.4 Verify the onboarding and identity redirect guards in `app_router.dart` are unaffected — they operate at the top level and should not need changes.

## 7. Library AppBar Cleanup

- [x] 7.1 In `lib/features/library/screens/library_screen.dart`, remove the Feed (`Icons.people_outline`), Discover (`Icons.explore_outlined`), and Notifications (`_NotificationsBadgeButton`) icon buttons from the `AppBar.actions` list. Keep only the Search icon button.
- [x] 7.2 Remove the scanning `CircularProgressIndicator` Refresh icon button from the AppBar. Replace it with a `LinearProgressIndicator` shown below the `TabBar` when `isScanning` is true (a thin 2–3 dp bar between the tab bar and the tab content).
- [x] 7.3 Wrap the content of each tab view (`AllSongsView`, `AlbumsView`, `ArtistsView`, `GenresView`) with a `RefreshIndicator` that calls `ref.read(libraryScanProvider.notifier).scan()` on refresh.

## 8. Move Notifications Badge to Feed Screen

- [x] 8.1 In `lib/features/federation/screens/social_feed_screen.dart` or `lib/features/social/screens/social_feed_screen_v2.dart` (whichever is the active Feed screen under Branch 1), add `_NotificationsBadgeButton` (or equivalent) to the Feed AppBar actions so the notifications shortcut is reachable from the Feed tab.
