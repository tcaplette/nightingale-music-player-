## ADDED Requirements

### Requirement: Discover tab in main navigation
The app SHALL include a Discover tab as a primary navigation destination accessible from the main navigation rail or bottom navigation bar. The route SHALL be `/discover`.

#### Scenario: Discover tab accessible from all screens
- **WHEN** the user is on any primary screen (Library, Feed, Player)
- **THEN** the Discover tab is visible and tappable in the navigation bar

---

### Requirement: Recommendations organized by provenance sections
The Discover screen SHALL organize recommendations into named sections based on their provenance path, not into opaque algorithmic shelves. Section headers SHALL be human-readable and people-focused.

#### Scenario: Sections reflect signal paths
- **WHEN** results from multiple scoring paths are present
- **THEN** the screen shows distinct sections such as "What your people are into", "From artists you already love", and "Trending in your network" — not a single undifferentiated list

#### Scenario: Empty section not shown
- **WHEN** a scoring path produces zero results (e.g., affinity path inactive due to low signal density)
- **THEN** that section is omitted from the screen; the screen does not show an empty section header

---

### Requirement: RecommendationCard shows who and why
Each recommendation item SHALL be rendered as a card displaying: track artwork, track title, artist name, a ProvenanceChip (actor avatar + reason string), and two actions — stream (primary) and save (secondary). The raw `@user@node` handle of the attributed actor SHALL NOT appear in the card's primary presentation.

#### Scenario: Card shows attributed person's face and name
- **WHEN** a recommendation has a contributing actor with cached display data
- **THEN** the card shows a small circular avatar and the actor's display name next to the reason string

#### Scenario: Card degrades gracefully when actor not cached
- **WHEN** a recommendation's contributing actor display data is not locally cached
- **THEN** the card shows a generic reason string ("Trending in your network") without an avatar, rather than a broken or empty state

#### Scenario: Card shows count for multi-person provenance
- **WHEN** a recommendation has three or more contributing actors
- **THEN** the card shows "3 people you follow saved this" with the lead actor's avatar, not a list of all three names

---

### Requirement: One-tap stream from Discover
The primary action on each recommendation card SHALL initiate best-effort streaming of the track from the hosting node, using the Phase 4 audio streaming infrastructure. The stream action SHALL be a single tap with no confirmation dialog.

#### Scenario: Stream starts on tap
- **WHEN** the user taps the stream action on a recommendation card
- **THEN** playback begins (or queues if something is playing), and the mini player appears

#### Scenario: Stream state shown honestly when host offline
- **WHEN** the user taps stream and the hosting node is unreachable
- **THEN** the card shows the host-offline network state indicator from the `network-state-primitives` component library; it does not show a generic error

#### Scenario: Stream degrades to cached copy if available
- **WHEN** the user taps stream and the hosting node is offline but a cached copy exists locally
- **THEN** the cached copy plays and the card shows the stream-from-cache state indicator

---

### Requirement: One-tap save from Discover
The secondary action on each recommendation card SHALL save the track to the user's local library queue with a single tap. A save SHALL also emit a Save signal event to the signal store.

#### Scenario: Track saved on tap
- **WHEN** the user taps the save action on a recommendation card
- **THEN** the track is added to the user's save queue and the card updates to show a saved state indicator

#### Scenario: Save emits a signal event
- **WHEN** the user taps save on a recommendation card
- **THEN** a `save` signal event is written to the signal store for that track

---

### Requirement: Manual refresh via pull-to-refresh
The Discover screen SHALL support pull-to-refresh to trigger a new scoring pass and reload the recommendation list.

#### Scenario: Pull-to-refresh triggers rescore
- **WHEN** the user pulls down to refresh the Discover screen
- **THEN** a new scoring pass is initiated, a loading indicator is shown, and results update when the pass completes

---

### Requirement: Discover screen uses design system primitives
The Discover screen SHALL be implemented using the Phase 1 design system tokens (typography scale, spacing grid, color palette, motion constants) and SHALL honor all `network-state-primitives` for stream state communication. Typography hierarchy SHALL carry the layout; color use SHALL be restrained (near-monochromatic base, single accent for primary stream action only).

#### Scenario: No competing primary actions
- **WHEN** a recommendation card is rendered
- **THEN** there is exactly one visually primary action (stream); save is visually secondary; no other CTAs compete for attention on the card

#### Scenario: Motion communicates state changes only
- **WHEN** a card transitions to saved state after a save tap
- **THEN** a brief, purposeful animation confirms the state change; no decorative or looping animations are present on the card

---

### Requirement: Discover screen honest empty state
If the cold-start bootstrap and all scoring paths genuinely produce zero results (e.g., no network, no library, fresh install with no data at all), the Discover screen SHALL show a thoughtful, on-brand empty state — not a broken or blank screen.

#### Scenario: Empty state shown when no results available
- **WHEN** the recommendation engine and cold-start bootstrap both return empty result sets
- **THEN** the Discover screen shows an empty state with a brief, human explanation and a suggestion (e.g., add music to your library, or follow someone)
