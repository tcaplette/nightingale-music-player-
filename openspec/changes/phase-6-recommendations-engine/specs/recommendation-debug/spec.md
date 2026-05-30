## ADDED Requirements

### Requirement: Recommendation engine inspector tab
The in-app debug overlay SHALL include a new "Recommendations" tab (Phase 6 addition) that displays the most recent scoring pass in full detail: input signals summary, per-path candidate lists with individual scores, the merged and ranked final output, and a label on each result indicating which path(s) — cold-start, trending, affinity, or new-from-known — produced it.

#### Scenario: Inspector shows per-path breakdown
- **WHEN** the developer opens the Recommendations tab after a scoring pass
- **THEN** the tab displays three expandable sections (Trending, Affinity, New-from-Known), each listing its candidate tracks with scores; a fourth section shows the merged final output

#### Scenario: Cold-start path clearly labeled
- **WHEN** the engine used the cold-start path for any or all results
- **THEN** each cold-start result is labeled "Cold Start" and the active cold-start mechanisms (genre match, discovery, relay) are listed in the inspector

#### Scenario: Inspector is compile-time gated
- **WHEN** the app is built in release mode
- **THEN** the Recommendations inspector tab does not exist in the binary; no code path reaches it

---

### Requirement: Signal event log
The debug overlay SHALL include a signal event log showing every signal event written to the signal store in the current session: event type (play, skip, save, like, network_listen, etc.), track fingerprint (truncated), timestamp, and the weight applied.

#### Scenario: Signal log shows real-time events
- **WHEN** the user plays, skips, or saves a track while the signal log tab is open
- **THEN** a new entry appears in the log immediately

#### Scenario: Signal log filterable by event type
- **WHEN** the developer selects a filter (e.g., "skips only")
- **THEN** the log displays only events of that type

#### Scenario: Signal log does not persist across sessions
- **WHEN** the app is restarted
- **THEN** the in-memory signal log is cleared; only the persisted signal store remains

---

### Requirement: Taste affinity matrix viewer
The debug overlay SHALL include a taste affinity matrix viewer showing the cosine similarity score between the local node and each followed node. The matrix is read-only and shows node display names (never raw handles) alongside their similarity scores.

#### Scenario: Matrix shows similarity scores for all followed nodes
- **WHEN** the developer opens the affinity matrix viewer
- **THEN** each followed node is listed with its computed similarity score (0.0–1.0), sorted descending

#### Scenario: Matrix shows "insufficient data" for nodes below threshold
- **WHEN** a followed node has fewer signal events than the affinity threshold requires
- **THEN** their row displays "Insufficient data" instead of a score

#### Scenario: Matrix viewer is dev-only
- **WHEN** the app is built in release mode
- **THEN** the affinity matrix viewer tab does not exist in the binary

---

### Requirement: Debug tooling compile-time gated and never shake-activated
All Phase 6 debug panels SHALL be gated behind a compile-time `kDebugMode` or equivalent flag. They SHALL be accessible only through the existing dev-build debug overlay entry point (tap-sequence in settings or dev-build-only button), never through a shake gesture.

#### Scenario: No debug data in release build
- **WHEN** the app is compiled in release mode
- **THEN** no recommendation engine data, signal log, or affinity matrix is reachable through any code path

#### Scenario: Debug panels non-blocking
- **WHEN** any Phase 6 debug panel is open and visible
- **THEN** the recommendation engine, signal collection, and app state continue operating normally without interference
