## ADDED Requirements

### Requirement: Three-path scoring pipeline
The recommendation engine SHALL score candidates using three independent paths — network trending, taste affinity, and new-from-known — and produce a single merged, ranked result list. Each result SHALL carry a `ProvenanceRecord` identifying which path(s) contributed and the top human-readable reason.

#### Scenario: Full pipeline runs when social graph is populated
- **WHEN** the user follows at least one node and local signal count meets the minimum threshold
- **THEN** the engine runs all three scoring paths, merges candidates, deduplicates by acoustic fingerprint, and returns the ranked list with provenance records attached

#### Scenario: Engine falls back to cold-start when graph is empty
- **WHEN** the user follows zero nodes or signal count is below the minimum threshold
- **THEN** the engine delegates entirely to the `ColdStartRepository` for candidate generation

---

### Requirement: Network trending path
The engine SHALL compute a trending score for each track by counting how many distinct followed nodes included it in a Listen activity within a rolling 7-day window. Tracks appearing on more followed nodes score higher.

#### Scenario: Track trending across multiple followed nodes
- **WHEN** a track appears in Listen activities from three distinct followed nodes in the past 7 days
- **THEN** its trending score reflects all three contributions and it ranks above a track with only one such contribution

#### Scenario: Repeat listens by the same node count once
- **WHEN** the same followed node has ten Listen activities for the same track
- **THEN** the trending score counts that node as one contributor, not ten

---

### Requirement: Taste affinity path
The engine SHALL compute a cosine similarity score between the local user's taste vector (derived from aggregated local signals) and each followed node's observable taste vector (derived from their shared Listen/Like/Save activities). Tracks liked or saved by high-affinity nodes score higher in this path.

#### Scenario: High-affinity node's saves surface as recommendations
- **WHEN** a followed node has high cosine similarity to the local taste vector and has saved a track the user does not own
- **THEN** that track appears in the affinity path results with a `ProvenanceRecord` naming that node

#### Scenario: Affinity path inactive below signal threshold
- **WHEN** the local signal store contains fewer than the minimum required events (e.g., 10 play events)
- **THEN** the affinity path returns an empty candidate list and the engine proceeds with the other two paths only

---

### Requirement: New-from-known path
The engine SHALL surface tracks by artists already present in the user's local library that have been shared or listened to on the network but are not already in the user's library. Artist matching is case-insensitive and normalized.

#### Scenario: Known artist's track discovered via network
- **WHEN** a followed node has a Listen activity for a track whose artist matches an artist in the local library, and the track is not in the local library
- **THEN** that track appears in the new-from-known path results

#### Scenario: Already-owned track excluded
- **WHEN** a track's artist matches a local artist but the track itself is already in the local library
- **THEN** it SHALL NOT appear in new-from-known results

---

### Requirement: ProvenanceRecord per result
Every recommendation result SHALL carry a `ProvenanceRecord` value object containing: the contributing path(s), the top contributing actor's ID and display name (if applicable), and a pre-rendered human-readable reason string.

#### Scenario: Reason string for trending result
- **WHEN** a track's primary path is network trending with three contributing nodes
- **THEN** the ProvenanceRecord reason string reads "3 people you follow have been playing this" (or equivalent template with the correct count)

#### Scenario: Reason string for affinity result
- **WHEN** a track's primary path is taste affinity with a single top contributing actor
- **THEN** the ProvenanceRecord reason string reads "<DisplayName> has had this on repeat" using the actor's display name, never their raw handle

#### Scenario: Reason string for new-from-known result
- **WHEN** a track's primary path is new-from-known
- **THEN** the ProvenanceRecord reason string reads "New from [Artist], in your library"

#### Scenario: Provenance degrades when actor not cached
- **WHEN** the contributing actor's display data is not in the local cache
- **THEN** the reason string degrades to a generic form (e.g., "Trending in your network") rather than blocking the recommendation

---

### Requirement: Deduplication against local library
The engine SHALL filter out from the final ranked list any track that already exists in the user's local library, using acoustic fingerprint matching to catch the same track under different metadata.

#### Scenario: Already-owned track excluded from results
- **WHEN** a candidate track's acoustic fingerprint matches a track in the local library
- **THEN** that candidate SHALL NOT appear in the final ranked result list

---

### Requirement: Scoring runs on a background isolate
All scoring computation SHALL run off the main UI thread using Dart's `Isolate.spawn` or `compute`, to prevent frame drops or jank during a scoring pass.

#### Scenario: UI remains responsive during scoring
- **WHEN** the recommendation engine is running a full scoring pass
- **THEN** the main thread remains unblocked and the Discover screen shows a loading state without dropping frames

---

### Requirement: Results cached for session
The most recent scored result list SHALL be cached in memory for the duration of the app session. Re-scoring SHALL be triggered only on: manual pull-to-refresh, app foreground event after a configurable minimum interval, or a significant new signal event (e.g., a new follow).

#### Scenario: Cached results served without re-scoring
- **WHEN** the user navigates away from and back to the Discover screen within the same session
- **THEN** the cached result list is displayed immediately without re-triggering a scoring pass
