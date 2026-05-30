## ADDED Requirements

### Requirement: Relay fallback for streaming
When direct streaming to a hosting node fails (connection timeout, host unreachable), the app SHALL attempt to fetch the audio via the relay if a relay path is configured and viable.

#### Scenario: Direct connection fails, relay succeeds
- **WHEN** direct streaming to the hosting node times out
- **AND** a relay is configured
- **THEN** the app requests the audio via the relay
- **AND** playback begins from the relayed stream

#### Scenario: Both direct and relay fail
- **WHEN** direct streaming fails
- **AND** relay streaming also fails
- **THEN** the app falls back to cached copy or skips the track

### Requirement: Relay stream request format
Relay-assisted stream requests SHALL include the target node's actor URL and track ID so the relay can forward the request.

#### Scenario: Relay request structure
- **WHEN** the app requests a stream via relay
- **THEN** the request includes `target_actor` and `track_id` parameters
- **AND** the relay forwards the request to the target node

### Requirement: Relay authentication
Relay-assisted streams SHALL preserve HTTP Signature authentication end-to-end. The relay SHALL forward the original request headers including the signature.

#### Scenario: Authenticated relay stream
- **WHEN** a stream request is relayed
- **THEN** the hosting node receives the original HTTP Signature
- **AND** verifies it as if the request came directly
