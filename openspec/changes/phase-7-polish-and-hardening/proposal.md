## Why

Phases 1–6 have delivered every feature of the nightingale federated music player — foundation, local playback, node identity, library federation with best-effort streaming, social layer, and recommendations. Phase 7 is the finishing pass: everything that exists is sharpened, hardened against real-world failure modes, made fully accessible, and proven through a comprehensive test suite before distribution.

## What Changes

- **Onboarding flow** — first-launch experience that sets up node identity and the key-migration story without ever exposing a raw handle or cryptographic detail to the user
- **UX polish** — entrance/exit choreography, state-transition animations, and loading states audited and tightened across every screen; empty states added for every list and feed; haptic feedback mapped to meaningful moments (track start, save, error)
- **Network-state surface refinement** — the buffering, host-offline, stream-failed-playing-local, and partial-library components built in Phase 1 are polished so each mode feels calm and intentional, never broken
- **Offline resilience** — full local playback when offline; federated activities queued and delivered on reconnect; library database corruption detected and repaired automatically
- **Graceful degradation** — when a remote node is unreachable, playback skips cleanly to next available source (cache → relay → local) with honest status surfaced to the user
- **Accessibility** — full VoiceOver/TalkBack support, WCAG AA color contrast, minimum touch targets, and dynamic type throughout
- **Performance** — startup time, feed rendering (large lists, image loading), extended-playback memory, background-federation battery usage, and stream buffering / cache eviction all profiled and optimized
- **Test coverage** — unit tests for all core algorithms (recommendation logic, cold-start bootstrap, ActivityPub serialization, HTTP Signature + replay protection, acoustic fingerprinting/dedup, stream authentication, key migration); widget tests for player controls, feed, library views, and network-state components; integration tests for the full federation round-trip including host-drop fallback
- **Performance debug overlay** — new Phase 7 tab in the compile-time-gated dev overlay: frame render times, memory, network byte counts, stream latency, cache hit rate
- **Production error reporting** — non-PII crash/error reporting wired into release builds and connected to an external dashboard; all diagnostic code stripped from release via compile-time flags

## Capabilities

### New Capabilities
- `onboarding-flow`: First-launch experience — node identity creation, key-migration story, "humans not handles" framing throughout; zero technical complexity exposed to the user
- `ux-polish`: Animation choreography, empty states for every list/feed, haptic feedback, and network-state surface refinement (calm + intentional, not error-like)
- `offline-resilience`: Offline mode (local playback continues, federated activities queued), graceful degradation on remote-node unreachability, and local database corruption recovery
- `accessibility`: Full VoiceOver/TalkBack support, WCAG AA color contrast audit, minimum touch-target enforcement, and dynamic type support
- `performance-optimization`: Startup-time profiling, feed-rendering performance, extended-playback memory profile, background-federation battery audit, stream-buffer and cache-eviction tuning
- `test-coverage`: Comprehensive unit, widget, and integration test suite covering all federated-player-specific logic
- `performance-debug-overlay`: Phase 7 additions to the compile-time-gated dev overlay — performance tab (frame times, memory, network bytes, stream latency, cache hit rate) and production error reporting wired for release builds

### Modified Capabilities
- `network-state-primitives`: Adding specific behavioral requirements for the "calm, not broken" polish pass — defined animation durations, haptic mappings, and copy tone for each degraded-state variant
- `debug-infrastructure`: Production crash/error reporting was stubbed in Phase 1 ("stubbed for prod wiring later") — Phase 7 wires it fully, adds the non-PII constraint, and establishes the compile-time flag that strips all diagnostic code from release builds

## Impact

- **lib/features/onboarding/** — new feature module
- **lib/shared/components/network_state/** — animation and haptic refinements to existing network-state primitives
- **lib/shared/components/** — empty-state widgets added to all list/feed views
- **lib/core/resilience/** — offline mode coordinator, activity queue, DB corruption recovery
- **lib/core/performance/** — startup and feed rendering optimizations
- **lib/core/debug/** — performance overlay tab, production error reporting wiring, compile-time strip flags
- **test/** — new unit, widget, and integration test directories covering all federated-player algorithms
- No new external dependencies expected; all work refines and hardens existing code
