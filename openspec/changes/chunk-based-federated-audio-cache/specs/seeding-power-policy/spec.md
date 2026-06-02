## ADDED Requirements

### Requirement: Seeding is gated on charging state and network type
The system SHALL prevent outbound chunk-serving (seeding) when the device is not charging OR when the active network connection is cellular. Seeding SHALL only be permitted when both conditions are met: device is charging AND connected to an unmetered Wi-Fi network.

#### Scenario: Seeding allowed on Wi-Fi while charging
- **WHEN** `SeedingPowerPolicy.canSeed()` is called and the device is charging and connected to Wi-Fi
- **THEN** `canSeed()` returns true

#### Scenario: Seeding blocked on cellular
- **WHEN** `canSeed()` is called and the device is on a cellular (metered) connection, regardless of charging state
- **THEN** `canSeed()` returns false

#### Scenario: Seeding blocked while on battery
- **WHEN** `canSeed()` is called and the device is not charging, even if connected to Wi-Fi
- **THEN** `canSeed()` returns false

### Requirement: A user-configurable battery threshold gates seeding
The system SHALL support a minimum battery level threshold (default 50%). Even when charging is detected, seeding SHALL be blocked if the current battery level is below this threshold. The threshold SHALL be persisted in user settings and applied at runtime without restarting the app.

#### Scenario: Battery below threshold blocks seeding
- **WHEN** the device is charging and on Wi-Fi but battery level is 30% and the threshold is 50%
- **THEN** `canSeed()` returns false

#### Scenario: Battery above threshold allows seeding
- **WHEN** the device is charging, on Wi-Fi, and battery level is 80% with the threshold at 50%
- **THEN** `canSeed()` returns true

#### Scenario: Threshold updated at runtime
- **WHEN** the user changes the threshold from 50% to 20% in Settings
- **THEN** subsequent calls to `canSeed()` use the new threshold without requiring an app restart

### Requirement: Seeding can be disabled entirely by the user
The system SHALL provide an on/off toggle in the Settings screen that completely disables chunk-serving to peers, regardless of charging state, network type, or battery level. The toggle state SHALL be persisted in user settings.

#### Scenario: Seeding disabled via toggle
- **WHEN** the user sets the seeding toggle to off
- **THEN** `canSeed()` returns false for all subsequent requests until the toggle is re-enabled

#### Scenario: Seeding re-enabled via toggle
- **WHEN** the user sets the seeding toggle back to on
- **THEN** `canSeed()` respects charging and network conditions as normal

### Requirement: The Settings screen surfaces seeding controls
The system SHALL display a seeding section in the Settings screen with: the on/off toggle, the battery threshold slider, and a status indicator showing whether seeding is currently active or paused (and why).

#### Scenario: Status indicator shows "Paused – charging required"
- **WHEN** the Settings screen is open, seeding is enabled, but the device is on battery
- **THEN** the status indicator displays a message indicating seeding is paused due to battery state

#### Scenario: Status indicator shows "Active"
- **WHEN** the device is charging, on Wi-Fi, above the threshold, and seeding is enabled
- **THEN** the status indicator displays an active/green state

#### Scenario: Status indicator shows "Disabled"
- **WHEN** the seeding toggle is off
- **THEN** the status indicator displays a disabled state regardless of charging or network conditions

### Requirement: The chunk endpoint returns 503 when seeding is disallowed
The system SHALL return HTTP 503 with a `Retry-After: 60` header from the `/chunks/{hash}` endpoint when `SeedingPowerPolicy.canSeed()` returns false, so requesting peers can retry without treating the node as permanently unavailable.

#### Scenario: 503 returned when policy blocks seeding
- **WHEN** a valid authenticated chunk request is received and `canSeed()` is false
- **THEN** the server responds with HTTP 503 and `Retry-After: 60`

#### Scenario: Request is served normally after policy re-enables seeding
- **WHEN** a subsequent request arrives after the device is plugged in and `canSeed()` returns true
- **THEN** the server responds with HTTP 200 and the chunk bytes
