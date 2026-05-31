## Why

Phase 0 was meant to answer a foundational question — can two phones reach each other's inboxes and stream audio across real networks — but that decision was never recorded and the architecture proceeded with a relay stub (`RelayClient` / `RELAY_BASE_URL`) that assumes a central TLS-terminating server exists. That server was never built, is not decentralised, and is incompatible with the "app is the node" principle. As a result, federation between devices does not work: the HTTPS enforcement middleware rejects all direct connections, the actor URL is wrong (random port, unresolved IP), and activity delivery silently fails. Phase 6's recommendation engine is structurally complete but receives no network signals because no activities ever arrive. This must be resolved before the app can be meaningfully tested with more than one device.

## What Changes

- **BREAKING** Remove `RelayClient` and `RELAY_BASE_URL` — the centralised relay stub is replaced entirely
- **BREAKING** Remove the HTTPS enforcement middleware from `FederationServer` — TLS is no longer a precondition for direct connections; trust is established via HTTP Signatures, not transport encryption
- Fix the federation server port from system-assigned (`0`) to a stable configured default
- Fix actor URL generation to resolve and advertise the device's actual reachable address at onboarding time
- Add mDNS service advertisement and discovery so devices on the same network find each other automatically with zero configuration
- Add STUN client so devices on different networks can discover their public IP/port and advertise a reachable actor URL
- Add address refresh on network change (WiFi ↔ cellular) so the actor URL stays current
- Replace relay fallback in `ActivityDeliveryService` with queue-and-retry against the target's most recently resolved address
- Update onboarding to run address resolution and store the reachable base URL as part of node identity setup

## Capabilities

### New Capabilities
- `mdns-transport`: mDNS service advertisement and peer discovery for zero-config local network federation
- `stun-address-resolution`: STUN-based public IP/port discovery for cross-network actor URL advertisement
- `stable-node-addressing`: Stable port configuration, address resolution at onboarding, address refresh on network change, actor URL kept current in identity store
- `decentralised-delivery`: Queue-and-retry activity delivery against resolved addresses; no relay dependency; volunteer circuit relay opt-in hook (interface only, implementation deferred)

### Modified Capabilities
- `node-reachability`: Reachability checks now use the mDNS-resolved or STUN-resolved address rather than whatever is in the actor URL; cache invalidated on network change
- `node-identity`: Actor ID and base URL now include the resolved reachable address set at onboarding; updated when network address changes

## Impact

- `lib/core/http_server/federation_server.dart` — remove HTTPS enforcement middleware; expose stable port
- `lib/features/federation/delivery/relay_client.dart` — deleted
- `lib/features/federation/delivery/activity_delivery_service.dart` — remove relay fallback; pure queue-and-retry
- `lib/core/di/service_locator.dart` — remove `RelayClient` registration; add mDNS and STUN service registrations
- `lib/features/node_identity/` — actor URL generation updated to use resolved address
- `lib/features/onboarding/` — onboarding flow gains address resolution step
- `lib/features/federation/reachability/` — reachability service updated to consult mDNS cache
- New dependencies: `multicast_dns` (mDNS), a STUN client package (e.g. `dart_stun` or equivalent)
- Phase 6 network signal pipeline activates automatically once delivery works
- Phase 7 integration test "full federation round-trip" becomes testable
