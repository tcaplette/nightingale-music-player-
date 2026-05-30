## Context

Phases 1–6 are feature-complete. Every screen, federated protocol path, recommendation signal, and debug tab has been shipped. Phase 7 makes no new features — it works across all existing modules simultaneously: tightening animation timing, hardening offline paths, adding accessible semantics, profiling performance, and building the test harness that proves the whole system holds together. It is inherently cross-cutting.

The app's most unusual design constraint carries forward: network-degraded states are the normal case, not edge cases. Every decision here is made through that lens — graceful degradation isn't a fallback, it's the primary path.

## Goals / Non-Goals

**Goals:**
- Every screen feels polished, intentional, and calm under degraded network conditions
- The app survives offline, DB corruption, and node unreachability without data loss or broken UI
- Full accessibility compliance (VoiceOver/TalkBack, WCAG AA, dynamic type, touch targets)
- Measurable performance targets met: cold start, scroll framerate, memory, battery
- Comprehensive test coverage proving the federated round-trip, including host-drop fallback
- Debug builds ship the complete overlay (including Phase 7 performance tab); release builds contain zero diagnostic code

**Non-Goals:**
- No new user-facing features — Phase 7 polishes and hardens what exists
- No data migrations — Phase 7 adds no new schema changes to the Drift database
- No changes to ActivityPub protocol behavior — federation semantics are fixed from Phase 3/4
- No new external services beyond production error reporting

## Decisions

### D1 — Onboarding flow as a guarded navigation shell

The first-launch flow is implemented as a navigation guard in go_router: on cold start, a `OnboardingGuard` redirect checks an `onboardingComplete` flag in secure storage. If unset, all routes redirect to the onboarding shell. The onboarding shell is a standalone Riverpod scope that drives identity generation, the migration-story screen, and initial preferences — it never exposes a raw handle, key material, or ActivityPub vocabulary to the user.

**Alternative considered:** A splash screen that runs setup synchronously before the router initializes. Rejected: mixing platform splash with app logic is fragile across iOS/Android; a router guard is testable and composable.

### D2 — Centralized offline coordinator, not per-feature handling

A single `OfflineModeCoordinator` (Riverpod provider) subscribes to `connectivity_plus` and owns the authoritative online/offline state for the entire app. All features watch this provider. When offline: local playback continues uninterrupted; outgoing ActivityPub activities are written to a durable `ActivityQueue` table (Drift) and flushed on reconnect in FIFO order; network-state components are notified automatically.

**Alternative considered:** Each feature module maintaining its own connectivity check. Rejected: duplicates logic, creates inconsistent state signals, and makes the "activity queue" pattern impossible to implement reliably.

### D3 — DB integrity check on startup with staged recovery

On every startup, the app runs `PRAGMA integrity_check` against the Drift/SQLite library database. On failure, recovery proceeds in three stages: (1) attempt WAL checkpoint and re-open; (2) rebuild indices while preserving track rows; (3) if unrecoverable, clear and re-scan with a user-visible notification. A snapshot of the last known good library state (track count, fingerprint hashes) is preserved before any destructive recovery step.

**Alternative considered:** Silent background repair with no user notification. Rejected: the "communicate state honestly" principle requires surfacing this to the user, even if the recovery is automatic.

### D4 — Shared animation constants and a `NetworkStateAnimator` wrapper

Animation constants (`AppDurations`, `AppCurves`) already exist in the design system from Phase 1. Phase 7 audits every transition against these constants and adds two missing pieces: (a) `NetworkStateAnimator` — a widget wrapper that applies a consistent entrance/exit choreography and holds the "calm, not broken" copy and icon for each degraded-state variant; (b) `EmptyStateWidget` — a shared component parameterized by icon, headline, and subhead, used in every list and feed.

All animation durations are in the 200–350ms range; easing is always `Curves.easeOut` for exits, `Curves.easeInOut` for transitions. Nothing animates that doesn't communicate state change.

**Alternative considered:** Per-screen custom animations. Rejected: inconsistency across screens violates the "motion has meaning" principle; shared constants enforce the vocabulary.

### D5 — Three-tier haptic vocabulary

Haptic feedback is mapped to exactly three intensities using `HapticFeedback` from `flutter/services`:
- `lightImpact` → track start (positive confirmation)
- `mediumImpact` → save, like (intentional action)
- `heavyImpact` → stream error, node unreachable (failure signal)

Haptics are fire-and-forget; failure (e.g., device doesn't support haptics) is silently ignored. No haptics on scroll, drag, or ambient UI events.

### D6 — Performance targets with inline `Timeline` markers

Measurable targets: cold start ≤ 2 s (measured from `main()` to first frame), feed scroll ≥ 58 fps sustained on a mid-range device (Pixel 6 / iPhone 12 class), steady-state memory ≤ 150 MB during playback, background battery drain ≤ 3% per hour. Flutter `Timeline.startSync`/`finishSync` markers are added at key startup phases (DB open, identity load, first route render) to enable DevTools profiling without shipping any logging overhead.

Feed rendering is optimized via `SliverList` with fixed-extent cells where possible, `cached_network_image` for avatar and artwork, and `RepaintBoundary` isolation around the mini player and artwork components.

### D7 — In-process two-node federation harness for integration tests

Integration tests that validate the full ActivityPub round-trip (publish → receive → stream → host-drop fallback) use an in-process harness: two `NightingaleNode` instances in the same test process, each with an isolated in-memory Drift database and a stubbed network transport that routes HTTP Signature-signed requests between them via method calls rather than real sockets. This makes tests fast, hermetic, and runnable in CI without device infrastructure.

**Alternative considered:** End-to-end tests on two physical devices or emulators. Rejected: too slow and fragile for CI. The in-process harness still exercises real ActivityPub serialization, HTTP Signature signing/verification, replay protection, and fallback logic — only the network socket is stubbed.

### D8 — Compile-time debug gate via `const bool kDiagnosticsEnabled`

A single `const bool kDiagnosticsEnabled = !kReleaseMode` controls the entire debug overlay. All diagnostic code is wrapped in `if (kDiagnosticsEnabled)` guards or `kDiagnosticsEnabled ? widget : const SizedBox.shrink()` in the widget tree. Flutter's tree-shaker removes all unreachable branches in release builds. Phase 7 adds one new tab to the overlay (`PerformanceOverlayTab`) following the same pattern established in earlier phases.

### D9 — Production error reporting: Sentry over Firebase Crashlytics

Sentry is preferred over Firebase Crashlytics because it is self-hostable (consistent with the "no central server" ethos where feasible), has a Flutter SDK with strong PII scrubbing controls, and avoids adding a Firebase dependency to a project that has none. `PlatformDispatcher.instance.onError` and `FlutterError.onError` are wired to Sentry in release builds only, with a `beforeSend` hook that strips any field that could identify a user (node URL, username, file paths). Sentry initialization is wrapped in `kDiagnosticsEnabled` guards so it never runs in debug builds.

## Risks / Trade-offs

- **DB recovery destroys data if staging is wrong** → Mitigation: snapshot row counts and fingerprint hashes before any destructive step; log recovery actions to a recovery journal; never proceed past stage 1 without a valid snapshot.
- **Haptics are fragmented on Android** → Mitigation: `HapticFeedback` degrades silently on unsupported devices; no business logic depends on haptic delivery.
- **Integration test harness drifts from real network behavior** → Mitigation: the harness enforces real ActivityPub serialization and HTTP Signature logic; only the socket layer is stubbed. Periodic manual two-device smoke testing is the safety net for socket-layer bugs.
- **Accessibility semantics break existing UI on screen readers** → Mitigation: audit each screen incrementally with VoiceOver/TalkBack enabled before merging; widget tests assert on `Semantics` labels.
- **Dynamic type support causes layout overflow** → Mitigation: all text is `TextOverflow.ellipsis` with a max of 2 lines in list cells; now-playing screen uses a `FittedBox` for track title.
- **Sentry `beforeSend` may still leak PII if field names change** → Mitigation: allowlist-based filtering (only send specific safe fields) rather than denylist-based (strip known bad fields); reviewed before each release.

## Migration Plan

Phase 7 is purely additive. No database schema migrations, no ActivityPub protocol changes, no breaking API changes. Deployment steps:

1. The `onboardingComplete` flag defaults to `true` for all existing installs (guard only fires on fresh installs).
2. The `ActivityQueue` Drift table is additive; existing schema is unmodified.
3. The DB integrity check runs read-only on startup; no schema change required.
4. Sentry initialization is release-only and gated behind a build-time DSN environment variable; if the DSN is absent, reporting is silently disabled.

Rollback: any individual capability can be reverted without affecting others — each is implemented in an isolated module.

## Open Questions

- **Dynamic type max scale factor**: should the app clamp `textScaleFactor` to 1.4× to prevent catastrophic layout overflow, or flex fully to honor OS accessibility settings? Recommendation: flex fully and fix any overflow rather than clamping — clamping is an accessibility violation.
- **Sentry DSN in CI**: where is the DSN stored for the release build pipeline? This must be resolved before Phase 8 distribution setup.
- **Integration test coverage threshold**: what percentage of line/branch coverage is the target for CI green gate? Recommend 80% unit/widget, best-effort for integration.
