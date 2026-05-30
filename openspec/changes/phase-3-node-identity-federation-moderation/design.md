## Context

Phase 2 shipped a standalone local music player. Phase 3 is the inflection point where the app becomes what the product actually is: a federated node. Every architectural decision in this phase has downstream consequences on Phases 4–6. The decisions are asymmetric — getting cryptography, key storage, and the ActivityPub contract wrong is catastrophically expensive to undo on a live network; getting them right creates an immovable foundation.

The app runs on mobile devices that are frequently offline, behind carrier-grade NAT, on dynamic IPs. This is not an edge case — it is the default operating environment. Every design choice in this phase is made against that reality.

## Goals / Non-Goals

**Goals:**
- Each app installation becomes a self-sovereign ActivityPub node with a stable cryptographic identity
- The identity is portable across device changes via a structured migration path
- Federation traffic is authenticated end-to-end: signed on the way out, verified on the way in, replays rejected
- The app serves its own ActivityPub endpoints (inbox, outbox, followers, following, WebFinger) directly from the device
- Moderation infrastructure (defederation, rate limiting, sanitization) is load-bearing from the first deployed node, not added later
- Node unreachability is handled gracefully with relay-assisted delivery and activity queueing

**Non-Goals:**
- Audio streaming (Phase 4) — this phase establishes identity and the activity layer only
- Social graph UI and social activities (Phase 5) — followers/following collections are served but the UI for managing them comes later
- Recommendation signals (Phase 6)
- Any form of centralized relay infrastructure decisions beyond the scaffolding (the relay choice was settled in Phase 0)
- Storing the full outbox history for public browsing — outbox in Phase 3 is structural plumbing; meaningful activity history populates from Phase 4 onward

## Decisions

### 1. Ed25519 over RSA-2048 for the node key pair

Ed25519 produces 32-byte keys and 64-byte signatures vs. RSA-2048's 256-byte signatures and multi-kilobyte keys. Verification is roughly 10× faster on constrained mobile hardware. More practically: the modern fediverse (Mastodon 4.x, Misskey, Calckey/Firefish) is actively migrating toward Ed25519 for actor keys. Starting on RSA-2048 would mean a forced migration later that touches every signed request on the live network.

*Alternative considered:* RSA-2048 for maximum compatibility with legacy fediverse implementations. Rejected — the compatibility window is closing, and the performance and key-size advantages of Ed25519 are material on mobile.

### 2. Private key exclusively in the device secure enclave

The Ed25519 private key is generated inside and never exported from the iOS Keychain (Secure Enclave-backed where available) or Android Keystore. It is never written to app storage, the Drift database, or any network payload. All signing operations are performed by passing a message to the platform key API and receiving a signature back — the key material itself is inaccessible to app code.

*Alternative considered:* Encrypting the key with a user-supplied passphrase and storing in app storage. Rejected — this reintroduces the key-in-key problem (where is the passphrase stored?), adds UX friction, and provides weaker security guarantees than hardware-backed enclaves available on all modern iOS and Android devices (API 23+).

### 3. Account portability via Mastodon-compatible `Move` activity

When a user migrates to a new device, the flow is:
1. Old device exports a signed, human-readable migration token containing the actor URL and public key fingerprint.
2. New device generates a fresh key pair and actor.
3. New device broadcasts an ActivityPub `Move` activity (`actor: old-actor-URL, object: new-actor-URL`) signed by the old key (the user enters the migration token to authorize the signing step on the old device, or the old device initiates the Move directly if both devices are available).
4. Followers of the old actor receive the `Move` and update their following pointers to the new actor URL.
5. Old actor URL serves a `tombstone` redirect.

This is the same mechanism Mastodon uses for server-to-server account migration and is understood by the wider fediverse. The design is specified now so the key format and actor schema are migration-compatible from the first generated identity.

*Alternative considered:* Seed-phrase-based key recovery (export the private key as a BIP-39 mnemonic). Rejected — it requires the user to handle and store the raw key material, which is both a security liability and a UX nightmare for a consumer product. The Move-activity approach recovers the *social graph* (followers, following) without ever exposing the key.

### 4. `shelf` for the embedded ActivityPub server

The app runs a `shelf` HTTP server in an isolate to serve WebFinger, inbox, outbox, followers, and following endpoints. `shelf` is Dart's foundational HTTP server library — zero additional abstraction cost, production-tested, and isolate-friendly. The server is started on app launch (dev: a fixed port; prod: system-assigned, registered with the relay or DDNS).

*Alternative considered:* `dart_frog` — more ergonomic routing, but adds a framework dependency over `shelf` without sufficient payoff for five fixed endpoints. `Dart_frog` wraps `shelf` anyway.

*Alternative considered:* Platform-native server (iOS Network.framework, Android NanoHTTPD). Rejected — language boundary, maintenance burden, inconsistent behavior across platforms.

### 5. HTTP Signatures: draft-cavage-12 for compatibility, Ed25519 signing

The fediverse's de-facto standard remains draft-cavage-http-signatures-12, which Mastodon and most major implementations send and accept. Phase 3 implements:
- **Signing:** Ed25519 over the `(request-target)`, `host`, `date`, `digest` headers, encoded as draft-cavage-12 `Signature` header.
- **Verification:** Accept and verify draft-cavage-12 signatures on all incoming requests; reject any request without a valid signature.
- **Replay protection:** Reject requests where `Date` is outside a ±30-second window of server time, or where the nonce (if present) has been seen within the window. Nonces are stored in an in-memory LRU cache with a 60-second TTL — no persistence needed since replay attacks must arrive within the time window.

*Alternative considered:* RFC 9421 (the finalized IETF spec). Will become the standard, but the majority of the fediverse does not yet support it. The signing implementation is abstracted behind a `HttpSignatureService` interface so the algorithm can be swapped or dual-signed later without touching call sites.

### 6. Activity validation and sanitization: strict schema + JSON-LD compact

All incoming ActivityPub payloads are:
1. JSON-decoded into a typed Dart model (reject anything that doesn't parse).
2. Validated against the expected ActivityPub schema for the activity type.
3. All string fields sanitized (strip HTML, reject URLs to non-HTTPS schemes, reject oversized payloads above a hard limit).
4. Unknown/unrecognized `type` values are dropped, not passed through to app logic.

This is not configurable. There is no "permissive mode." Malformed or unexpected activities are logged (dev) and silently dropped (prod) — not surfaced as errors to the sender, to avoid information leakage about what the validator rejects.

### 7. Rate limiting: per-source sliding window, in-memory

Inbox delivery rate limiting uses a per-source-node sliding window counter stored in memory (no persistence). Default limit: 60 activities per minute per source node. On breach: HTTP 429, `Retry-After` header, logged to the federation inspector. The defederated-node blocklist is checked before rate limiting — defederated nodes receive HTTP 403 immediately.

State is in-memory because:
- A restarting node resets its limits, which is acceptable — the threat model is sustained flooding, not a burst across restarts.
- Persisting per-node rate limit state to Drift adds write pressure on the hot inbox path for marginal security benefit.

### 8. Moderation state in Drift

Defederated nodes, allow/deny list entries, and per-node reputation flags are persisted in Drift. Reason: these are explicit user decisions (or defaults) that must survive app restarts and device reboots. The tables are small and write-rarely/read-often — no meaningful performance concern.

### 9. Node reachability and relay-assisted delivery

The app registers its current address with the relay infrastructure established in Phase 0. The relay holds the routing address for each actor URL and acts as a delivery intermediary when the destination node is not directly reachable. From the sending node's perspective:
1. Attempt direct HTTP delivery to the destination inbox URL.
2. If direct delivery fails (timeout, unreachable, connection refused), hand the activity to the relay with the destination actor URL.
3. The relay queues and delivers when the destination node comes online.

Activity queueing for the sending node: outgoing activities are written to a Drift table before any delivery attempt. The queue is marked delivered on success or handed to the relay on direct failure. The queue survives app restarts.

### 10. Folder structure

```
lib/
  core/
    crypto/             # Ed25519 key generation, secure storage abstraction
    activitypub/        # Actor, Activity, Collection typed models; JSON-LD handling
    http_server/        # shelf isolate, routing, middleware
    federation/         # HttpSignatureService, actor resolution cache, relay client
  features/
    node_identity/      # First-launch identity generation, WebFinger, key migration
    federation/
      serving/          # Inbox, outbox, followers, following endpoint handlers
      delivery/         # Outgoing activity queue, direct delivery, relay handoff
      moderation/       # Defederation, rate limiting, allow/deny list
      reachability/     # Connection state, relay registration, reconnect logic
    debug/              # FederationInspectorTab, WebFingerDebugger (dev-only)
```

## Risks / Trade-offs

**[Risk] The embedded HTTP server is unreachable when the app is backgrounded** → Mitigation: This is expected and documented. The relay-assisted delivery path exists precisely for this case. Phase 3 does not promise direct reachability — it promises that activities eventually arrive. The `node-reachability` spec explicitly frames unreachability as the normal state.

**[Risk] Ed25519 interoperability with older fediverse nodes** → Mitigation: Incoming signature verification accepts Ed25519; if a legacy node sends RSA-signed requests and the receiving node cannot verify them, the activity is dropped and logged. This is a conscious interoperability tradeoff. The spec notes the limitation; full RSA verification can be added later behind the `HttpSignatureService` abstraction if the user base requires it.

**[Risk] Key migration requires the old device to be available** → Mitigation: The migration token export can be done at any time, not just at migration time. Users should be prompted to export a migration token during onboarding. If the old device is lost without a token, the social graph cannot be migrated — this is a property of self-sovereign identity and is communicated honestly in onboarding.

**[Risk] In-memory rate limit state is lost on app restart, allowing a burst after each restart** → Mitigation: The threat model is sustained flood attacks, not single bursts. Persisted rate limit state adds write load on the inbox hot path. Acceptable trade-off for Phase 3; revisit if real-world abuse patterns show restart-cycling attacks.

**[Risk] `shelf` server port conflicts in multi-app environments or after force-kill** → Mitigation: Use `ServerSocket.bind(InternetAddress.anyIPv4, 0)` (system-assigned port) and register the assigned port with the relay on each app launch. The relay always has the current port.

## Open Questions

1. **WebFinger domain**: What string constitutes the node's `@user@<domain>` domain segment? On mobile, there is no stable hostname. Options: (a) a relay-assigned stable subdomain per node; (b) the node's public key fingerprint as a pseudo-domain. This depends on the relay infrastructure chosen in Phase 0 — needs resolution before `node-identity` spec is finalized if the relay provides stable routing names.

2. **Migration token UX**: The migration token must be exportable before the old device is lost. Where in the onboarding or settings flow is this surfaced without being alarming to non-technical users? ("Back up your identity" vs. "Export migration token.") Defer detailed UX to Phase 7 polish, but the underlying mechanism must be ready now.

3. **Outbox page size and pagination**: ActivityPub outbox collections must support pagination. In Phase 3 the outbox is sparse (few activities until Phase 4+). Is a single-page outbox acceptable for Phase 3, or should pagination be implemented preemptively? Recommendation: implement the `OrderedCollectionPage` wrapper now with a hard limit of 20 items, even if it always returns one page — avoids a schema change later.

4. **Content-Type negotiation**: ActivityPub requires serving `application/activity+json` or `application/ld+json; profile="..."`. Does the shelf server need to handle both, or can it hardcode `application/activity+json` for Phase 3? Recommendation: hardcode `application/activity+json` for Phase 3; Mastodon and the majority of modern implementations accept it.
