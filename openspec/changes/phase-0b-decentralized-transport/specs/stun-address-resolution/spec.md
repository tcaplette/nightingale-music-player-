## ADDED Requirements

### Requirement: STUN public address discovery
The system SHALL perform a STUN binding request on each network change and at onboarding to discover the device's current public IP:port, storing the result in the identity table so it can be advertised to remote peers.

#### Scenario: STUN resolves public address on onboarding
- **WHEN** the user completes the onboarding identity setup step and network is available
- **THEN** the system performs a STUN binding request and stores the returned public IP:port as `nodePublicAddress` in the identity table

#### Scenario: STUN re-runs on network change
- **WHEN** the device transitions between network types (WiFi ↔ cellular) or connects to a new network
- **THEN** the system performs a fresh STUN binding request and updates `nodePublicAddress` in the identity table

#### Scenario: STUN address advertised in actor object
- **WHEN** a remote peer fetches this node's actor object
- **THEN** the actor JSON includes an `x-nightingale-public-address` extension field containing the most recently resolved public IP:port

#### Scenario: STUN failure does not block onboarding or operation
- **WHEN** the STUN request fails (no network, STUN server unreachable, timeout)
- **THEN** the system proceeds without a public address; the actor object omits `x-nightingale-public-address`; local-only federation via mDNS continues to work

#### Scenario: STUN server is configurable
- **WHEN** the app is built with a `STUN_SERVER` environment variable set
- **THEN** that STUN server is used instead of the default (`stun.l.google.com:19302`)

---

### Requirement: Last known address persistence
The system SHALL persist the last successfully resolved public address across app restarts so that the actor URL remains advertisable immediately on launch before a fresh STUN lookup completes.

#### Scenario: Stored address used before STUN completes
- **WHEN** the app launches and a STUN lookup is in progress
- **THEN** the previously stored `nodePublicAddress` is used in the actor object until the new lookup completes

#### Scenario: Stored address replaced when STUN returns a different result
- **WHEN** a fresh STUN lookup returns a different public IP:port than the stored value
- **THEN** the identity table is updated and subsequent actor object fetches reflect the new address
