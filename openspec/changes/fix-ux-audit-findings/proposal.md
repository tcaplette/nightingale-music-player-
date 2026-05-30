## Why

The UI/UX Pro Max audit identified 8 issues — 3 critical bugs (including a leftover `Colors.green` debug scaffold background that makes the Library screen visually broken), 3 high-severity UX violations, and 2 medium-severity code-quality issues. These need to be fixed before any further feature work proceeds.

## What Changes

- Remove `backgroundColor: Colors.green` debug artifact from `LibraryScreen`
- Replace hardcoded `Colors.green` for the cached stream indicator in `NowPlayingScreen` with a semantic theme color
- Deduplicate the `miniPlayerHeight` constant (currently defined in both `mini_player.dart` and `player_shell.dart`) into a single shared location
- Reduce Library AppBar from 5 icons to 1 (Search only); relocate Feed and Discover to the bottom navigation bar and replace the Refresh icon-button with a pull-to-refresh gesture
- Replace hardcoded `Colors.red` / `Colors.white` in the notifications badge with theme-aware semantic colors
- Fix the `HostOfflineWidget` in `NowPlayingScreen` to show the actual remote actor/node name rather than the hardcoded string `'Remote node'`
- Increase `bodyMedium` / `bodyMd` text styles from 14 px to 16 px to meet mobile readability standards
- Remove the invalid `fontFamily: 'System'` string from `AppTypography` (replace with `null` to correctly use the platform default)

## Capabilities

### New Capabilities

- `bottom-nav`: Bottom navigation bar housing Library, Feed, Discover, and (optionally) Profile tabs, replacing the current single-screen AppBar icon cluster

### Modified Capabilities

*(none — all other changes are implementation-level fixes with no spec-level requirement changes)*

## Impact

- `lib/features/library/screens/library_screen.dart` — AppBar cleanup, pull-to-refresh, badge color fix
- `lib/features/player_ui/screens/now_playing_screen.dart` — cached indicator color, HostOfflineWidget display name
- `lib/features/player_ui/mini_player.dart` — remove duplicate `miniPlayerHeight` constant
- `lib/features/player_ui/player_shell.dart` — remove duplicate `miniPlayerHeight` constant, source from shared location
- `lib/shared/theme/app_typography.dart` — remove `'System'` fontFamily string, bump body sizes
- `lib/core/router/app_router.dart` — may need updating to accommodate bottom nav shell
- New file: `lib/shared/components/navigation/app_bottom_nav.dart` (or equivalent scaffold)
