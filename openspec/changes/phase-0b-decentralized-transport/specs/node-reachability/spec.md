## MODIFIED Requirements

### Requirement: Check if a remote node is reachable
The system SHALL determine whether a remote node is currently reachable by consulting the mDNS peer cache first, then the STUN-discovered address from the remote actor object, then the stored actor URL. The reachability cache SHALL be invalidated on network change.

#### Scenario: mDNS address used for local peers
- **WHEN** the reachability service is asked about a node that mDNS has resolved on the current network
- **THEN** the mDNS-resolved IP:port is used for the reachability check, not the stored actor URL

#### Scenario: STUN-discovered address used for remote peers
- **WHEN** the reachability service is asked about a node not on the local network and the remote actor object contains `x-nightingale-public-address`
- **THEN** that address is attempted before falling back to the base actor URL host

#### Scenario: Falls back to stored actor URL
- **WHEN** neither mDNS nor a STUN-discovered address is available for a node
- **THEN** the reachability check uses the host extracted from the stored actor URL

#### Scenario: Cache invalidated on network change
- **WHEN** the device's network changes (WiFi ↔ cellular ↔ none)
- **THEN** the reachability cache is cleared so stale results do not persist across network transitions

#### Scenario: Unreachable result cached briefly
- **WHEN** a reachability check returns false
- **THEN** the negative result is cached for 2 minutes to avoid hammering offline nodes; a positive result is cached for 2 minutes as before
