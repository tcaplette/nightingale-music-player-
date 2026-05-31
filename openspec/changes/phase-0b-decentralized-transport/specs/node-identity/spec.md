## MODIFIED Requirements

### Requirement: Node identity includes a reachable base URL
The node identity record SHALL store a `baseUrl` that is derived from the device's actual reachable address (local IP for LAN, STUN-discovered public address for cross-network) set at onboarding and updated on network change. The actor ID SHALL be constructed from this `baseUrl`.

#### Scenario: Base URL set to local IP at onboarding
- **WHEN** the user completes the identity setup step during onboarding and the device is on a WiFi network
- **THEN** `baseUrl` is set to `http://<local-LAN-IP>:<port>` and the actor ID is `<baseUrl>/users/<username>`

#### Scenario: Base URL includes STUN address when available
- **WHEN** STUN resolution succeeds during or after onboarding
- **THEN** `nodePublicAddress` in the identity table is set to the STUN result; remote peers that fetch the actor object receive this address in `x-nightingale-public-address`

#### Scenario: Base URL never contains localhost
- **WHEN** a `baseUrl` is generated under any circumstance
- **THEN** it SHALL NOT use `localhost`, `127.0.0.1`, or `::1` as the host

#### Scenario: Base URL updated on network change
- **WHEN** the device connects to a new network
- **THEN** the local IP portion of `baseUrl` is updated to reflect the new interface address; STUN is re-run to update `nodePublicAddress`

#### Scenario: Actor object served with current addresses
- **WHEN** a remote peer fetches this node's actor object from the local HTTP server
- **THEN** the response includes both the current `id` (actor URL) and, if available, `x-nightingale-public-address` so peers can attempt delivery to the public address
