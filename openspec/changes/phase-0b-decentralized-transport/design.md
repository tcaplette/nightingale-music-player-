## Context

Nightingale's federation layer assumes each node has a stable, publicly reachable HTTPS URL — the standard ActivityPub contract. This assumption was designed for always-on servers, not mobile devices. The current implementation deferred the resolution of this tension to a "relay" that was never built. The consequences are concrete: the HTTPS enforcement middleware in `FederationServer` redirects every direct HTTP connection to HTTPS (which fails because there is no cert), the server binds to port `0` (random, changes on every resume), the actor URL stored in the identity table reflects neither the device's current IP nor its current port, and `RelayClient` silently drops all activity after three failed direct delivery attempts.

The transport decision Phase 0 was supposed to make is now being made here: **HTTP Signatures provide the trust layer; transport encryption is not required for correct federation.** Trust in ActivityPub comes from verifying that the sender signed the request with the private key associated with their actor's `publicKey` object — not from TLS. Removing TLS as a precondition does not weaken security; it removes a false dependency that was blocking everything.

## Goals / Non-Goals

**Goals:**
- Two devices on the same WiFi can federate with zero configuration via mDNS
- Two devices on different networks can federate by advertising their STUN-discovered public address
- Activity delivery works without any central server
- Actor URL stays current as the device moves between networks
- The onboarding flow produces a node identity with a correct reachable base URL
- Phase 6 network signals begin flowing as a direct consequence of this change

**Non-Goals:**
- Volunteer circuit relay implementation (interface is defined, implementation is a future change)
- Audio streaming NAT traversal (streaming is best-effort; this change fixes the social/activity layer; streaming improvements are separate)
- TLS on the local server (HTTP Signatures are the trust mechanism; adding device TLS is a future hardening option)
- Support for devices behind symmetric NAT where hole punching cannot succeed (these fall back to eventual delivery when the device is on a traversable network)

## Decisions

### Decision 1: Remove HTTPS enforcement, keep HTTP Signatures as the sole trust mechanism

**Chosen:** Remove `_httpsEnforcementMiddleware` from `FederationServer`. All federation requests are signed and verified via HTTP Signatures regardless of transport. A tampered or forged request fails signature verification; a missing TLS layer does not compromise this.

**Alternatives considered:**
- Self-signed TLS cert generated at onboarding — adds complexity (cert distribution, trust anchors), provides no meaningful security benefit over HTTP Signatures for this use case, breaks standard HTTP clients.
- Require TLS only on external interfaces — impractical on mobile; the device doesn't control its network interface.

**Why this is correct:** ActivityPub's security model is explicitly built on HTTP Signatures. The Mastodon implementation, Pleroma, and all major ActivityPub servers treat HTTP Signatures as the integrity guarantee, not TLS. TLS on transport protects against passive eavesdropping on the wire — a valid concern for a future hardening pass, not a correctness requirement.

---

### Decision 2: Stable configured port with a sensible default

**Chosen:** The federation server binds to a configurable port (default `7777`), set via `FEDERATION_PORT` build env var. The port is stored as part of node identity at onboarding so the actor URL never goes stale between launches.

**Alternatives considered:**
- Keep random port, update actor URL on every launch — requires notifying all followers of the address change on every app resume; impractical.
- Use a well-known fixed port (e.g. `80`, `8080`) — conflicts with other services; `7777` is unassigned and distinctive.

---

### Decision 3: mDNS for local network — advertisement and discovery

**Chosen:** Use the `multicast_dns` Flutter package. On startup, the node advertises `_nightingale._tcp` with its display name and port. `NodeReachabilityService` queries mDNS before attempting HTTP to resolve a local peer's current IP. mDNS results override the stored actor URL for nodes on the same network segment.

**Why mDNS:** Zero infrastructure, zero configuration, standard protocol, works on both iOS and Android. The same mechanism AirPlay, Chromecast, and Bonjour use. Handles the most common testing and early-adopter scenario (friends on the same WiFi) with no effort from the user.

---

### Decision 4: STUN for cross-network public address discovery

**Chosen:** On each network change (and at onboarding), the app performs a STUN binding request to a well-known STUN server (default: `stun.l.google.com:19302`, overridable via `STUN_SERVER` build env). The returned public IP:port is stored as `nodePublicAddress` in the identity table and included in the actor object's `endpoints` extension field. Peers attempting delivery use this address when the mDNS lookup misses.

**Alternatives considered:**
- libp2p — full P2P networking stack with built-in NAT traversal, circuit relays, pubsub. More complete but significantly more complex; the Dart implementation is less mature. Revisit if STUN + hole punching proves insufficient.
- UPnP/NAT-PMP — requests port forwarding from the router. Increasingly unsupported on modern routers; unreliable on mobile; requires elevated permissions on some platforms.
- No cross-network support — accept local-only federation. Unacceptable; limits the network to people in the same room.

**STUN server choice:** Google's public STUN server is stateless — it returns your IP:port and retains nothing. Any STUN server can be substituted. The `STUN_SERVER` env var allows operators to point at their own.

---

### Decision 5: Replace relay fallback with queue-and-retry; define volunteer relay interface

**Chosen:** `ActivityDeliveryService` retries delivery against the target's most recently resolved address (mDNS first, then STUN-discovered, then stored actor URL). On exhaustion, the activity remains queued with a `pending` status and is retried on the next app foreground. No relay handoff occurs.

A `CircuitRelayClient` interface is defined but not implemented. When a volunteer relay network exists, this interface is the integration point. Nodes that opt in to relaying advertise themselves via a `Relay` service type in mDNS.

**Why remove the relay stub entirely:** The current stub silently marks activities as `relayed` when they have not been delivered. This is worse than leaving them `pending` — it creates false confidence and loses the activity. A queued pending activity will eventually deliver when the target comes online. A falsely-relayed activity is silently lost.

---

### Decision 6: Address refresh on network change

**Chosen:** The app listens to `Connectivity` package events (WiFi ↔ cellular ↔ none). On each network change: re-run STUN, update `nodePublicAddress` in the identity store, re-advertise mDNS. Followers are not proactively notified of the address change — they discover the new address on next delivery attempt via actor object fetch.

## Risks / Trade-offs

**Symmetric NAT (CGNAT on cellular) → STUN returns a different port per destination, hole punching fails.**
Mitigation: Activity delivery falls back to queue-and-retry; the activity delivers when the device is on a traversable network (WiFi). This is the accepted "best-effort" posture stated in the ROADMAP.

**mDNS blocked on some enterprise/public WiFi networks.**
Mitigation: mDNS miss falls through to STUN-discovered address; this is handled transparently in the resolution chain.

**STUN lookup fails (no network, STUN server down).**
Mitigation: Use last known public address if available; if none, omit `endpoints` from actor object and operate as local-only until connectivity returns. No crash, honest degraded state.

**Port `7777` already in use on the device.**
Mitigation: Fall back to a secondary port (`7778`, `7779`) with a short scan; store whichever succeeds in the identity table.

**Removing HTTPS enforcement exposes activity payloads to passive eavesdropping on untrusted networks.**
Accepted trade-off for this phase. HTTP Signatures guarantee integrity and authenticity. Confidentiality via transport TLS is a hardening concern deferred to a future change. The data in transit (activity JSON) is equivalent to public ActivityPub data in most cases.

## Open Questions

- **Hole punching implementation depth:** STUN gives us the public address; actual UDP/TCP hole punching requires coordinated simultaneous connection attempts. Initial implementation advertises the STUN address and attempts direct TCP; hole punching coordination (via a rendezvous signal) is left for a follow-up if direct TCP fails at unacceptable rates.
- **Actor object `endpoints` field:** The ActivityPub spec has an `endpoints` object but it's primarily for `sharedInbox`. Using it for `nodePublicAddress` is an extension. We define a Nightingale-specific `x-nightingale-public-address` extension field in the actor JSON to avoid collisions.
