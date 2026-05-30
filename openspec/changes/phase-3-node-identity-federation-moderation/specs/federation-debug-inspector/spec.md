## ADDED Requirements

### Requirement: Federation inspector tab in the debug overlay
The system SHALL add a "Federation" tab to the existing Phase 1 debug overlay (dev builds only). The tab SHALL be compile-time gated and SHALL never appear in release builds. It SHALL be activated only through the existing dev-build entry point — not via shake gesture or any gesture that conflicts with accessibility tools.

#### Scenario: Federation tab is present in dev builds only
- **WHEN** the app is running as a dev build and the debug overlay is opened
- **THEN** a "Federation" tab is visible alongside existing overlay tabs
- **WHEN** the app is running as a release build
- **THEN** no federation inspector code is compiled in or accessible

#### Scenario: Federation tab is inaccessible without the dev entry point
- **WHEN** the debug overlay's dev entry point has not been triggered
- **THEN** the federation tab is not reachable by any gesture, tap sequence, or URL
- **THEN** the federation tab does not render in the widget tree

---

### Requirement: Outgoing activity log
The federation inspector SHALL display a live, scrollable log of all outgoing ActivityPub activities with their full JSON payload and the HTTP response received from the remote node.

#### Scenario: Outgoing activity is logged with full detail
- **WHEN** the app delivers an activity to a remote inbox
- **THEN** the federation inspector adds an entry showing: timestamp, destination actor URL, activity type, full JSON payload (formatted), HTTP response code, response body (truncated at 2 KB), and delivery status (delivered / retrying / relayed / failed)

#### Scenario: Log entries persist during the session
- **WHEN** the user opens the federation inspector after activities have been sent
- **THEN** all outgoing activities from the current app session are visible in reverse-chronological order

---

### Requirement: Incoming activity log
The federation inspector SHALL display a live log of all incoming activities received at the local inbox, including signature verification status.

#### Scenario: Incoming activity is logged with signature status
- **WHEN** an activity arrives at the local inbox
- **THEN** the federation inspector adds an entry showing: timestamp, source actor URL, activity type, HTTP Signature verification result (verified / failed / missing), and whether the activity was accepted, dropped, or rate-limited

#### Scenario: Signature failures are prominently flagged
- **WHEN** an incoming activity's signature fails verification
- **THEN** the log entry is visually differentiated (e.g., error color) and includes the failure reason (bad signature, expired timestamp, replayed nonce)

---

### Requirement: HTTP Signature verification status per request
The federation inspector SHALL show the HTTP Signature verification outcome for every incoming request, including replay-rejection events, with enough detail to diagnose interoperability issues.

#### Scenario: Replay rejection is logged distinctly
- **WHEN** an incoming request is rejected because its nonce has been seen within the time window
- **THEN** the inspector adds a "replay rejected" entry with the nonce, timestamp, and source actor URL

#### Scenario: Verification detail includes signed headers
- **WHEN** a signature verification entry is expanded in the inspector
- **THEN** the display shows the `keyId`, signed headers list, signature algorithm, and the specific reason for success or failure

---

### Requirement: Actor resolution cache viewer
The federation inspector SHALL display the contents of the local actor resolution cache so developers can inspect which remote actors have been fetched, their cached Actor JSON, and when the cache entries expire.

#### Scenario: Cache viewer shows current entries
- **WHEN** the actor resolution cache viewer is opened
- **THEN** each cached entry shows: actor URL, `preferredUsername`, `publicKey.id`, cache time, and TTL remaining

#### Scenario: Cache entries can be manually invalidated
- **WHEN** a developer taps "Invalidate" on a cache entry
- **THEN** that entry is removed from the cache, forcing a fresh fetch on the next resolution

---

### Requirement: Node reachability status display
The federation inspector SHALL display the current reachability state of the local node and the status of the relay registration.

#### Scenario: Reachability status is shown accurately
- **WHEN** the federation inspector is open
- **THEN** the reachability panel shows: current listening address and port, relay registration status (registered / pending / failed), last successful registration timestamp, and whether the node believes it is directly reachable

---

### Requirement: Defederation and rate-limit state viewer
The federation inspector SHALL display the current defederation list and live rate-limit counters for all source nodes that have delivered to the inbox in the current session.

#### Scenario: Defederation list is shown
- **WHEN** the defederation/rate-limit panel is open
- **THEN** all defederated domains are listed with the timestamp they were added

#### Scenario: Rate limit counters are shown live
- **WHEN** a source node is actively delivering activities
- **THEN** the inspector shows the current sliding-window count and the reset time for that node

---

### Requirement: WebFinger resolution debugger
The federation inspector SHALL include a WebFinger resolution tool allowing the developer to enter a handle or resource URI and see the full WebFinger lookup result: the JRD response body, the resolved actor URL, and any errors encountered.

#### Scenario: Successful WebFinger resolution is displayed
- **WHEN** the developer enters a valid `acct:user@domain` resource in the WebFinger debugger and triggers the lookup
- **THEN** the debugger displays: the WebFinger endpoint URL called, the HTTP response code, the full JRD response body (formatted JSON), and the resolved actor URL extracted from the `rel: self` link

#### Scenario: Failed WebFinger resolution shows the error
- **WHEN** a WebFinger lookup fails (DNS failure, HTTP error, malformed JRD)
- **THEN** the debugger displays the failure reason, the response body if any, and the HTTP status code
