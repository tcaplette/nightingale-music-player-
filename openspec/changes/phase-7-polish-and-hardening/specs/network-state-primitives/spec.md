## MODIFIED Requirements

### Requirement: Network-state primitives are first-class shared widgets
`lib/shared/components/network_state/` SHALL contain four concrete, fully styled widgets: `BufferingWidget`, `HostOfflineWidget`, `StreamFailedPlayingLocalWidget`, and `PartialLibraryWidget`. These SHALL NOT be placeholders, `TODO` stubs, or `Container()` wrappers. Each SHALL be visually distinct, use only design tokens, and communicate its state calmly and intentionally — unavailability SHALL feel deliberate, never broken. In Phase 7, each widget SHALL additionally: (a) animate its entrance and exit using `AppDurations` and `AppCurves` constants, (b) use copy that passes the "calm intent" tone audit (no "Error", "Failed", or "Problem" wording), and (c) never overlap or block playback controls when rendered in the Now Playing context.

#### Scenario: Buffering state displayed
- **WHEN** a remote stream is loading
- **THEN** `BufferingWidget` SHALL display a styled activity indicator and a short status label using second-person present-tense copy ("Connecting…")
- **THEN** no raw "Loading..." text SHALL appear without design-token styling
- **THEN** the widget SHALL animate its entrance over `AppDurations.stateTransition` ms

#### Scenario: Host offline state displayed
- **WHEN** a remote node is unreachable
- **THEN** `HostOfflineWidget` SHALL display the host's display name (not their raw handle), a passive offline indicator, and the last-seen timestamp if available
- **THEN** the state SHALL read as intentional, not as an error condition
- **THEN** the widget SHALL NOT use `AppColors.error` unless the offline state is terminal and unrecoverable

#### Scenario: Stream failed, playing local copy
- **WHEN** a remote stream fails mid-session and a cached local copy is used
- **THEN** `StreamFailedPlayingLocalWidget` SHALL display as a non-intrusive banner or badge
- **THEN** the banner SHALL not block playback controls or other interactive elements
- **THEN** the widget SHALL animate its entrance with a slide-in from above over `AppDurations.stateTransition` ms

#### Scenario: Partial library state displayed
- **WHEN** a remote library is only partially fetched
- **THEN** `PartialLibraryWidget` SHALL indicate the partial state with a subtle visual cue
- **THEN** the user SHALL still be able to interact with the portion of the library that is available
- **THEN** the visual cue SHALL NOT use alarm colors or warning iconography

## ADDED Requirements

### Requirement: Network-state components pass a tone and motion audit
Before Phase 7 ships, each network-state widget SHALL be reviewed against the following checklist: (1) copy contains no "Error", "Failed", "Problem", or "Broken"; (2) icon is a passive/neutral indicator; (3) entrance animation uses `AppDurations` and `AppCurves`; (4) no `AppColors.error` unless state is terminal; (5) widget does not obscure playback controls. The audit SHALL be documented in a code comment above each widget class.

#### Scenario: Audit checklist in code comment
- **WHEN** a developer opens `HostOfflineWidget` in the editor
- **THEN** a single-line comment above the class SHALL reference the Phase 7 tone and motion audit result
- **THEN** the comment SHALL confirm or note any exceptions to the checklist items
