## ADDED Requirements

### Requirement: Network-state primitives are first-class shared widgets
`lib/shared/components/network_state/` SHALL contain four concrete, fully styled widgets: `BufferingWidget`, `HostOfflineWidget`, `StreamFailedPlayingLocalWidget`, and `PartialLibraryWidget`. These SHALL NOT be placeholders, `TODO` stubs, or `Container()` wrappers. Each SHALL be visually distinct, use only design tokens, and communicate its state calmly and intentionally — unavailability SHALL feel deliberate, never broken.

#### Scenario: Buffering state displayed
- **WHEN** a remote stream is loading
- **THEN** `BufferingWidget` SHALL display a styled activity indicator and a short status label
- **THEN** no raw "Loading..." text SHALL appear without design-token styling

#### Scenario: Host offline state displayed
- **WHEN** a remote node is unreachable
- **THEN** `HostOfflineWidget` SHALL display the host's display name (not their raw handle), an offline indicator, and the last-seen timestamp if available
- **THEN** the state SHALL read as intentional, not as an error condition

#### Scenario: Stream failed, playing local copy
- **WHEN** a remote stream fails mid-session and a cached local copy is used
- **THEN** `StreamFailedPlayingLocalWidget` SHALL display as a non-intrusive banner or badge
- **THEN** the banner SHALL not block playback controls or other interactive elements

#### Scenario: Partial library state displayed
- **WHEN** a remote library is only partially fetched
- **THEN** `PartialLibraryWidget` SHALL indicate the partial state with a subtle visual cue
- **THEN** the user SHALL still be able to interact with the portion of the library that is available

### Requirement: Network-state widgets use design tokens exclusively
Each network-state widget SHALL source all colors, spacing, typography, and motion values from `AppTokens`/`Theme.of(context)`. No magic numbers or hardcoded `Color` values SHALL appear in network-state widget files. All widgets SHALL render correctly in both dark and light mode.

#### Scenario: Dark mode network state
- **WHEN** the device is in dark mode and a `HostOfflineWidget` is displayed
- **THEN** all colors SHALL resolve to their dark-mode semantic values via `Theme.of(context)`
- **THEN** no element SHALL appear with a light-mode hardcoded color

### Requirement: Network-state widget API is stable against future real-state wiring
Each widget's constructor SHALL accept generic, typed parameters (`displayName`, `lastSeenAt`, `statusLabel`) rather than hard-coded string literals. This ensures that when Phase 3 wires real network state into these widgets, the widget API does not need to change — only the call sites change.

#### Scenario: Phase 3 wires real state
- **WHEN** a Phase 3 provider supplies real host-offline state
- **THEN** the provider SHALL be able to pass `displayName` and `lastSeenAt` to `HostOfflineWidget` without modifying the widget's source code
- **THEN** no widget API migration SHALL be required

### Requirement: Network-state widgets are covered by widget tests
Each of the four network-state widgets SHALL have at least one widget test verifying it renders without exception and displays its key content. Tests SHALL live in `test/shared/components/network_state/`.

#### Scenario: BufferingWidget renders in test
- **WHEN** `BufferingWidget` is pumped in a widget test with a `statusLabel`
- **THEN** the test SHALL find the label text in the widget tree
- **THEN** no exception SHALL be thrown during rendering
