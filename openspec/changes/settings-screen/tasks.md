## 1. SettingsRepository & Storage Foundation

- [x] 1.1 Create `lib/features/settings/data/settings_repository.dart` with `FlutterSecureStorage` using the same iOS/Android options as `ColdStartSettingsRepository`
- [x] 1.2 Define storage keys and typed getters/setters for: theme mode, reduce motion, buffer preset, skip threshold, audio focus behaviour, notify new followers, notify activity feed, notification auto-clear
- [x] 1.3 Register `SettingsRepository` as a singleton in `lib/core/di/service_locator.dart`

## 2. Theme Provider

- [x] 2.1 Create `lib/features/settings/providers/theme_notifier.dart` as a Riverpod `AsyncNotifier<ThemeMode>` that loads from `SettingsRepository` on first build
- [x] 2.2 Update `lib/app.dart` `_AppBody.build` to watch `themeNotifierProvider` and pass the resolved value to `MaterialApp.themeMode` (fall back to `ThemeMode.system` while loading)

## 3. Reduce-Motion Provider

- [x] 3.1 Create `lib/features/settings/providers/motion_notifier.dart` as a Riverpod `AsyncNotifier<bool>` that loads from `SettingsRepository`
- [x] 3.2 Add a `resolvedDuration(Duration standard)` helper that returns the standard duration or 80 ms when reduce-motion is enabled
- [x] 3.3 Update `lib/core/router/app_router.dart` `_fadePage` to use the motion notifier for `transitionDuration` / `reverseTransitionDuration`

## 4. Playback Settings Integration

- [x] 4.1 Create `lib/features/settings/models/playback_settings.dart` with `BufferPreset` enum (efficient/normal/generous), `SkipThreshold` enum (1/3/5/10 s), `AudioFocusBehaviour` enum (duck/pause/doNothing)
- [x] 4.2 Add `loadPlaybackSettings()` to `SettingsRepository` returning a `PlaybackSettings` value object with defaults matching current hardcoded values
- [x] 4.3 Update `PlaybackEngine.create()` in `lib/core/audio/playback_engine.dart` to accept a `PlaybackSettings` parameter and use its values for `AndroidLoadControl` and audio focus handling
- [x] 4.4 Update `setupServiceLocator()` in `lib/core/di/service_locator.dart` to `await` `loadPlaybackSettings()` and pass the result to `PlaybackEngine.create()`
- [x] 4.5 Update skip-previous logic in `PlaybackEngine` to read `skipThreshold` from `PlaybackSettings` instead of the hardcoded 3-second constant

## 5. Router & Shell Entry Point

- [x] 5.1 Add `static const String settings = '/settings'` and sub-route constants (`/settings/playback`, `/settings/appearance`, `/settings/notifications`) to `AppRoutes` in `lib/core/router/app_router.dart`
- [x] 5.2 Register `/settings` as a top-level `GoRoute` with nested child routes for each sub-screen (placeholder screens initially)
- [x] 5.3 Add a settings gear `IconButton` to the `AppBar` inside `AppBottomNav` in `lib/shared/components/navigation/app_bottom_nav.dart` that calls `context.push(AppRoutes.settings)`
- [x] 5.4 Add the sub-routes `/settings/playback`, `/settings/appearance`, `/settings/notifications` pointing to their respective screens (created in later tasks)

## 6. SettingsScreen Hub

- [x] 6.1 Create `lib/features/settings/screens/settings_screen.dart` as a `ConsumerWidget` with a `CustomScrollView` and `SliverList` of section tiles
- [x] 6.2 Add **Playback** section tile → pushes `/settings/playback`
- [x] 6.3 Add **Privacy & Sharing** section with a **Library Visibility** tile → pushes `SharingSettingsScreen` (use its existing route or push directly)
- [x] 6.4 Add **Federation & Discovery** section with a **Federation** tile → pushes `FederationSettingsScreen`
- [x] 6.5 Add **Notifications** section tile → pushes `/settings/notifications`
- [x] 6.6 Add **Appearance** section tile → pushes `/settings/appearance`
- [x] 6.7 Add **Account** section with **Export Identity** → `MigrationExportScreen`, **Blocked & Muted** → `BlockedMutedScreen`, and **Sign Out** tile
- [x] 6.8 Implement the Sign Out confirmation dialog: show `AlertDialog` on tap, on confirm clear identity state and navigate to `/onboarding`

## 7. Playback Sub-Screen

- [x] 7.1 Create `lib/features/settings/screens/playback_settings_screen.dart` as a `ConsumerWidget`
- [x] 7.2 Add **Buffer Size** tile showing current value; tapping opens a bottom sheet / dialog with Efficient / Normal / Generous options; on select, call `SettingsRepository.setBufferPreset` and show a SnackBar ("Takes effect next time the app opens")
- [x] 7.3 Add **Skip Previous Sensitivity** tile with options 1 s / 3 s / 5 s / 10 s; on select, persist and update `PlaybackEngine` skip threshold immediately via a setter
- [x] 7.4 Add **Audio Focus** tile with Duck / Pause / Do nothing options; on select, persist and update the engine's focus behaviour handler immediately

## 8. Appearance Sub-Screen

- [x] 8.1 Create `lib/features/settings/screens/appearance_settings_screen.dart` as a `ConsumerWidget`
- [x] 8.2 Add **Theme** segmented control / radio group (System / Light / Dark); on select, call `themeNotifierProvider.notifier.setTheme(mode)` which persists and emits the new value
- [x] 8.3 Add **Reduce Motion** `SwitchListTile`; on toggle, call `motionNotifierProvider.notifier.setReduceMotion(value)` which persists and emits

## 9. Notifications Sub-Screen

- [x] 9.1 Create `lib/features/settings/screens/notification_settings_screen.dart` as a `ConsumerWidget`
- [x] 9.2 Add **New Followers** `SwitchListTile`; on toggle, persist via `SettingsRepository`
- [x] 9.3 Add **Activity from People I Follow** `SwitchListTile`; on toggle, persist via `SettingsRepository`
- [x] 9.4 Add **Auto-Clear Read Notifications** tile showing current value; tapping opens options (7 days / 30 days / Never); on select, persist
- [x] 9.5 Update `NotificationsScreen` to filter out new-follower entries when the pref is disabled
- [x] 9.6 Update `NotificationsScreen` to filter out activity entries when the pref is disabled
- [x] 9.7 Update `NotificationsScreen` load/display logic to drop read notifications older than the auto-clear threshold (check on each open)

## 10. Wire Sub-Routes for Existing Screens

- [x] 10.1 Add `/settings/federation` and `/settings/sharing` routes to the router pointing to `FederationSettingsScreen` and `SharingSettingsScreen`
- [x] 10.2 Update the hub tiles in task 6.3 and 6.4 to use the new routes instead of direct widget pushes
