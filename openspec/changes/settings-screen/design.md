## Context

The app uses **Riverpod** for state management, **go_router** (StatefulShellBranch) for navigation, and **flutter_secure_storage** for all persistent preferences. There are three bottom-nav tabs (Library, Feed, Discover); settings is not a fourth tab — it is a pushed route, same as Notifications and Profile. `PlaybackEngine` is created once via `PlaybackEngine.create()` inside `setupServiceLocator()` in `lib/core/di/service_locator.dart`. The `MaterialApp` in `lib/app.dart` currently hardcodes `themeMode: ThemeMode.system`.

## Goals / Non-Goals

**Goals:**
- One entry point (`/settings`) reachable from the app shell, revealing all user preferences
- `FederationSettingsScreen` and `SharingSettingsScreen` accessible via the new hub (no UI changes to those screens themselves)
- New settings (playback, appearance, notifications, account links) backed by persistent storage
- Theme mode (`System / Light / Dark`) reactively applied to `MaterialApp`
- Playback constants (buffer, skip threshold, focus behaviour) sourced from storage at engine startup
- Reduce-motion toggle scales `AppMotion` durations app-wide

**Non-Goals:**
- Redesigning or modifying `FederationSettingsScreen` or `SharingSettingsScreen` internals
- Per-screen animation overrides — reduce-motion is a global multiplier only
- In-app account deletion or data purge (separate concern)
- Any new package dependencies

## Decisions

### 1. Single `SettingsRepository` in `lib/features/settings/`
**Decision:** Create `lib/features/settings/data/settings_repository.dart` using the identical `FlutterSecureStorage` construction as `ColdStartSettingsRepository` (iOS Keychain `first_unlock`, Android `encryptedSharedPreferences`).

**Why:** Keeps storage access consistent across the app. Avoids scattering new `SharedPreferences` or raw storage calls. The existing pattern is already tested and handles platform differences.

**Alternative considered:** `SharedPreferences` — simpler, but settings like notification prefs shouldn't be world-readable on Android; existing pattern uses encrypted storage throughout, so we follow it.

---

### 2. `ThemeNotifier` as a Riverpod `AsyncNotifier`
**Decision:** Create `lib/features/settings/providers/theme_notifier.dart` — a `AsyncNotifier<ThemeMode>` that loads from `SettingsRepository` on first build and exposes `setTheme(ThemeMode)`. `_AppBody` in `lib/app.dart` watches it via `ref.watch(themeNotifierProvider)`, replacing the hardcoded `ThemeMode.system`.

**Why:** `MaterialApp.themeMode` must be driven from the widget tree. Riverpod's `AsyncNotifier` handles the async load cleanly and gives the existing `ConsumerStatefulWidget` (`_AppBody`) a natural place to consume it. Falls back to `ThemeMode.system` while loading so there's no flash.

**Alternative considered:** A plain `StateNotifier` initialized in `setupServiceLocator` — but that couples the DI container to Flutter's widget lifecycle unnecessarily.

---

### 3. Playback settings injected at `PlaybackEngine.create()` time
**Decision:** Add a `PlaybackSettings` value object (buffer preset enum, skip threshold seconds, audio focus behaviour enum). `SettingsRepository.loadPlaybackSettings()` is called synchronously (using `await`) inside `setupServiceLocator()` before `PlaybackEngine.create()`, and the result is passed in. The engine stores these as final fields.

**Why:** `PlaybackEngine` is a service-layer object with no Riverpod access. Reading from storage once at startup and passing the result avoids introducing a Flutter/Riverpod dependency into the audio layer. If the user changes a playback setting, a toast informs them it takes effect after restart (acceptable UX trade-off for v1; a full hot-swap would require refactoring the engine lifecycle).

**Alternative considered:** Having the engine observe a `ValueNotifier` — adds complexity; buffer config on `AndroidLoadControl` cannot be changed after the player is constructed anyway.

---

### 4. Settings entry point: action icon in the app shell AppBar
**Decision:** Add a settings gear `IconButton` to `AppBottomNav`'s `Scaffold` — placed in a top-level `AppBar` or as a trailing icon on the Library tab's AppBar — that calls `context.push('/settings')`. The `/settings` route is registered as a top-level `GoRoute` (outside all `StatefulShellBranch`es), exactly like `/notifications`.

**Why:** Matches the existing pattern for Notifications. Keeps the bottom nav at 3 tabs (adding a 4th tab for settings is unconventional and would push it out of the M3 NavigationBar sweet spot). A consistent top-right icon is discoverable and conventional for settings.

**Alternative considered:** Settings as a 4th bottom tab — breaks M3 NavigationBar conventions and inflates the nav for a rarely-visited destination.

---

### 5. Reduce-motion via an `AppMotion` extension provider
**Decision:** Create `lib/features/settings/providers/motion_notifier.dart` — a simple `AsyncNotifier<bool>`. A new `AppMotionSettings` extension reads from this provider (via `ref.read` at call sites) to return either the real `AppMotion` duration or a short fixed duration (e.g. 80ms) when reduce-motion is on.

**Why:** `AppMotion` is currently a pure static class. Rather than rewriting every call site, we add one indirection layer. All existing `AppMotion.pageTransition` usages remain but route through a `context`-free provider lookup.

**Alternative considered:** Passing `Duration` down the widget tree — too invasive; would require touching every animated widget.

---

### 6. Notification preferences stored in `SettingsRepository`, not a notification service
**Decision:** `SettingsRepository` stores three bools (`notifyNewFollowers`, `notifyActivityFeed`) and one enum (`notificationAutoClear`). The existing `NotificationsScreen` reads these prefs to filter display. No push-notification infrastructure is added.

**Why:** The app has an in-app notification center (`NotificationsScreen`) but no FCM/APNs integration. These prefs control what appears in that center, not OS-level push. Keeping them in `SettingsRepository` is consistent and avoids premature infrastructure.

---

### 7. Sub-settings navigation within the pushed settings stack
**Decision:** All sub-sections (Playback, Appearance, Notifications, Federation, Sharing) are either inline in `SettingsScreen` (if they have ≤ 3 controls) or pushed as separate routes (`/settings/playback`, `/settings/appearance`, etc.) registered as nested `GoRoute`s under `/settings`.

**Why:** Avoids a single long-scroll page. Groups with many controls (Playback has 3, Notifications has 3) warrant their own screen. Privacy/sharing and Federation are already full screens — they just push from the hub.

## Risks / Trade-offs

- **Playback settings require restart** → Mitigated by showing a `SnackBar` on save: "Changes take effect next time you open the app."
- **Secure storage async cold start** → `ThemeNotifier` shows `ThemeMode.system` while loading; no visible flash on most devices because Riverpod initialises before first frame.
- **`AppMotion` reduce-motion indirection** → If `AppMotion` is used in non-widget contexts (e.g. pure animation controllers), they will need explicit provider plumbing. Current usage is widget-only, so low risk.
- **Settings screen entry point placement** → Putting the gear icon on the Library AppBar means it isn't reachable from Feed/Discover tabs without switching tabs. Mitigation: place it on `AppBottomNav`'s wrapping `Scaffold` AppBar so it is always visible.

## Migration Plan

1. Add `SettingsRepository` and register in `service_locator.dart`
2. Add `ThemeNotifier` and wire into `_AppBody` — lowest risk, isolated change
3. Add playback settings load into `setupServiceLocator` and pass to `PlaybackEngine.create()`
4. Build `SettingsScreen` hub with section tiles
5. Add `/settings` route (and sub-routes) to `AppRoutes` and `buildRouter`
6. Add settings icon to shell
7. Build sub-screens (Playback, Appearance, Notifications) — Federation and Sharing screens already exist
8. Wire `NotificationsScreen` to read notification prefs from `SettingsRepository`
9. Wire `AppMotion` reduce-motion provider

No data migration required — all new keys; defaults match current hardcoded behaviour.

## Open Questions

- Should the settings gear live on every tab's AppBar individually, or on a single persistent top-level AppBar wrapping the entire shell? (The current shell is a bare `Scaffold` with only a `NavigationBar`; adding an AppBar to `AppBottomNav` is the cleanest universal placement.)
- For the "sign out / reset" action — what exactly should reset? Identity only, or all app data including library scan? Needs product decision before implementation.
