## Why

The social and federation layers (Phases 3–5) are complete — every Listen, Like, Save, and Share activity is flowing across the network. Phase 6 turns that stream of real human listening data into a discovery engine: a Discover screen where every recommendation is attributed to a real person and a real reason, not an opaque algorithm. It also solves the cold-start problem head-on, because a federated app that shows nothing until you've built a social graph fails before it starts.

## What Changes

- New encrypted-at-rest **taste profile** stored locally — play counts, skip rates, saves, likes, and playlist adds aggregated into a scored signal store; never leaves the device unless the user explicitly shares it
- New **on-device recommendation engine** computing three signal paths: network trending (tracks appearing frequently across followed nodes), taste affinity (tracks liked/saved by nodes with overlapping listening patterns), and new-from-known (tracks by artists already in the user's library surfaced via the network)
- New **cold-start bootstrap path** that makes the app useful before the user follows anyone: server-light node discovery, genre/library overlap seeding, and an opt-in global trending relay
- New **Discover screen** organized around people and reasons — every recommendation shows who and why (name, face, provenance string); no anonymous algorithmic rows
- New **Phase 6 debug overlay tabs**: recommendation engine inspector, signal event log, and taste affinity matrix viewer

## Capabilities

### New Capabilities

- `signal-collection`: Capture and persist local signals (play count, skip rate, save, like, playlist add) and network signals (inbound Listen/Like/Save activities from followed nodes); aggregate into a structured taste profile encrypted at rest in Drift/SQLite; each signal carries a timestamp and assigned weight
- `recommendation-engine`: On-device scoring across three paths — network trending, taste affinity, new-from-known; produces a ranked, deduplicated candidate list with a provenance record attached to each result (which signal path, which person, which activity)
- `cold-start-bootstrap`: Server-light discovery of active nodes worth following; genre/library-overlap seed matching against the user's own library; opt-in global trending relay feed; ensures the app feels alive on day one with zero follows
- `discover-screen`: Provenance-first discovery UI — Discover tab in main nav; recommendations organized by people and reasons not algorithmic shelves; every item shows name, avatar, and a human-readable reason string ("Maya's been playing this", "3 people you follow saved this"); one-tap stream or save; honest offline/unavailable states per the network-state-primitives contract
- `recommendation-debug`: Phase 6 debug overlay additions — recommendation engine inspector (input signals, scored candidates, final ranked output, cold-start vs. graph path), signal event log (every play/skip/save with timestamp and weight), taste affinity matrix viewer (similarity scores between local node and each followed node); compile-time gated, dev-only

### Modified Capabilities

- `debug-overlay`: Add Phase 6 debug tabs (recommendation engine inspector, signal log, taste affinity matrix) — purely additive, no requirement changes to existing tabs

## Impact

- `lib/features/recommendations/` — new feature module: signal store, engine, cold-start bootstrap, discover screen
- `lib/features/recommendations/data/` — SignalStore (Drift table), TasteProfileRepository (encrypted), ColdStartRepository
- `lib/features/recommendations/domain/` — RecommendationEngine, ScoringPipeline, ProvenanceRecord model
- `lib/features/discover/` — DiscoverScreen, RecommendationCard, ProvenanceChip widgets
- `lib/shared/debug/` — Phase 6 overlay tabs added
- **Encrypted storage dependency**: flutter_secure_storage or equivalent for taste profile encryption at rest (private key already handled by secure enclave; taste profile needs its own encryption key derived and stored similarly)
- **No network protocol changes** — all recommendation logic is purely a consumer of existing ActivityPub signal data; no new ActivityPub activity types introduced
- **No breaking changes** to existing capabilities
