## 1. Dependencies & Configuration

- [x] 1.1 Add `multicast_dns` package to `pubspec.yaml` for mDNS advertisement and discovery
- [x] 1.2 Add a STUN client package (evaluate `dart_stun` or implement a minimal RFC 5389 binding request directly over UDP) to `pubspec.yaml`
- [x] 1.3 Add `connectivity_plus` package to `pubspec.yaml` for network change events (if not already present)
- [x] 1.4 Add `FEDERATION_PORT` build env var (default `7777`) and `STUN_SERVER` build env var (default `stun.l.google.com:19302`) to service locator constants

## 2. Federation Server — Remove HTTPS Enforcement, Stable Port

- [x] 2.1 Remove `_httpsEnforcementMiddleware` from `FederationServer.start()` — HTTP connections are accepted directly; HTTP Signatures remain the sole trust mechanism
- [x] 2.2 Replace port `0` with `FEDERATION_PORT` default in `FederationServer.start()`; implement fallback scan to `+1`, `+2` if the port is in use
- [x] 2.3 Expose the bound port via `FederationServer.currentPort` (already exists) and surface it through the service locator so identity and mDNS layers can read it

## 3. Stable Node Addressing — Actor URL & Identity

- [x] 3.1 Add `nodePublicAddress` column (nullable String) to the node identity Drift table; write and run migration
- [x] 3.2 Implement `LocalAddressResolver` — resolves the device's current LAN IP by iterating `NetworkInterface.list()`, filtering to non-loopback IPv4, preferring WiFi interface; returns null if none found
- [x] 3.3 Update actor URL generation in `NodeIdentityRepositoryImpl` to use `http://<LAN-IP>:<port>/users/<username>` — never localhost, never port 0
- [x] 3.4 Update `ActorHandler` to include `x-nightingale-public-address` in the served actor JSON when `nodePublicAddress` is set in the identity table
- [x] 3.5 Add network change listener (via `connectivity_plus`) in `FederationServerLifecycle` that triggers address re-resolution and identity table update on WiFi/cellular transition

## 4. STUN Address Resolution

- [x] 4.1 Implement `StunAddressResolver` — sends a STUN Binding Request to the configured STUN server over UDP; parses the Binding Response to extract the mapped public IP:port; returns null on timeout or parse failure; times out after 5 seconds
- [x] 4.2 Register `StunAddressResolver` as a singleton in the service locator
- [x] 4.3 Call `StunAddressResolver.resolve()` at the end of the onboarding identity setup step; store the result in `nodePublicAddress`; non-blocking (onboarding does not wait for STUN if it is slow)
- [x] 4.4 Re-run `StunAddressResolver.resolve()` on each network change event; update `nodePublicAddress` in the identity table
- [x] 4.5 Write unit test: STUN resolver returns null on timeout without throwing; onboarding completes correctly when STUN returns null

## 5. mDNS Transport

- [x] 5.1 Implement `MdnsAdvertiser` — advertises `_nightingale._tcp` with the node's `preferredUsername` as the service name and the current bound port; starts on server start, stops on server stop
- [x] 5.2 Register `MdnsAdvertiser` as a singleton in the service locator; wire it into `FederationServerLifecycle` start/stop calls
- [x] 5.3 Implement `MdnsDiscoveryService` — browses for `_nightingale._tcp` services, builds an in-memory map of `actorUrlPath → (ip, port)` for discovered peers; refreshes on network change
- [x] 5.4 Register `MdnsDiscoveryService` as a singleton in the service locator; start browsing at app launch
- [x] 5.5 Write integration smoke test: two simulated nodes advertise and discover each other via mDNS on loopback (verifies the advertisement/discovery plumbing without requiring two real devices)

## 6. Reachability — mDNS-aware Resolution Chain

- [x] 6.1 Inject `MdnsDiscoveryService` into `NodeReachabilityService`
- [x] 6.2 Update `NodeReachabilityService.isReachable()` to consult mDNS cache first; if a fresh mDNS entry exists for the actor's URL path, use the mDNS IP:port for the HEAD check
- [x] 6.3 Update `NodeReachabilityService.isReachable()` to check `x-nightingale-public-address` from the cached actor object as a second fallback before the stored actor URL host
- [x] 6.4 Clear `NodeReachabilityService` cache on network change event
- [x] 6.5 Write unit tests: mDNS hit returns correct address; mDNS miss falls through to STUN address; both miss falls through to actor URL

## 7. Decentralised Delivery — Remove Relay, Queue-and-Retry

- [x] 7.1 Delete `lib/features/federation/delivery/relay_client.dart`
- [x] 7.2 Remove `RelayClient` from `ActivityDeliveryService` constructor and all call sites; remove `RELAY_BASE_URL` from service locator
- [x] 7.3 Replace the relay handoff block in `ActivityDeliveryService._attemptDelivery()` with: set status to `pending`, log that delivery will be retried on next foreground; no HTTP call to any relay
- [x] 7.4 Remove `relayed` as a valid outbox status; update any DB queries or UI references that filter on `relayed`
- [x] 7.5 Define `CircuitRelayClient` as an abstract class in `lib/features/federation/delivery/circuit_relay_client.dart` with a single `Future<bool> relay(ApActivity activity, String targetInboxUrl)` method; do not register any implementation in the service locator
- [x] 7.6 Update `ActivityDeliveryService.sweepPendingOnStartup()` to also sweep `retrying` activities that are older than 5 minutes (catches activities that were interrupted mid-retry)
- [x] 7.7 Write unit tests: exhausted retries leave activity as `pending` not `relayed`; sweep picks up stale `retrying` rows; no relay URL is ever called

## 8. Onboarding — Address Resolution Step

- [x] 8.1 Add an address resolution step to the onboarding flow (after identity key generation): resolve LAN IP, construct actor URL, trigger STUN in background; store results before completing onboarding
- [x] 8.2 Ensure the onboarding flow does not block on STUN — LAN IP resolution is synchronous and fast; STUN runs concurrently and updates the identity table when it resolves
- [x] 8.3 Update the debug overlay node identity panel to display: current actor URL, current LAN IP, current `nodePublicAddress` (STUN result), bound port — so it is easy to verify addressing during development

## 9. Remove Relay From Service Locator & Clean Up

- [x] 9.1 Remove `RelayClient` registration from `service_locator.dart`; remove `_kRelayBaseUrl` constant
- [x] 9.2 Remove `relayClient` parameter from `ActivityDeliveryService` constructor and all instantiation sites
- [x] 9.3 Run `flutter analyze` and resolve any dangling references to `RelayClient` or `relayBaseUrl`
- [x] 9.4 Search codebase for `RELAY_BASE_URL`, `relayBaseUrl`, `RelayClient`, `relayed` status string — confirm all are removed or replaced

## 10. Tests

- [x] 10.1 Unit test `LocalAddressResolver`: returns non-loopback IPv4 address; never returns localhost; returns null when no suitable interface found
- [x] 10.2 Unit test `StunAddressResolver`: parses a valid STUN Binding Response correctly; returns null on malformed response; returns null on timeout
- [x] 10.3 Unit test actor URL generation: constructed URL uses LAN IP and stable port; never contains localhost or port 0
- [x] 10.4 Unit test `ActorHandler`: actor JSON includes `x-nightingale-public-address` when `nodePublicAddress` is set; omits field when null
- [x] 10.5 Unit test `ActivityDeliveryService`: after max retries, activity status is `pending`; `sweepPendingOnStartup` re-enqueues pending and stale retrying rows; no relay URL is called under any condition
- [x] 10.6 Unit test `NodeReachabilityService` resolution chain: mDNS hit → mDNS address used; mDNS miss + STUN address in actor → STUN address used; both miss → actor URL used; cache cleared on network change
