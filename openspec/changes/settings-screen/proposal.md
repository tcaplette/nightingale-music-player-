## Why

Nightingale has no settings screen — two existing settings screens (FederationSettingsScreen, SharingSettingsScreen) are unreachable from the UI, and several important user preferences (theme, playback behaviour, notifications) are either hardcoded or missing entirely. Users have no way to configure the app to their preferences.

## What Changes

- Add a dedicated `SettingsScreen` as the central hub for all user preferences
- Wire `FederationSettingsScreen` and `SharingSettingsScreen` into the router and surface them from the new hub
- Add a `SettingsRepository` that persists all new settings via `flutter_secure_storage` (matching the existing pattern)
- Add a `ThemeNotifier` provider so the `MaterialApp` can react to the user's light/dark/system preference
- Expose playback buffer size, skip-previous threshold, and audio focus behaviour as user-configurable settings read by `PlaybackEngine` at startup
- Add notification preference controls (new followers, activity feed, auto-clear)
- Add reduce-motion toggle that scales animation durations app-wide
- Add Account section linking to `MigrationExportScreen` and `BlockedMutedScreen`, plus sign-out/reset

## Capabilities

### New Capabilities

- `settings-screen`: Central settings hub — scrollable screen with section tiles navigating to sub-sections or inline controls
- `playback-settings`: User-configurable playback preferences (buffer size, skip threshold, audio focus) persisted and read by the playback engine at startup
- `appearance-settings`: Theme (System/Light/Dark) and reduce-motion toggle with app-wide reactivity
- `notification-settings`: Per-type notification toggles and auto-clear cadence preference

### Modified Capabilities

<!-- No existing spec-level requirements are changing — federation and sharing screens already exist and retain their current behaviour; they are only being made reachable. -->

## Impact

- **Router** (`lib/core/router/app_router.dart`): new `/settings` route and entry point from the main shell
- **Navigation shell** (`lib/core/navigation/`): settings icon/action added to reach the new screen
- **PlaybackEngine** (`lib/core/audio/playback_engine.dart`): reads buffer/threshold/focus settings from `SettingsRepository` instead of hardcoded constants
- **MaterialApp** (`lib/main.dart` or app root): consumes `ThemeNotifier` to switch `themeMode`
- **New files**: `lib/features/settings/` directory with screen, repository, providers, and sub-screens
- **Dependencies**: no new packages — `flutter_secure_storage` and `provider`/`riverpod` already present
