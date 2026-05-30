## ADDED Requirements

### Requirement: PersonDisplay is the sole widget that renders a person's identity
`lib/shared/components/identity/person_display.dart` SHALL contain a `PersonDisplay` widget. No other widget in the codebase SHALL render a fediverse handle string (`@user@node` format) as visible text in the UI. All places that present a person's identity SHALL route through `PersonDisplay`.

#### Scenario: Person shown in a feed item
- **WHEN** a feed item displays who shared a track
- **THEN** the feature widget SHALL embed `PersonDisplay(displayName: ..., avatarUrl: ...)`
- **THEN** no string containing `@` followed by a domain SHALL appear as rendered text

### Requirement: PersonDisplay renders name and avatar; handle is hidden by default
`PersonDisplay` SHALL display the `displayName` (required) and optionally an avatar image from `avatarUrl`. The `handle` parameter (the raw `@user@node` string) SHALL be accepted but SHALL NOT be rendered unless `showHandle: true` is explicitly passed. `showHandle` SHALL default to `false`. When `showHandle: true`, the handle SHALL be rendered in a subdued style (small text, low-contrast color from `AppColors`) below the display name.

#### Scenario: Default rendering hides the handle
- **WHEN** `PersonDisplay(displayName: 'Maya', handle: '@maya@music.example')` is rendered
- **THEN** the widget tree SHALL display "Maya"
- **THEN** no text matching `@maya@music.example` SHALL appear in the widget tree

#### Scenario: Advanced context shows handle
- **WHEN** `PersonDisplay(displayName: 'Maya', handle: '@maya@music.example', showHandle: true)` is rendered
- **THEN** the widget SHALL display "Maya" as primary text
- **THEN** "@maya@music.example" SHALL appear as secondary text in subdued styling

### Requirement: PersonDisplay handles missing avatar gracefully
When `avatarUrl` is null or the image fails to load, `PersonDisplay` SHALL render a fallback: an initials monogram derived from `displayName`, displayed in a styled circle using `AppColors` and `AppSpacing`. No broken image icon or blank space SHALL appear in place of a missing avatar.

#### Scenario: Avatar URL is null
- **WHEN** `PersonDisplay(displayName: 'Jordan')` is rendered with no `avatarUrl`
- **THEN** a styled circle SHALL appear with the initials "J" (or "JO" for two-initial style)
- **THEN** no network request SHALL be made

#### Scenario: Avatar image fails to load
- **WHEN** `avatarUrl` is provided but the image request returns an error
- **THEN** the widget SHALL fall back to the initials monogram
- **THEN** no error widget (red broken-image icon) SHALL appear in the widget tree

### Requirement: showHandle usage is auditable
All usages of `showHandle: true` in the codebase SHALL be restricted to settings, advanced profile, or diagnostic contexts. A code reviewer SHALL be able to find all handle-surface points by grepping for `showHandle: true`. This is a convention enforced by code review, not a runtime check.

#### Scenario: Audit of handle surface points
- **WHEN** a developer runs `grep -r 'showHandle: true' lib/`
- **THEN** every result SHALL be in a settings, advanced, or debug context
- **THEN** no result SHALL be in a feed, player, or discovery UI context

### Requirement: PersonDisplay is covered by widget tests
`test/shared/components/identity/person_display_test.dart` SHALL test: default rendering (name visible, handle hidden), `showHandle: true` rendering, null avatar fallback, and image-load-failure fallback.

#### Scenario: Widget test for default rendering
- **WHEN** `PersonDisplay(displayName: 'Maya', handle: '@maya@example.com')` is pumped
- **THEN** `find.text('Maya')` SHALL find one widget
- **THEN** `find.text('@maya@example.com')` SHALL find zero widgets
