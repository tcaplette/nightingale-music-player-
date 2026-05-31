## ADDED Requirements

### Requirement: User can choose the app theme
The app SHALL provide a **Theme** setting with three options: **System** (default), **Light**, **Dark**. The selection SHALL be persisted and reactively applied to `MaterialApp.themeMode` without requiring a restart.

#### Scenario: Default theme is System
- **WHEN** the user opens Appearance settings for the first time
- **THEN** Theme shows System as selected

#### Scenario: Selecting Dark switches the app to dark mode immediately
- **WHEN** the user selects Dark
- **THEN** the app switches to its dark theme instantly, without a restart

#### Scenario: Selecting Light switches the app to light mode immediately
- **WHEN** the user selects Light
- **THEN** the app switches to its light theme instantly, even if the OS is in dark mode

#### Scenario: Selecting System restores OS-driven theming
- **WHEN** the user selects System
- **THEN** the app theme follows the OS dark/light setting from that point forward

#### Scenario: Theme persists across app restarts
- **WHEN** the user has selected Dark and restarts the app
- **THEN** the app opens in dark mode before the first frame is painted (no flash)

---

### Requirement: User can enable reduce motion
The app SHALL provide a **Reduce Motion** toggle. When enabled, all animation durations driven by `AppMotion` SHALL be replaced with a short fixed duration (80 ms). The setting SHALL be persisted and applied immediately on toggle.

#### Scenario: Reduce motion is off by default
- **WHEN** the user opens Appearance settings for the first time
- **THEN** the Reduce Motion toggle is off

#### Scenario: Enabling reduce motion shortens transitions immediately
- **WHEN** the user enables Reduce Motion
- **THEN** subsequent page transitions and UI animations use 80 ms durations

#### Scenario: Disabling reduce motion restores standard durations
- **WHEN** the user disables Reduce Motion
- **THEN** subsequent animations resume their standard durations from `AppMotion`

#### Scenario: Setting persists across restarts
- **WHEN** the user has enabled Reduce Motion and restarts the app
- **THEN** all animations use the reduced duration from the first frame
