## Context

Nightingale is a greenfield Flutter application. Nothing exists yet — no project files, no packages, no UI. This design establishes the structural decisions that all subsequent phases inherit and cannot easily undo. Every choice made here (state management, navigation, DI, theme token shape, debug overlay activation strategy) becomes load-bearing once Phase 2 begins building on top of it.

Two principles drive design constraints above all others:
- **Humans, not handles** — the identity presentation layer must make it structurally difficult to accidentally surface raw `@user@node` strings in UI.
- **Honest network-state communication** — the network-state primitives must be real, first-class widgets in the shared component library, not placeholders or stubs.

## Goals / Non-Goals

**Goals:**
- Establish a folder structure that scales to 6+ phases without reorganization
- Select and wire state management, navigation, and DI so all future features follow one pattern
- Build a design token system flexible enough for dark/light mode and future theming
- Introduce network-state and identity-presentation primitives as canonical shared components
- Build a debug overlay that is compile-time gated — zero overhead in release, never activatable via shake
- Produce a working Flutter shell: app boots, theme applies, routes navigate, debug overlay opens in dev

**Non-Goals:**
- Any music playback (Phase 2)
- Any ActivityPub or networking (Phase 3+)
- Backend services, APIs, or server infrastructure
- Onboarding or authentication flows
- Production crash reporting configuration (stubbed only)
- Accessibility audit (Phase 7)

## Decisions

### D1 — Folder structure: feature-first under `lib/`

```
lib/
  core/           # App-wide infrastructure: DI, logging, env config, router
  features/       # One folder per product feature (empty in Phase 1)
  shared/
    components/   # Reusable widgets: design system, network-state, identity
    theme/        # Tokens: colors, typography, spacing, motion
    utils/        # Pure helpers with no Flutter dependency
```

**Why:** Feature-first keeps related code co-located as the project grows. `core/` isolates infrastructure that every feature imports but no feature owns. `shared/` is the design system boundary — anything a component in two different features needs lives here.

**Alternative considered:** Layer-first (`data/`, `domain/`, `presentation/`) — rejected because it scatters a single feature's code across three top-level directories, making feature-scoped changes harder to reason about and review.

### D2 — State management: Riverpod (code-generation variant)

Use `flutter_riverpod` + `riverpod_annotation` + `riverpod_generator` with `@riverpod` annotations and `build_runner` codegen.

**Why:** Riverpod's compile-time safety, testability without `BuildContext`, and provider scoping align with a federated app where many providers will be parameterized by node identity or stream source. Code generation eliminates boilerplate and enforces consistency.

**Alternative considered:** Bloc — more ceremony per feature, less ergonomic for derived async state chains. Provider (v1) — deprecated path. GetX — mixes too many concerns.

### D3 — Navigation: go_router with typed routes

Define a typed `AppRouter` class in `lib/core/router/`. All routes declared as `TypedGoRoute`-annotated classes; no string-based navigation anywhere in the codebase.

**Why:** Typed routes make route parameters compile-time checked. go_router's declarative, URL-based model maps cleanly to deep linking for federation use cases (e.g., opening a remote user's profile from an ActivityPub URI). Shell routes provide the persistent mini-player scaffold Phase 2 needs.

**Alternative considered:** Navigator 2.0 directly — too much boilerplate. auto_route — equivalent capability, go_router has stronger pub.dev maintenance signal.

### D4 — Dependency injection: get_it (service locator)

Register all repositories, services, and infrastructure singletons in `lib/core/di/service_locator.dart`. Riverpod providers access services via `get_it`; widgets never call `get_it` directly.

**Why:** get_it is simple, fast, and has no Flutter dependency — services remain pure Dart and testable in isolation. Riverpod providers are the access layer for UI; get_it is the wiring layer for services. Keeping these separate means providers can be unit-tested by registering mock services before the test runs.

**Alternative considered:** Riverpod-only DI (providers as singletons) — creates circular dependency risk and makes service registration order implicit. injectable — adds annotation overhead; get_it alone is sufficient for Phase 1 scope.

### D5 — Theme: token-first with `ThemeExtension`

Define all design tokens as Dart constants in `lib/shared/theme/`:
- `AppColors` — near-monochromatic base palette, single accent, semantic aliases (`onSurface`, `surfaceVariant`, etc.)
- `AppTypography` — `TextTheme` built from a defined type scale (5–6 sizes, 2 weights)
- `AppSpacing` — spacing grid as named constants (`xs`, `sm`, `md`, `lg`, `xl`, `xxl`)
- `AppRadius` — border-radius constants
- `AppMotion` — `Duration` and `Curve` constants for every animation category (micro, standard, emphasis)

Package tokens into a custom `ThemeExtension<AppTokens>` so any widget can access `Theme.of(context).extension<AppTokens>()` without importing token files directly.

Dark and light `ThemeData` instances are built from the same tokens with semantic color aliases resolved differently per mode.

**Why:** Token-first prevents magic numbers from spreading across the codebase. `ThemeExtension` keeps tokens inside Flutter's theme system, so they respond correctly to `Theme.of` and `MediaQuery` without prop-drilling.

### D6 — Network-state primitives: explicit sealed widget hierarchy

Define a sealed class `NetworkStateWidget` in `lib/shared/components/network_state/` with four concrete variants:

- `BufferingWidget` — spinner + label, used when a remote stream is loading
- `HostOfflineWidget` — offline icon + name of host + last-seen time
- `StreamFailedPlayingLocalWidget` — subtle banner indicating fallback to cached local copy
- `PartialLibraryWidget` — indicator that a remote library is partially loaded

Each variant is a real, styled widget using design tokens — not a `Placeholder` or `TODO`. They must be visually distinct, calm, and intentional (per design principles: "unavailability should feel intentional, never broken").

**Why:** Building these now forces the shared vocabulary to exist before any feature that needs it. If they are deferred, Phase 2 invents ad-hoc loading states that Phase 3 then has to rip out. Making them sealed prevents accidental variants sprouting across features.

### D7 — Identity presentation: `PersonDisplay` widget enforced at the type level

`PersonDisplay` in `lib/shared/components/identity/` accepts:
- `displayName` (required String)
- `avatarUrl` (optional String)
- `handle` (optional String — the raw `@user@node`) — **never rendered by default**
- `showHandle` (bool, defaults `false`) — only `true` in settings/advanced contexts

No other widget in the codebase renders a raw fediverse handle string. Any feature that needs to show a person routes through `PersonDisplay`.

**Why:** Making the handle opt-in at the widget level makes it structurally hard to accidentally leak protocol details into normal UI. A code reviewer can grep for `showHandle: true` to audit every place a handle surfaces.

### D8 — Debug overlay: compile-time gated, tap-sequence activated

The debug overlay lives entirely inside `#if kDebugMode` guards (or a `debugOverlay` compile-time flag). Release builds contain zero overlay code via Flutter's tree-shaking of `kDebugMode` branches.

Activation: in debug builds, a hidden `GestureDetector` wrapping the root navigator detects a 7-tap sequence on the app version label in the Settings screen (or an equivalent dev-only FAB on the home screen). **No shake gesture.** Shake collides with iOS accessibility (Undo) and is unreliable on simulators.

The overlay is a `Stack` widget inserted above the navigator — it never interferes with navigation or widget tests.

Tabs in Phase 1: **Logs** (filterable by level/tag), **Info** (version, build, env, route).

**Why:** Shake is explicitly excluded in the ROADMAP. Tap-sequence is reliable, invisible in production (because the overlay code doesn't exist), and doesn't collide with any system gesture.

### D9 — Logging: typed structured events over `dart:developer`

`AppLogger` wraps `dart:developer`'s `log()` with:
- Severity levels: `verbose`, `debug`, `info`, `warning`, `error`, `fatal`
- Tag system: callers provide a tag (`'auth'`, `'playback'`, `'federation'`) for filtering
- In debug builds: emits to the in-app overlay log stream (via a `StreamController`) and to `dart:developer`
- In release builds: no-ops to console; crash-reporting hook receives `error`/`fatal` only

**Why:** Raw `print()` and `debugPrint()` are untraceable in the overlay and can't be filtered. Typed log events let the overlay UI filter by severity and tag. The `StreamController` approach keeps logging non-blocking.

## Risks / Trade-offs

**[Riverpod code-generation adds build_runner step]** → Mitigation: add `build_runner watch` to the dev workflow script from day one; document it in the project README. All generated files are committed to avoid CI cold-start delays.

**[get_it service locator is a global registry — hard to test if misused]** → Mitigation: enforce the contract that only Riverpod providers call `get_it`; widgets go through providers. Document in `ARCHITECTURE.md`.

**[ThemeExtension lookup adds a small runtime cost per widget build]** → Mitigation: acceptable at Phase 1 scale; profile in Phase 7 if needed. Tokens are read-only and the extension is cached by the InheritedWidget mechanism.

**[Network-state widgets built before any real network exists]** → They are UI-only; they don't depend on network code. Phase 3 will wire real state into them. Risk is that their API is wrong when real states arrive — mitigation: design their constructors to accept generic `status` and `label` params rather than hard-coded strings, so Phase 3 can pass real data without API breakage.

**[Debug overlay Stack inserted above navigator can intercept gestures]** → Mitigation: use `IgnorePointer` wrapping overlay content when it is collapsed; only the activation handle and the open overlay receive touches.

## Open Questions

- **Minimum Flutter SDK version**: 3.22 (stable as of writing) is the target. Confirm no Phase 2 package (`just_audio`) requires a higher minimum before locking it.
- **Crash reporting provider**: Sentry vs. Firebase Crashlytics. Stub accepts either; decision deferred to Phase 2 or 3 when the app has real error surfaces.
- **`riverpod_generator` vs. manual providers**: Start with codegen. If build times become painful, evaluate selective manual providers for hot-path providers in Phase 2.
