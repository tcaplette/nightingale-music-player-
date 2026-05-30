## ADDED Requirements

### Requirement: All visual constants expressed as named design tokens
The app SHALL define all colors, typography sizes, spacing values, border radii, and animation constants as named Dart constants in `lib/shared/theme/`. No magic numbers (e.g., `16.0`, `Color(0xFF...)`) SHALL appear in widget files. All token files SHALL be pure Dart with no Flutter dependency except for `Color`, `TextStyle`, `Duration`, and `Curve`.

#### Scenario: A widget needs padding
- **WHEN** a widget applies padding
- **THEN** it SHALL reference `AppSpacing.md` (or another named constant)
- **THEN** no numeric literal SHALL appear as the padding value in the widget file

#### Scenario: Token is updated globally
- **WHEN** a designer changes the base spacing unit
- **THEN** updating the constant in `AppSpacing` SHALL propagate to all widgets without per-file edits

### Requirement: Color palette is near-monochromatic with a single accent
`AppColors` SHALL define a near-monochromatic base palette (neutral greys/warm neutrals) with exactly one accent color. Semantic aliases (`onSurface`, `surfaceVariant`, `error`, `success`) SHALL be defined separately and SHALL resolve to palette values. Widgets SHALL reference semantic aliases, not raw palette values. The accent SHALL be used only for primary interactive elements and SHALL not appear decoratively.

#### Scenario: Dark mode color resolution
- **WHEN** the device is in dark mode
- **THEN** semantic aliases (`onSurface`, `background`, etc.) SHALL resolve to dark-appropriate values
- **THEN** no widget SHALL hardcode a color that looks correct only in light mode

### Requirement: Typography scale defined as a TextTheme
`AppTypography` SHALL define a `TextTheme` with 5–6 named sizes and at most 2 font weights. All text in the app SHALL use a named `TextStyle` from the theme (e.g., `Theme.of(context).textTheme.bodyMedium`). No widget SHALL define an inline `TextStyle` with an explicit `fontSize` or `fontWeight`. The type scale SHALL establish clear hierarchy: display, title, body, label, caption.

#### Scenario: Text renders at the correct size
- **WHEN** a widget renders a track title
- **THEN** it SHALL use `textTheme.titleMedium` (or equivalent named style)
- **THEN** the font size SHALL be determined by the theme, not by a literal in the widget

### Requirement: Spacing grid expressed as named constants
`AppSpacing` SHALL define a spacing grid as named constants: `xs` (4), `sm` (8), `md` (16), `lg` (24), `xl` (32), `xxl` (48) (values in logical pixels, adjustable). All padding, margin, and gap values SHALL use these constants. Values between grid steps SHALL be explicitly named (e.g., `insetSm`) rather than computed as expressions.

#### Scenario: Consistent card padding
- **WHEN** two different cards are built by two different developers
- **THEN** both SHALL use `AppSpacing.md` for internal padding (assuming same visual spec)
- **THEN** the output SHALL be visually identical without per-widget coordination

### Requirement: Motion constants define all animation behavior
`AppMotion` SHALL define `Duration` constants (`durationMicro`, `durationStandard`, `durationEmphasis`) and `Curve` constants for at least three categories: micro-interactions, standard state transitions, and emphasis animations. No `AnimatedWidget` or `AnimationController` SHALL use a numeric millisecond literal or `Curves.linear` without an explicit justification comment.

#### Scenario: A button responds to a tap
- **WHEN** a user taps a primary button
- **THEN** the button's press animation SHALL use `AppMotion.durationMicro` and `AppMotion.curveStandard`
- **THEN** the animation SHALL feel consistent with all other micro-interactions in the app

### Requirement: Base component library covers core interaction patterns
`lib/shared/components/` SHALL contain implementations of: primary and secondary buttons, text input, card container, bottom sheet wrapper, and modal dialog wrapper. Each component SHALL:
- Accept only typed parameters (no raw `Map` or `dynamic`)
- Use design tokens exclusively for visual properties
- Support dark and light mode via `Theme.of(context)`
- Have no business logic; they are pure presentation components

#### Scenario: Button rendered in dark mode
- **WHEN** the device switches to dark mode while the app is open
- **THEN** all `AppButton` instances SHALL update their colors via theme resolution
- **THEN** no `AppButton` SHALL require a rebuild with explicit color overrides

### Requirement: Dark and light mode supported from initial build
The app SHALL ship with a complete `ThemeData` for both light and dark modes. `MaterialApp` SHALL be configured with both `theme` and `darkTheme`, deferring to `MediaQuery.platformBrightness` by default. No screen or widget SHALL require a separate dark-mode code path — theme resolution handles it entirely.

#### Scenario: System dark mode toggle
- **WHEN** the user toggles dark mode in system settings
- **THEN** the entire app SHALL update to the appropriate theme without a restart
- **THEN** no hardcoded color SHALL remain unchanged (i.e., look wrong in the new mode)
