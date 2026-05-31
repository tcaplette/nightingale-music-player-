## ADDED Requirements

### Requirement: mDNS service advertisement
The app SHALL advertise its federation server as a `_nightingale._tcp` mDNS service on startup so that other Nightingale nodes on the same network segment can discover it without any configuration.

#### Scenario: Node advertises on startup
- **WHEN** the federation server starts successfully
- **THEN** the app broadcasts a `_nightingale._tcp` mDNS record containing the node's display name, port, and actor URL path

#### Scenario: Advertisement stops when server stops
- **WHEN** the federation server is stopped (app paused or backgrounded)
- **THEN** the mDNS advertisement is withdrawn so peers stop attempting delivery to an offline node

#### Scenario: Advertisement resumes on server restart
- **WHEN** the federation server restarts after the app resumes from background
- **THEN** the mDNS advertisement is re-broadcast with the current port

---

### Requirement: mDNS peer discovery
The system SHALL discover other Nightingale nodes on the local network via mDNS and make their current IP:port available to the delivery and reachability layers without requiring the user to manually enter addresses.

#### Scenario: Local peer is discovered automatically
- **WHEN** another device running Nightingale is on the same WiFi network
- **THEN** the local node discovers it via mDNS and resolves its current IP and port

#### Scenario: mDNS result overrides stale actor URL for local peers
- **WHEN** the reachability layer attempts to contact a known actor URL and mDNS has a fresher address for that node
- **THEN** the mDNS-resolved address is used in preference to the stored actor URL

#### Scenario: mDNS discovery fails gracefully
- **WHEN** mDNS is blocked by the network (e.g. enterprise WiFi) or returns no results
- **THEN** the system falls through to STUN-discovered or stored addresses without surfacing an error to the user
