## 1. Module Scaffolding

- [x] 1.1 Create `lib/features/recommendations/` directory tree: `data/`, `domain/`, `presentation/`
- [x] 1.2 Create `lib/features/discover/` directory tree: `presentation/`, `widgets/`
- [x] 1.3 Add any new pub dependencies (e.g., `encrypt` or `pointycastle` for AES-256 envelope encryption) to `pubspec.yaml`
- [x] 1.4 Create Riverpod provider barrel file `lib/features/recommendations/recommendations_providers.dart`

## 2. Taste Profile Encryption Setup

- [x] 2.1 Implement `TasteProfileKeyStore` — generates and retrieves the AES-256 encryption key from the platform secure enclave (iOS Keychain / Android Keystore), mirroring the Phase 3 private key pattern
- [x] 2.2 Implement `EncryptedSignalStore` wrapper around Drift that encrypts row data using the taste profile key before write and decrypts on read
- [x] 2.3 Write unit test: signal store read fails when called before key is loaded from enclave
- [x] 2.4 Write unit test: first-launch key generation creates and stores a valid AES-256 key

## 3. Signal Collection — Data Layer

- [x] 3.1 Write Drift migration adding the `signal_events` table: columns `id`, `track_fingerprint`, `event_type`, `source_actor_id` (nullable), `timestamp_utc`, `weight`
- [x] 3.2 Write Drift migration adding the `taste_scores` table: columns `track_fingerprint`, `score` (aggregated sum of weights)
- [x] 3.3 Implement `SignalDao` with methods: `insertEvent(SignalEvent)`, `updateScore(fingerprint, delta)`, `getScoreForTrack(fingerprint)`, `getScoresAboveThreshold(minScore)`, `getRecentNetworkEvents(sinceUtc, actorIds)`
- [x] 3.4 Implement `SignalRepository` wrapping `SignalDao`, applying encryption via `EncryptedSignalStore`

## 4. Signal Collection — Event Capture

- [x] 4.1 Hook into `PlaybackEngine` to emit a `play` signal event when a track crosses the 30-second threshold
- [x] 4.2 Hook into `PlaybackEngine` to emit a `skip` signal event when a track is skipped before 30 seconds
- [x] 4.3 Hook into the save action (all surfaces) to emit a `save` signal event
- [x] 4.4 Hook into the Like activity flow to emit a `like` signal event
- [x] 4.5 Hook into playlist add to emit a `playlist_add` signal event
- [x] 4.6 Implement `NetworkSignalIngester` — Riverpod listener on the ActivityPub inbox stream that writes `network_listen` and `network_like` events for activities from followed, non-blocked actors
- [x] 4.7 Write unit tests: each local event type writes the correct signal row; blocked actor activities are excluded from ingestion

## 5. Recommendation Engine — Core

- [x] 5.1 Define `ProvenanceRecord` value object: `paths`, `topActorId`, `topActorDisplayName`, `reasonString`
- [x] 5.2 Define `RecommendationResult` value object: `track`, `score`, `provenance`
- [x] 5.3 Implement `NetworkTrendingScorer` — queries network signal events in the past 7-day window, groups by track fingerprint, counts distinct source actors, produces `List<RecommendationResult>` with trending provenance records
- [x] 5.4 Implement `TasteAffinityScorer` — computes per-actor taste vectors from shared Listen/Like/Save signals, computes cosine similarity against local taste scores, surfaces high-affinity actors' saved/liked tracks; gates on minimum local signal count
- [x] 5.5 Implement `NewFromKnownScorer` — cross-references network activity artists against local library artist list (case-insensitive normalized), excludes already-owned tracks
- [x] 5.6 Implement `ScoringPipeline` — runs all three scorers (or delegates to `ColdStartRepository`), merges candidate lists, deduplicates by acoustic fingerprint, filters already-owned tracks, sorts by combined score, attaches final `ProvenanceRecord` per result
- [x] 5.7 Implement `RecommendationEngine` Riverpod `AsyncNotifier` that runs `ScoringPipeline` on a background isolate and caches the result for the session
- [x] 5.8 Write unit tests: trending scorer counts distinct actors not raw events; affinity scorer inactive below threshold; new-from-known excludes owned tracks; deduplication merges fingerprint-matched candidates

## 6. Cold-Start Bootstrap

- [x] 6.1 Implement `ColdStartRepository` with activation guard: returns early if `followingCount > 0` and signal density exceeds threshold
- [x] 6.2 Implement genre/library overlap matching — extract genre tags from local library, match against cached remote library metadata in the local Drift store, return scored node suggestions
- [x] 6.3 Implement `NodeDiscoveryService` — unauthenticated GET to the well-known discovery endpoint; parses JSON list of `{nodeUrl, displayName, genreTags, trackCount}`; returns empty list on error with no user-visible error
- [x] 6.4 Implement `GlobalTrendingRelayService` — fetches relay trending list only when user has opted in; returns empty list when opt-in is false or relay is unavailable
- [x] 6.5 Implement `ColdStartSettingsRepository` — stores user preferences for discovery endpoint opt-in and global trending opt-in; ensures trending is disabled by default
- [x] 6.6 Verify: cold-start discovery requests contain no Authorization header, actor ID, or user data
- [x] 6.7 Write unit tests: cold-start deactivates when following > 0; trending relay returns empty when opt-in is false; discovery error leaves app in usable state

## 6b. Cold-Start Fixes

- [x] 6b.1 Fix node discovery default: `isDiscoveryEnabled()` SHALL return `true` when no preference is stored — discovery is opt-out, not opt-in
- [x] 6b.2 Fix `DiscoverEmptyState` CTA: replace "Add music" → Library with "Find people to follow" → `/social/find`
- [x] 6b.3 Add Discover section to `FederationSettingsScreen`: toggle for node discovery (default on, opt-out), toggle for global trending relay (default off, explicit opt-in with privacy note)

## 7. Discover Screen — UI

- [x] 7.1 Register `/discover` route in go_router and add the Discover tab to the main navigation rail/bottom bar
- [x] 7.2 Implement `DiscoverScreen` widget — `AsyncNotifier`-driven scrollable list organized into provenance section groups; pull-to-refresh triggers rescore
- [x] 7.3 Implement `ProvenanceChip` widget — circular actor avatar (with graceful placeholder), display name (never raw handle), reason string; uses `PersonDisplay` primitive from Phase 1
- [x] 7.4 Implement `RecommendationCard` widget — artwork, title, artist, `ProvenanceChip`, stream action (primary), save action (secondary); one primary CTA only per design system rule
- [x] 7.5 Wire stream action to Phase 4 `PlaybackEngine` best-effort stream path; show `network-state-primitives` overlay for offline/buffering/cached states on the card
- [x] 7.6 Wire save action to `SignalRepository` save event emission and to the library save queue
- [x] 7.7 Implement `DiscoverEmptyState` widget — on-brand empty state with human explanation and a single suggested action; shown only when all scoring paths and cold-start return empty
- [x] 7.8 Implement section headers — human-readable section labels ("What your people are into", "From artists you already love", "Trending in your network"); omit sections with zero results
- [x] 7.9 Ensure typography hierarchy carries the layout: titles and reason strings sized per the Phase 1 type scale; color near-monochromatic with accent only on stream action

## 8. Phase 6 Debug Overlay

- [x] 8.1 Implement `RecommendationInspectorPanel` (dev only) — shows last scoring pass: per-path candidate lists with scores, merged output, per-result path label (Trending / Affinity / New-from-Known / Cold-Start), and active cold-start mechanisms
- [x] 8.2 Implement `SignalEventLogPanel` (dev only) — real-time in-memory list of signal events in the current session: type, fingerprint (truncated), timestamp, weight; supports filter by event type
- [x] 8.3 Implement `AffinityMatrixPanel` (dev only) — lists each followed node's display name and cosine similarity score (0.0–1.0) sorted descending; shows "Insufficient data" for nodes below threshold
- [x] 8.4 Register the three new panels as tabs ("Rec Engine", "Signals", "Affinity") in the existing debug overlay tab bar
- [x] 8.5 Gate all three panels behind `kDebugMode` compile-time constant; verify no panel code is reachable in a release build
- [x] 8.6 Verify panels are accessible only via the existing tap-sequence overlay entry point, not via shake gesture

## 9. Integration & Wiring

- [x] 9.1 Wire `NetworkSignalIngester` into the app startup sequence so it begins listening on ActivityPub inbox stream at launch
- [x] 9.2 Wire background periodic rescore: trigger a new scoring pass when the app foregrounds after the configured minimum interval (default: 30 minutes)
- [x] 9.3 Wire new-follow event to invalidate the recommendation cache and trigger a rescore (follow count change is a significant signal event)
- [x] 9.4 Verify signal data is absent from all outgoing ActivityPub payloads (outbox, inbox delivery, any federation HTTP request body)

## 10. Testing

- [x] 10.1 Unit tests: `ScoringPipeline` end-to-end with fixture signal data — verify trending, affinity, and new-from-known paths each produce correctly ranked results with correct provenance records
- [x] 10.2 Unit tests: `TasteProfileKeyStore` — key generation, retrieval, and encryption/decryption round-trip
- [x] 10.3 Unit tests: cold-start bootstrap activation guard — activates at zero follows, deactivates above threshold
- [x] 10.4 Widget tests: `RecommendationCard` — provenance chip renders display name not handle; stream action triggers playback; save action updates card state
- [x] 10.5 Widget tests: `DiscoverScreen` — empty state shown when no results; sections absent when path returns empty; pull-to-refresh triggers rescore
- [x] 10.6 Integration test: full round-trip — ingest a Listen activity from a followed node → signal written → scoring pass runs → track appears in Discover screen with correct provenance
