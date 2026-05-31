## ADDED Requirements

### Requirement: Stable federation server port
The federation server SHALL bind to a stable, configured port rather than a system-assigned random port, so that the actor URL remains valid across app launches.

#### Scenario: Server starts on configured port
- **WHEN** the federation server starts
- **THEN** it binds to the port specified by `FEDERATION_PORT` (default `7777`)

#### Scenario: Port conflict falls back gracefully
- **WHEN** the configured port is already in use
- **THEN** the server tries the next two ports in sequence (`7778`, `7779`) and binds to the first available; the chosen port is stored in the identity table

#### Scenario: Random port is never used
- **WHEN** the federation server starts under any circumstances
- **THEN** port `0` (system-assigned) is NOT used

---

### Requirement: Actor URL reflects actual reachable address
The actor URL stored in the identity table and served in the actor object SHALL reflect the device's actual reachable address, not a placeholder or localhost address.

#### Scenario: Actor URL set correctly at onboarding
- **WHEN** the user completes identity setup during onboarding
- **THEN** the actor URL is constructed from the resolved local IP (for LAN) or the STUN-discovered public address, plus the stable port

#### Scenario: Actor URL updated on network change
- **WHEN** the device's network address changes (new WiFi, cellular handoff)
- **THEN** the actor URL in the identity table is updated to reflect the new address; the actor object served to peers reflects the update on next fetch

#### Scenario: Actor URL is never localhost
- **WHEN** any actor URL is generated or stored
- **THEN** it SHALL NOT contain `localhost`, `127.0.0.1`, or `::1` as the host

---

### Requirement: HTTPS enforcement removed
The federation server SHALL accept plain HTTP connections. Trust is established via HTTP Signature verification on each request, not via transport encryption.

#### Scenario: HTTP request is processed, not redirected
- **WHEN** a peer sends an HTTP (non-TLS) ActivityPub request to the local inbox
- **THEN** the request is processed normally; it is NOT redirected to HTTPS

#### Scenario: Unsigned requests are still rejected
- **WHEN** an HTTP request arrives without a valid HTTP Signature
- **THEN** the request is rejected with HTTP 401; removing HTTPS enforcement does not weaken signature verification
