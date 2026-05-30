## Context

The app has accumulated 8 UX issues from active development: debug color artifacts, duplicated constants, a cluttered AppBar, raw color values bypassing the theme, and two typography regressions. The most significant structural change is the AppBar declutter, which requires introducing a bottom navigation bar so that Feed and Discover (currently stuffed into the Library AppBar) have a proper home.

The router already uses go_router with a `ShellRoute` wrapping Library + Search under `PlayerShell`. Feed and Discover are top-level routes with no persistent navigation context.

## Goals / Non-Goals

**Goals:**
- Fix all 8 issues identified in the audit with no regressions
- Introduce a bottom navigation bar (`StatefulShellRoute`) for Library, Feed, and Discover
- Preserve mini-player persistence across all bottom-nav tabs
- Keep all changes minimal — no design-system overhaul, no new dependencies

**Non-Goals:**
- Redesigning any screen beyond what the audit requires
- Adding a Profile or Settings tab (future phase work)
- Changing navigation animations or page transitions
- Addressing the home screen component gallery (that is Phase 1 scaffolding, not a shipped screen)

## Decisions

### D1 — Bottom nav via `StatefulShellRoute` (not `ShellRoute`)

`StatefulShellRoute` (go_router ≥ 7) preserves each branch's navigator stack independently, so switching from Library → Feed and back does not reset the Library scroll position or tab state. A plain `ShellRoute` rebuilds child state on every tab switch.

`PlayerShell` wraps the `StatefulShellRoute` builder so the mini-player remains persistent across all tabs, exactly as it does today for Library/Search.

Branch layout:
- Branch 0 — `/library` (+ `/library/albums/:id`, `/library/artists/:id`, `/search`)
- Branch 1 — `/feed`
- Branch 2 — `/discover`

The `AppBottomNav` widget reads the current branch index from the `StatefulNavigationShell` and drives `NavigationBar` (Material 3). It lives in `lib/shared/components/navigation/app_bottom_nav.dart`.

### D2 — Pull-to-refresh replaces the Refresh icon-button

`RefreshIndicator` wraps the `TabBarView` in `LibraryScreen`. The icon-button is removed. This is the standard mobile pattern and eliminates one of the five AppBar icons.

The scanning `CircularProgressIndicator` that replaced the Refresh icon during a scan is also removed; a slim `LinearProgressIndicator` below the `TabBar` shows scan progress instead (less disruptive, doesn't occupy an action slot).

### D3 — `miniPlayerHeight` moved to a shared constants file

A new file `lib/shared/theme/app_dimensions.dart` (or added to `app_spacing.dart`) holds `miniPlayerHeight = 64.0`. Both `mini_player.dart` and `player_shell.dart` import from there. No behavioral change.

### D4 — `fontFamily: 'System'` replaced with `null`

Flutter's `TextStyle` with `fontFamily: null` uses the platform default (San Francisco on iOS, Roboto on Android). The string `'System'` is not a registered font asset and silently falls back the same way — but it's semantically wrong and could break if a font named `'System'` is ever added. Replacing with `null` makes the intent explicit.

### D5 — Body text bumped from 14 px to 16 px

`bodyLarge` stays at 16 px (already correct). `bodyMedium` moves from 14 px → 16 px. `bodyMd` (the standalone static style) moves from 14 px → 16 px. `labelMedium` and `labelSmall` stay at 12/11 px — these are secondary labels, not body copy, and 12 px is acceptable for that role.

### D6 — Semantic colors for notification badge and cached indicator

Notification badge: use `scheme.error` (red in both light and dark) and `scheme.onError` (white in both) instead of raw `Colors.red` / `Colors.white`. This is already wired correctly in `AppColors`.

Cached stream indicator in `NowPlayingScreen`: replace `Colors.green` with `AppColors.accent` (the app's single accent color, already used for the remote stream indicator on the same row).

### D7 — `HostOfflineWidget` display name from track metadata

`NowPlayingScreen._NetworkStateIndicator` receives `state` which contains `state.currentTrack`. `TrackModel` has a `sourceActorUrl` field (the actor URL of the hosting node). The display name should be derived from that URL when available, falling back to `'Remote node'` only when `sourceActorUrl` is null. A simple helper extracts a human-readable label from the URL (e.g. `music.example` from `https://music.example/users/maya`).

## Risks / Trade-offs

- **`StatefulShellRoute` migration** — The existing `ShellRoute` must be replaced. The redirect logic (`onboarding`, `identity`) operates at the top level and is unaffected. Risk is low but the router is a central file; test redirect flows after the change. → Mitigation: keep the redirect guard identical; only the inner route structure changes.
- **Body text size increase** — Bumping `bodyMedium` from 14 → 16 px may reflow some existing list items or cards that assumed 14 px line height. → Mitigation: visually audit `AllSongsView`, `AlbumsView`, and `SocialFeedScreenV2` after the change; adjust padding if needed.
- **Pull-to-refresh on TabBarView** — `RefreshIndicator` must wrap each tab's scroll view, not the `TabBarView` itself, or it will only trigger on the first tab. → Mitigation: place `RefreshIndicator` inside each of the four tab widgets (`AllSongsView`, `AlbumsView`, `ArtistsView`, `GenresView`) and wire to `libraryScanProvider.notifier.scan()`.

## Open Questions

- Should the Notifications icon move to the bottom nav as a fourth tab (rather than staying as an AppBar action on the Library screen)? This change intentionally defers that — Notifications stays as a push route from the Feed tab's AppBar. Revisit in Phase 5 polish.
- The `Search` route is currently nested under the Library `ShellRoute`. Under the new `StatefulShellRoute`, Search should remain in Branch 0 so the Library navigator handles it. Confirm this is correct before implementing.
