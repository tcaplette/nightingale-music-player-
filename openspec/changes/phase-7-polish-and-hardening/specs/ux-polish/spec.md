## ADDED Requirements

### Requirement: All screen transitions use design-system animation constants
Every route entrance and exit SHALL use durations and easing curves defined in `AppDurations` and `AppCurves` (from the Phase 1 design system). No transition MAY use a hardcoded millisecond value or `Curves` constant inline. The standard page transition SHALL be a 250 ms fade-through (`Curves.easeInOut`). Modal bottom sheets SHALL enter with a 300 ms ease-out slide.

#### Scenario: Page navigation uses standard transition
- **WHEN** the user navigates from the library screen to an album detail screen
- **THEN** the transition SHALL last exactly `AppDurations.pageTransition` (250 ms)
- **THEN** the easing SHALL match `AppCurves.pageTransition`
- **THEN** no intermediate frame SHALL show a white flash or unstyled state

#### Scenario: Bottom sheet entrance
- **WHEN** a modal bottom sheet is presented
- **THEN** it SHALL slide up over `AppDurations.sheetEnter` (300 ms) with `AppCurves.easeOut`

### Requirement: Loading states use animated skeletons, not spinners
List and feed views SHALL display skeleton-loading placeholders that match the layout of the content they replace. A spinner SHALL only appear for single, blocking operations (e.g., initial library scan). Skeleton placeholders SHALL animate with a shimmer effect using design-token colors.

#### Scenario: Feed loads with skeleton
- **WHEN** the social feed is loading
- **THEN** a list of skeleton rows SHALL appear immediately, each matching the height and layout of a real feed item
- **THEN** a spinner SHALL NOT appear in the feed area

#### Scenario: Single blocking operation shows spinner
- **WHEN** the app is performing an initial library scan on first launch
- **THEN** a full-screen progress indicator with a status label SHALL appear
- **THEN** the skeleton layout SHALL NOT be shown for this case (no content shape to mirror)

### Requirement: Empty states are present for every list and feed view
Every list, grid, and feed view in the app SHALL have a defined empty state rendered when the data source is empty (not loading). Empty states SHALL use the shared `EmptyStateWidget` with an icon, a headline, and an optional subhead. They SHALL NOT show raw "No data" text or a blank white screen.

#### Scenario: Empty library state
- **WHEN** the user opens the library and no tracks have been scanned
- **THEN** `EmptyStateWidget` SHALL render with an icon, headline ("No music yet"), and a subhead ("Add music to get started")
- **THEN** the state SHALL match the app's typographic and color design system

#### Scenario: Empty social feed state
- **WHEN** the user opens the social feed and follows no one
- **THEN** `EmptyStateWidget` SHALL render with a prompt to follow people
- **THEN** the prompt SHALL reference people, not handles

#### Scenario: Empty search results state
- **WHEN** the user searches for a term with no matching tracks or artists
- **THEN** `EmptyStateWidget` SHALL render with a "No results for…" headline including the search term
- **THEN** no list rows or placeholder rows SHALL appear

### Requirement: Haptic feedback fires at exactly three defined moments
The app SHALL fire haptic feedback at track start (`HapticFeedback.lightImpact`), save or like action (`HapticFeedback.mediumImpact`), and stream error or node-unreachable failure (`HapticFeedback.heavyImpact`). Haptics SHALL NOT fire on scroll, drag, swipe-to-dismiss, or ambient UI events.

#### Scenario: Track starts playing
- **WHEN** a track begins playback (local or remote)
- **THEN** `HapticFeedback.lightImpact()` SHALL be called exactly once
- **THEN** no haptic SHALL fire on pause, skip, or seek

#### Scenario: User saves a track
- **WHEN** the user taps the save action on a remote track
- **THEN** `HapticFeedback.mediumImpact()` SHALL be called exactly once

#### Scenario: Stream fails
- **WHEN** a remote stream fails and the app cannot fall back to any source
- **THEN** `HapticFeedback.heavyImpact()` SHALL be called exactly once
- **THEN** the haptic SHALL fire simultaneously with the error state rendering, not before

### Requirement: Network-state surfaces are audited and polished for calm intent
All four network-state components (`BufferingWidget`, `HostOfflineWidget`, `StreamFailedPlayingLocalWidget`, `PartialLibraryWidget`) SHALL pass a UX audit verifying: icon is non-alarming, copy is in second person present tense ("Connecting…", "Maya's offline"), no error-red color unless the state is terminal and unrecoverable, and the component does not block or visually compete with playback controls.

#### Scenario: Host offline state reads as calm
- **WHEN** `HostOfflineWidget` is displayed
- **THEN** the text SHALL NOT use the word "Error", "Failed", or "Problem"
- **THEN** the icon SHALL be a passive indicator (e.g., offline cloud), not a red X or warning triangle
- **THEN** the component color SHALL use the design system's neutral or muted semantic token, not `AppColors.error`

#### Scenario: Buffering state does not block controls
- **WHEN** `BufferingWidget` is visible in the Now Playing screen
- **THEN** the playback controls (play/pause, skip) SHALL remain interactive and unobscured
- **THEN** the buffering indicator SHALL appear as a secondary layer, not as an overlay blocking the primary controls
