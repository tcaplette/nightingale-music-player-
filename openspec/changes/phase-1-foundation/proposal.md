## Why

Nightingale's federated music player has no project structure, no shared vocabulary for UI states, and no debugging layer — before any feature can be built, the scaffolding that every subsequent phase depends on must exist and embody the product's two non-negotiable principles from the first commit: that people are shown as humans (not raw protocol handles), and that network uncertainty is communicated honestly rather than hidden. Building this foundation now prevents retrofitting these principles into a codebase that has grown without them.

## What Changes

- Flutter project initialized with a defined minimum SDK, monorepo-friendly folder layout (`lib/core`, `lib/features`, `lib/shared`), and enforced lint/format rules
- Riverpod state management scaffolded as the canonical pattern across all features
- `go_router` navigation layer established with typed routes
- Dependency injection container wired; repository pattern defined for all data sources
- Token-based design system created: typography scale, color palette, spacing grid, radius constants, motion constants (duration + easing curves)
- Base component library built: buttons, cards, inputs, bottom sheets, modals — dark and light mode from day one
- **Network-state UI primitives** introduced as first-class shared components: `BufferingState`, `HostOfflineState`, `StreamFailedPlayingLocalState`, `PartialLibraryState` — not afterthoughts
- **Identity presentation primitive** introduced: a `PersonDisplay` widget that shows a name and avatar; the raw `@user@node` handle is metadata only, surfaced in advanced/settings contexts
- Structured logging layer (`AppLogger` over `dart:developer`) with typed, filterable log events
- In-app debug overlay (dev builds only) with log stream, app version, environment, and current route — activated via a dev-only tap sequence, **never shake**, never present in release builds
- Error boundary widgets for graceful Flutter error display in dev
- Crash reporting hook stubbed for production wiring in a later phase
- Network request inspector (dev only)

## Capabilities

### New Capabilities

- `project-setup`: Flutter project scaffolding — SDK version, folder structure (`lib/core`, `lib/features`, `lib/shared`), environment config (dev/staging/prod), linting and formatting rules
- `architecture-foundation`: Riverpod state management, go_router navigation, dependency injection container, and repository pattern scaffolding
- `design-system`: Token-based theme (typography, color, spacing, radius, motion), base component library, dark/light mode
- `network-state-primitives`: First-class shared UI components for buffering, host-offline, stream-failed-playing-local, and partial-library states
- `identity-presentation`: `PersonDisplay` primitive — name + avatar, handle as hidden metadata; establishes the "humans, not handles" contract for all future UI
- `debug-infrastructure`: Structured logging, in-app debug overlay (dev-only, tap-sequence activation), error boundary widgets, crash reporting stub, network request inspector

### Modified Capabilities

## Impact

- No existing code is affected — this is greenfield
- All subsequent phases (`phase-2-core-player` onward) build on the folder structure, architecture patterns, design tokens, and debug overlay established here
- The `network-state-primitives` and `identity-presentation` capabilities define a vocabulary that Phase 2 (player UI) and Phase 3 (federation) must consume — changing them later would be a breaking refactor
- Dependency additions: `flutter_riverpod`, `riverpod_annotation`, `go_router`, `get_it`, `logger` (or equivalent); dev dependencies: `flutter_lints`, custom analysis options
