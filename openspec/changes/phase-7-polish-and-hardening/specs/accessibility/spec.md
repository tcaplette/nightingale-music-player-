## ADDED Requirements

### Requirement: All interactive elements have semantic labels for screen readers
Every button, icon button, gesture detector, and interactive list item in the app SHALL have a `Semantics` widget with a meaningful `label`. Labels SHALL describe the action, not the visual appearance. Custom interactive widgets SHALL use `Semantics(button: true, label: '...')` or equivalent.

#### Scenario: Play button has semantic label
- **WHEN** VoiceOver or TalkBack reads the Now Playing screen
- **THEN** the play/pause button SHALL announce "Play" or "Pause" depending on current state
- **THEN** the semantic label SHALL update reactively when state changes

#### Scenario: Track list item has semantic label
- **WHEN** VoiceOver or TalkBack focuses a track row in the library
- **THEN** the announcement SHALL include track title, artist name, and duration
- **THEN** no raw `@user@node` handle or internal ID SHALL be part of the announcement

#### Scenario: Icon button without visible text has label
- **WHEN** VoiceOver or TalkBack focuses a standalone icon button (e.g., shuffle toggle)
- **THEN** the button SHALL announce its function (e.g., "Shuffle: on" or "Shuffle: off")
- **THEN** the label SHALL NOT be "Image" or "Button" without further description

### Requirement: All touch targets meet the 44×44pt minimum
Every tappable element SHALL have a minimum hit area of 44×44 logical pixels. Elements that are visually smaller (e.g., icon buttons in a toolbar) SHALL use `SizedBox`, `Padding`, or `InkResponse` to expand the hit area without changing the visual footprint.

#### Scenario: Small icon button hit area
- **WHEN** a 24×24 icon button is measured in a widget test
- **THEN** its tappable area SHALL be at least 44×44 logical pixels
- **THEN** tapping 10 px outside the visible icon SHALL still register as a tap

#### Scenario: Mini player controls are reachable
- **WHEN** the mini player is visible at the bottom of the screen
- **THEN** each control (play/pause, skip) SHALL have a minimum 44×44 tap target
- **THEN** all controls SHALL be reachable with one hand without re-gripping the device

### Requirement: All text and icon combinations meet WCAG AA contrast
Every text/background pair and icon/background pair in the app SHALL meet WCAG AA minimum contrast ratios: 4.5:1 for normal text (< 18pt), 3:1 for large text (≥ 18pt bold or ≥ 24pt) and meaningful icons. This requirement applies to both light and dark mode.

#### Scenario: Primary body text contrast in light mode
- **WHEN** the app is in light mode
- **THEN** the primary body text color against its background SHALL have a contrast ratio of at least 4.5:1
- **THEN** no text SHALL fall below this ratio due to opacity modifications

#### Scenario: Network-state component text contrast
- **WHEN** a network-state component (e.g., `HostOfflineWidget`) is visible
- **THEN** its status label text SHALL meet WCAG AA contrast in both light and dark modes
- **THEN** muted/secondary text in degraded-state components SHALL still meet a minimum 4.5:1 ratio

### Requirement: Dynamic type scales all text without layout overflow
All text in the app SHALL use `Theme.of(context).textTheme` styles and SHALL respond to the OS-level text size setting. No text SHALL be clipped, truncated beyond readability, or overflow its container at any OS text scale factor from 0.85× to 2.0×. Overflow-prone areas SHALL use `TextOverflow.ellipsis` with a meaningful maximum line count.

#### Scenario: Text scale factor 2.0 does not clip track title
- **WHEN** the OS text scale is set to 2.0×
- **THEN** the track title in the Now Playing screen SHALL be visible and readable (ellipsized if needed, not clipped)
- **THEN** no text element SHALL overflow its bounding box and appear behind other widgets

#### Scenario: List cells reflow at large text sizes
- **WHEN** the OS text scale is set to 1.5× or above
- **THEN** library list cells SHALL expand vertically to accommodate larger text
- **THEN** artwork thumbnails and trailing icons SHALL remain aligned and not overlap text
