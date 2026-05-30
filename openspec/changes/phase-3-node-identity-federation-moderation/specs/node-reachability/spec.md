## ADDED Requirements

### Requirement: Best-effort node address registration
The system SHALL attempt to register the node's current network address with the relay infrastructure on each app launch and whenever the network address changes. Reachability SHALL be treated as a transient, opportunistic state — not a guarantee. The app SHALL function correctly regardless of whether the node is currently reachable.

#### Scenario: Node registers with relay on launch
- **WHEN** the app launches and an identity exists
- **THEN** the app registers its current host and port with the relay, associating them with the actor URL
- **THEN** if registration fails (relay unreachable, no network), the app starts normally and schedules a retry — it does not block startup or show an error to the user

#### Scenario: Address change triggers re-registration
- **WHEN** the device's IP address or port changes (network transition, app restart)
- **THEN** the app re-registers the new address with the relay
- **THEN** the old address entry is superseded by the new one

#### Scenario: Reachability state is communicated honestly
- **WHEN** the node is not directly reachable from the internet (e.g., backgrounded, behind NAT, no network)
- **THEN** the reachability status is surfaced as "relay-only" or "offline" in any context where it is relevant (settings, debug overlay) — never as a broken or error state

---

### Requirement: Relay-assisted inbox delivery
The system SHALL support relay-assisted delivery as the fallback path when a destination node is not directly reachable. The relay queues activities and delivers them when the destination node re-registers.

#### Scenario: Direct delivery failure triggers relay handoff
- **WHEN** direct HTTPS delivery to a remote inbox fails after all retry attempts (non-2xx, timeout, unreachable)
- **THEN** the system hands the activity to the relay with the destination actor URL
- **THEN** the outgoing queue entry is updated to "relayed" status
- **THEN** no error is surfaced to the user — the relay handoff is a normal delivery path

#### Scenario: Relay delivers queued activity when destination comes online
- **WHEN** a destination node re-registers its address with the relay after being offline
- **THEN** the relay delivers any queued activities to the node's inbox
- **THEN** those activities are processed as if they had arrived via direct delivery

#### Scenario: Relay handoff is logged in the federation inspector
- **WHEN** an activity is handed to the relay
- **THEN** the event is recorded in the outgoing activity log with status "relayed" and the relay reference ID (dev overlay)

---

### Requirement: Connection state management with retry
The system SHALL manage the connection state for all outgoing federation delivery attempts. Transient failures SHALL be retried with exponential back-off before escalating to relay handoff. The retry state SHALL survive app restarts via the persistent outgoing activity queue.

#### Scenario: Transient delivery failure is retried with back-off
- **WHEN** a direct inbox delivery attempt receives a 5xx response or network timeout
- **THEN** the system schedules a retry after an initial 5-second delay
- **THEN** each subsequent failure doubles the delay (10s, 20s) up to a maximum of 3 total attempts
- **THEN** after 3 failed attempts, the activity is handed to the relay

#### Scenario: Activity queue persists across app restarts
- **WHEN** the app restarts while there are pending or retrying outgoing activities in the queue
- **THEN** those activities are loaded from Drift on startup
- **THEN** pending deliveries are retried from their last recorded state

#### Scenario: Successful delivery removes the queue entry
- **WHEN** a direct delivery or relay delivery confirmation is received
- **THEN** the corresponding queue entry is marked as delivered and removed from the pending set

---

### Requirement: Incoming activity queueing for offline nodes
Activities delivered to the local node's inbox SHALL be accepted and stored even when the app is backgrounded or temporarily unreachable — because the relay holds and delivers them when the node reconnects, the app does not need to be running at the moment of delivery.

#### Scenario: Queued activity is processed on next app foreground
- **WHEN** the app comes to the foreground after a period offline
- **THEN** any activities delivered to the inbox via the relay during the offline period are present in the local inbox database
- **THEN** the app processes them in received order

#### Scenario: Duplicate activity delivery is idempotent
- **WHEN** the relay delivers an activity that has already been stored in the local inbox (e.g., due to a relay retry)
- **THEN** the system detects the duplicate by activity `id` and discards it without creating a duplicate record
