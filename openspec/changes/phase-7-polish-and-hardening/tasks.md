## 1. Foundation & Shared Infrastructure

- [x] 1.1 Add `const bool kDiagnosticsEnabled = !kReleaseMode` to `lib/core/debug/diagnostics.dart` and replace all existing `kDebugMode` debug-overlay guards with it
- [x] 1.2 Add `EmptyStateWidget` to `lib/shared/components/` with parameterized icon, headline, and optional subhead
- [x] 1.3 Add `ActivityQueue` Drift table (`id`, `activityJson`, `createdAt`, `attemptCount`, `status`) to the local database schema
- [x] 1.4 Add `connectivity_plus` dependency and create `OfflineModeCoordinator` Riverpod provider that exposes an `isOnline` stream
- [x] 1.5 Verify `AppDurations` and `AppCurves` design-system constants cover: `pageTransition` (250 ms), `sheetEnter` (300 ms), `stateTransition` (200 ms); add any missing constants

## 2. Onboarding Flow

- [x] 2.1 Create `lib/features/onboarding/` module with `OnboardingGuard`, `OnboardingShellRoute`, and a `SecureStorageService` abstraction over `flutter_secure_storage`
- [x] 2.2 Implement `OnboardingGuard` as a go_router `redirect` that checks `onboardingComplete` from `SecureStorageService`; cache the value after first read
- [x] 2.3 Build the welcome screen (brand splash, single CTA "Get started")
- [x] 2.4 Build the identity setup screen: trigger background Ed25519 key generation, show "Setting up your space…" progress state; surface a user-friendly retry on failure — no cryptographic terms visible
- [x] 2.5 Build the key-migration story screen: plain-language "Take your music identity with you" copy, "Back up" primary CTA wired to the Phase 3 `Move` activity flow, skippable
- [x] 2.6 Build the completion screen: write `onboardingComplete = true` to secure storage, transition to home with a fade animation, ensure back-navigation cannot return to onboarding
- [x] 2.7 Wire `onboardingComplete = true` default for existing installs so they bypass onboarding on upgrade

## 3. UX Polish & Network-State Surface Refinement

- [x] 3.1 Audit every go_router page transition and bottom sheet entrance; replace hardcoded durations/curves with `AppDurations` and `AppCurves` constants
- [x] 3.2 Replace list/feed spinners with skeleton-loading placeholders using shimmer animation and design-token colors for: library all-songs, albums, artists, social feed, recommendations discover screen
- [x] 3.3 Add `EmptyStateWidget` instances to every list and feed view: all-songs, albums, artists, genres, social feed, notifications, search results, discover screen, followers list, following list
- [x] 3.4 Add a `HapticService` wrapper around `HapticFeedback` and wire `lightImpact` on track start, `mediumImpact` on save/like, `heavyImpact` on terminal stream failure
- [x] 3.5 Animate the entrance and exit of all four network-state widgets (`BufferingWidget`, `HostOfflineWidget`, `StreamFailedPlayingLocalWidget`, `PartialLibraryWidget`) using `AppDurations.stateTransition` and `AppCurves.easeOut`
- [x] 3.6 Run the tone audit on all four network-state widget copy strings: remove "Error"/"Failed"/"Problem", adopt second-person present tense, replace error-red colors with neutral tokens; add audit checklist comment above each class
- [x] 3.7 Verify no network-state component obscures playback controls in the Now Playing layout; adjust z-order or layout constraints as needed

## 4. Offline Resilience

- [x] 4.1 Implement `ActivityQueue` flush logic in `OfflineModeCoordinator`: on transition to online, flush FIFO with exponential backoff (up to 3 attempts); mark permanently failed activities as `dead`
- [x] 4.2 Wire all outgoing ActivityPub activity dispatchers (Listen, Like, Share, Follow, Announce) to enqueue via `ActivityQueue` when `isOnline` is false, with optimistic UI update
- [x] 4.3 Update the playback engine's remote-track resolver to implement the three-source fallback cascade: local cache → relay → alternate host by fingerprint → mark unavailable and skip
- [x] 4.4 Add `StreamFailedPlayingLocalWidget` display to the Now Playing screen when falling back to cache, and auto-advance after 3 s pause when all sources are exhausted
- [x] 4.5 Implement startup DB integrity check: run `PRAGMA integrity_check` on Drift DB open; on pass, proceed normally; on failure, attempt WAL checkpoint then re-open
- [x] 4.6 Implement staged DB recovery: (a) index rebuild preserving track rows with non-intrusive repair toast; (b) full clear + re-scan with user-modal confirmation if rows are unrecoverable

## 5. Accessibility

- [x] 5.1 Add `Semantics` labels to all interactive elements in the Now Playing screen: play/pause (state-reactive), skip next/previous, seek bar, shuffle toggle, repeat toggle
- [x] 5.2 Add `Semantics` labels to track list items (title + artist + duration) and album/artist detail rows throughout the library
- [x] 5.3 Add `Semantics` labels to all icon-only buttons in the social feed, notifications, profile, and mini player
- [x] 5.4 Audit and fix all touch targets below 44×44 logical pixels: use `SizedBox` / `Padding` / `InkResponse` to expand hit areas without altering visual layout
- [x] 5.5 Run WCAG AA contrast audit against every text/background and icon/background pair in light and dark mode; update design tokens or widget color assignments where ratio is below 4.5:1 (normal text) or 3:1 (large text / icons)
- [x] 5.6 Audit all text widgets for dynamic type overflow at 1.5× and 2.0× OS text scale: add `TextOverflow.ellipsis` with appropriate `maxLines`, and ensure list cells expand vertically

## 6. Performance Optimization

- [x] 6.1 Add `Timeline.startSync`/`finishSync` markers to the startup sequence at: Drift DB open, identity load, router initialization, first frame callback
- [x] 6.2 Profile cold start in release mode on target hardware; optimize any stage exceeding its budget by deferring non-critical initialization to post-frame callbacks
- [x] 6.3 Convert all uniform-height list views (library all-songs, social feed) to `SliverFixedExtentList` with explicit `itemExtent`
- [x] 6.4 Wrap the mini player widget and all artwork thumbnail widgets in `RepaintBoundary`
- [x] 6.5 Configure `cached_network_image` with `maxMemoryCacheCount: 50` and `maxDiskCacheSize: 100 MB`; verify images load asynchronously without dropped frames during fast scroll
- [x] 6.6 Configure `just_audio` buffer settings: minimum 5 s pre-roll before first audio, target 30 s buffer, reduce to 15 s target on connections below 64 kbps
- [x] 6.7 Implement LRU eviction for the audio cache with a 500 MB limit; protect in-queue tracks from eviction during the active session
- [x] 6.8 Tune background `ActivityPub` inbox polling to an adaptive interval: 2 min when active, increasing to 15 min after 10 min of idle; measure battery impact

## 7. Unit Tests

- [x] 7.1 Unit tests for recommendation engine: network trending, taste affinity scoring, new-from-known; assert ranked output and provenance reason strings
- [x] 7.2 Unit tests for cold-start bootstrap: node discovery scoring and genre/library overlap matching
- [x] 7.3 Unit tests for ActivityPub serialization: Actor, Listen, Like, Announce, OrderedCollection — round-trip encode/decode fidelity
- [x] 7.4 Unit tests for HTTP Signature signing and verification: valid signature accepted, tampered payload rejected, unknown key ID rejected
- [x] 7.5 Unit tests for replay-protection nonce/timestamp window: within-window request accepted, expired request rejected, duplicate nonce rejected
- [x] 7.6 Unit tests for acoustic fingerprinting deduplication: within-threshold match produces merge with provenance record; undo restores both tracks
- [x] 7.7 Unit tests for stream authentication: valid token accepted, expired token rejected, wrong-node token rejected
- [x] 7.8 Unit tests for key migration: `Move` activity generation produces valid ActivityPub payload; ingestion on the receiving node updates follower references

## 8. Widget Tests

- [x] 8.1 Widget tests for player controls: play/pause state transition, skip, seek, shuffle toggle (on/off), repeat cycle (off/one/all)
- [x] 8.2 Widget tests for social feed: list item renders avatar + display name (no raw handle), activity type icons, like/share counts
- [x] 8.3 Widget tests for library views: all-songs list renders track title + artist + duration; album detail renders tracklist; artist detail renders album grid
- [x] 8.4 Widget tests for all four network-state components: each renders without exception, displays expected content, passes Semantics label assertions
- [x] 8.5 Widget tests for `OnboardingGuard`: mock `SecureStorageService` returning unset flag redirects to onboarding shell; set flag passes through
- [x] 8.6 Widget tests for `EmptyStateWidget`: headline and icon are rendered; optional subhead appears when provided; no exception when subhead is absent

## 9. Integration Tests

- [x] 9.1 Build the in-process two-node federation harness: two `NightingaleNode` instances with isolated in-memory Drift databases and stubbed HTTP transport routing signed requests via method calls
- [x] 9.2 Integration test: node A publishes a `Listen` activity → node B's inbox receives it → node B's social feed store contains the event
- [x] 9.3 Integration test: node B begins streaming a track from node A → node A is dropped from the harness mid-stream → node B falls back to local cache and displays `StreamFailedPlayingLocalWidget`
- [x] 9.4 Integration test: replay protection — same signed activity delivered to node B twice → second delivery rejected → node B inbox contains exactly one copy
- [x] 9.5 Verify all integration tests complete in under 60 s; add to CI pipeline alongside unit and widget tests

## 10. Performance Debug Overlay & Production Diagnostics

- [x] 10.1 Create `PerformanceOverlayTab` widget (inside `kDiagnosticsEnabled` guard): frame render time (current + average + 60 s peak) via `SchedulerBinding.addTimingsCallback`
- [x] 10.2 Add RSS memory display to `PerformanceOverlayTab`, refreshing every 5 s
- [x] 10.3 Add network bytes transferred and active connection count to `PerformanceOverlayTab` (sourced from `NetworkInspector`)
- [x] 10.4 Add audio cache hit rate and image cache hit rate to `PerformanceOverlayTab` (instrumented in the cache layer)
- [x] 10.5 Add active remote stream count and per-stream latency to `PerformanceOverlayTab` (sourced from the stream manager)
- [x] 10.6 Register `PerformanceOverlayTab` as a new tab in the debug overlay shell
- [x] 10.7 Add `sentry_flutter` to `pubspec.yaml`; implement `SentryCrashReporter` with `beforeSend` allowlist (exception type, anonymized stack trace, app version, platform only)
- [x] 10.8 Wire `PlatformDispatcher.instance.onError` and `FlutterError.onError` to `CrashReporter.recordError` in `main.dart`
- [x] 10.9 Register `SentryCrashReporter` in release builds when `SENTRY_DSN` env var is set; register `NullCrashReporter` in all other cases
- [x] 10.10 Document `SENTRY_DSN` build-time variable in the project README or `docs/` and wire it into the CI build step for release artifacts
