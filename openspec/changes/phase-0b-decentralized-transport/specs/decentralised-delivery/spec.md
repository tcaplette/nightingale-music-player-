## ADDED Requirements

### Requirement: Queue-and-retry delivery without relay dependency
The activity delivery system SHALL queue undelivered activities and retry against the target's most recently resolved address on subsequent app foreground events. No central relay SHALL be used or required.

#### Scenario: Activity delivered directly on first attempt
- **WHEN** a signed activity is dispatched and the target inbox is reachable
- **THEN** the activity is delivered directly and marked `delivered` in the outbox table

#### Scenario: Failed delivery is queued and retried
- **WHEN** direct delivery fails after the configured retry attempts
- **THEN** the activity remains in the outbox table with status `pending`; on the next app foreground the delivery is retried against the target's most recently resolved address

#### Scenario: No relay handoff occurs
- **WHEN** all direct delivery attempts are exhausted
- **THEN** the activity is NOT handed to any central relay; it remains `pending` for future retry

#### Scenario: Pending activities swept on app foreground
- **WHEN** the app returns to the foreground
- **THEN** all `pending` activities in the outbox are retried in order of creation

---

### Requirement: Centralised relay stub removed
The `RelayClient` class and `RELAY_BASE_URL` configuration SHALL be removed from the codebase. No code path SHALL hand off activities to a configurable central relay URL.

#### Scenario: No relay reference in outbox flow
- **WHEN** activity delivery exhausts all retry attempts
- **THEN** no HTTP request is made to any relay URL; the activity status is set to `pending` not `relayed`

#### Scenario: `relayed` status is no longer a valid outbox state
- **WHEN** the outbox table is inspected
- **THEN** no row has status `relayed`; valid statuses are `pending`, `retrying`, and `delivered`

---

### Requirement: Volunteer circuit relay interface (reserved)
The system SHALL define a `CircuitRelayClient` interface as the integration point for a future volunteer relay network. The interface SHALL be present but unimplemented; no functionality depends on it in this change.

#### Scenario: Interface exists but has no active implementation
- **WHEN** the app builds and runs
- **THEN** `CircuitRelayClient` is defined as an abstract class; no concrete implementation is registered in the service locator; all delivery paths operate as if no relay is available
