## Context

Phases 3–5 established the full federation stack: ActivityPub identity, library sharing, audio streaming, and a live social graph. Listen, Like, Save, and Announce activities are already flowing between nodes and stored locally. Phase 6 is a pure consumer of that data — it adds no new ActivityPub activity types and changes no network protocol. Its job is to aggregate the signals already on-device, run a scoring pass, and surface results through a provenance-first Discover screen.

The taste profile is new sensitive data. Unlike the music library (track titles are not sensitive), a user's listening patterns, skip rates, and affinity scores are genuinely private. The encryption strategy mirrors the approach taken for the private key: data is encrypted at rest and never leaves the device unless the user explicitly opts to share it.

Cold start is the most common failure mode of decentralized social apps: a new user follows nobody, so every graph-derived signal is empty, and the app feels dead. This phase treats cold start as a first-class problem with its own dedicated code path, not a "handle later" edge case.

---

## Goals / Non-Goals

**Goals:**
- Surface relevant track and node recommendations derived from the user's own library and their social graph, entirely on-device
- Make the app feel alive on day one with zero follows via the cold-start bootstrap path
- Attach a human-readable provenance reason to every recommendation ("Maya's been playing this", "3 people you follow saved this")
- Encrypt the taste profile at rest so it is never accessible in plaintext outside the app
- Ship Phase 6 debug tooling: engine inspector, signal log, taste affinity matrix viewer

**Non-Goals:**
- A central recommendation server — all logic runs on-device; no telemetry or signal data is transmitted without explicit user action
- Collaborative filtering at network scale — affinity is computed only against followed nodes, not the full fediverse
- Real-time signal processing — signals are batched and scored on a scheduled pass, not streamed
- New ActivityPub activity types — recommendation signals are derived from existing Listen/Like/Save/Announce activities only
- Machine learning models — the scoring algorithm is a transparent, deterministic weighted formula; no opaque model weights

---

## Decisions

### 1. On-Device Scoring with a Deterministic Weighted Formula

**Decision:** All recommendation logic runs locally as a deterministic weighted scoring function, not an ML model or a remote API.

**Rationale:** The ROADMAP explicitly requires "no black-box algorithm" and "all logic runs on-device." A deterministic formula is fully inspectable — the debug overlay can show every score and the signals that produced it. It is also fast, requires no model training infrastructure, and degrades gracefully when signal data is sparse (cold start).

**Alternative considered:** A lightweight on-device ML model (e.g., a simple collaborative filtering embedding). Rejected: adds dependency weight, requires training data that doesn't exist at launch, and produces scores the user cannot audit.

---

### 2. Taste Profile: Drift Table + Envelope Encryption

**Decision:** The taste profile is stored in a dedicated Drift table (`signal_store`) and the entire table is encrypted at rest using an AES-256 key that is itself stored in the platform secure enclave (iOS Keychain / Android Keystore). The key derivation follows the same pattern already established for the node's private key in Phase 3.

**Rationale:** The rest of the Drift database (library, activities) is intentionally unencrypted — the ROADMAP notes that track metadata is not sensitive and encryption adds friction for no benefit. The taste profile is different: it encodes what the user loves, skips, and ignores. Encrypting only the sensitive table avoids blanket database encryption overhead while protecting what actually needs protecting.

**Alternative considered:** Full database encryption via SQLCipher. Rejected: encrypts non-sensitive library data needlessly, adds a native dependency, and complicates backup/restore.

**Alternative considered:** Storing the taste profile in flutter_secure_storage directly (key-value). Rejected: taste profile is a structured dataset (hundreds of track scores, per-node affinity vectors) that requires queryable relational storage, not a key-value store.

**Implementation note:** At first launch after Phase 6, the app generates a taste profile key, stores it in the secure enclave, and uses it to encrypt the signal store. The key never appears in plaintext in app memory beyond the duration of a single read/write transaction.

---

### 3. Three-Path Scoring Pipeline

**Decision:** The recommendation engine runs three independent scoring paths and merges the results:

| Path | Signal Source | Primary Use |
|---|---|---|
| **Network Trending** | Listen activity frequency across followed nodes in a rolling 7-day window | Surface what the local social graph is into right now |
| **Taste Affinity** | Cosine similarity between the local taste vector and each followed node's taste vector (derived from their shared Listen/Like/Save activities) | Surface what people with similar taste are saving and liking |
| **New From Known** | Artist overlap: tracks by artists already in the user's library, surfaced via the network | Low-risk discovery; familiar artists, new tracks |

Each path produces a scored candidate list. Candidates are merged by track identity (using the acoustic fingerprint deduplication from Phase 4), scores are summed across paths, and duplicates with already-owned/saved tracks are filtered out. The final ranked list carries a `ProvenanceRecord` noting which path(s) contributed and the top human reason string.

**Alternative considered:** A single unified scoring function combining all signals. Rejected: harder to debug (which signals produced this result?), harder to present provenance clearly in the UI.

---

### 4. ProvenanceRecord as a First-Class Model

**Decision:** Every recommendation result carries a `ProvenanceRecord` — a structured value object containing: contributing signal paths, the top contributing actor (if any), their display name and avatar URL, and a pre-rendered reason string. The reason string is constructed in the engine, not the UI.

**Rationale:** The ROADMAP states "provenance is the entire differentiator from Spotify." If provenance is an afterthought assembled in a widget, it will be shallow. By making `ProvenanceRecord` a first-class domain model produced by the engine, it is testable, stable, and carries full actor context regardless of which widget renders it. The reason strings use a small set of templates: `"<Name> has had this on repeat"`, `"<N> people you follow saved this"`, `"New from an artist in your library"`.

---

### 5. Cold-Start Bootstrap as a Separate Code Path

**Decision:** Cold start is a distinct module (`ColdStartRepository`) that runs when `followingCount == 0` or when graph-derived signals are below a minimum threshold. It operates three mechanisms in order of preference:

1. **Genre/library overlap matching** — compare the user's own library genre tags against cached genre metadata from any nodes already known to the app (e.g., nodes that have delivered activities to our inbox even without a follow relationship). Requires no network call.
2. **Server-light node discovery** — query a lightweight well-known discovery endpoint (a simple JSON list of active nodes willing to be discovered; not a central recommendation server) to surface candidate nodes worth following.
3. **Opt-in global trending relay** — if the user opts in, fetch a trending track list from a community-operated relay. Treated as a supplementary feed, not the primary path.

Cold start dissolves automatically as the user's social graph grows — the engine switches to the full three-path pipeline once following count and signal density exceed a minimum threshold.

**Alternative considered:** Showing nothing until the user follows someone, with an explicit onboarding prompt. Rejected: the ROADMAP explicitly calls this out as the failure mode to avoid. The app must feel alive on day one.

---

### 6. Discover Screen Architecture

**Decision:** Discover is a new top-level tab in the main navigation (go_router route `/discover`). The screen is a single scrollable list of `RecommendationCard` widgets grouped by provenance section headers (e.g., "What your people are into", "New from your artists"). Each card shows: artwork, title, artist, a `ProvenanceChip` (avatar + reason string), and two actions: stream (primary) and save (secondary). Stream action uses the existing best-effort audio streaming from Phase 4 with the standard network-state-primitives overlay for offline/buffering states.

The screen drives from a `DiscoverNotifier` (Riverpod `AsyncNotifier`) that calls the `RecommendationEngine`. Refresh is manual (pull-to-refresh) plus a background periodic refresh on app foreground. Results are cached in memory for the session to avoid re-scoring on every scroll.

---

## Risks / Trade-offs

**[Risk] Taste vector similarity requires enough signal to be meaningful** → Mitigation: the cold-start path handles the zero-signal case; affinity scoring is gated behind a minimum signal count threshold (e.g., ≥ 10 play events on the local node before affinity comparisons are attempted). Below threshold, fall back to trending and new-from-known only.

**[Risk] Cold-start discovery endpoint is a de facto central dependency** → Mitigation: the discovery endpoint is fully optional and opt-in at launch; the app works without it (genre matching still runs). Long-term, the endpoint can be community-operated and replicated. It serves only a list of node URLs — no user data flows to it.

**[Risk] Taste profile key loss on device wipe means signal history is unrecoverable** → Mitigation: the taste profile is reconstructable over time from ongoing listening activity; it is not a permanent record. Document this clearly. Key migration (backup/restore) is a Phase 7 / polish concern; this phase establishes the encryption contract only.

**[Risk] ProvenanceRecord requires actor display data (name, avatar) to be locally cached** → Mitigation: actor display data is already cached from Phase 5 social graph following. For cold-start recommendations where actors are not yet followed, provenance degrades gracefully to a generic reason string without an avatar ("Trending across the network").

**[Risk] Scoring performance on low-end devices with large libraries** → Mitigation: scoring runs on a background isolate (Dart `Isolate.spawn` or `compute`), never on the UI thread. Results are cached; the UI never blocks on a score pass.

---

## Migration Plan

This phase introduces no breaking changes to existing data or federation behavior. The `signal_store` Drift table is a new migration (e.g., migration version N+1). The cold-start module activates automatically for users with no follows. The Discover tab appears in the navigation rail/bottom bar on upgrade; it can be dismissed or reordered in settings.

Rollout is self-contained: enabling Phase 6 does not alter how Listen/Like/Save activities are published or stored in Phase 4/5 tables — it only adds new derived tables and a new consumer.

---

## Open Questions

1. **Discovery endpoint governance** — who operates the server-light discovery list at launch? Should it be a community-maintained static JSON file in a public repository, or a minimal hosted service? The implementation does not depend on this answer, but the launch plan does.
2. **Provenance reason string localization** — reason strings are pre-rendered in the engine. Should they be localized template strings from the app's ARB files, or English-only for launch? Recommend ARB from the start to avoid a painful retrofit.
3. **Taste profile export / portability** — the ROADMAP account portability story (Phase 3) covers identity and social graph. Should the taste profile be included in the migration bundle? It adds value but also complexity. Leave as an open question for Phase 7 polish.
