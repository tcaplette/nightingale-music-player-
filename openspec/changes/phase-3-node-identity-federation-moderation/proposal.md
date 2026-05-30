## Why

Phase 2 delivered a fully functional local music player. Phase 3 transforms each installation into an actual node on the federated network: the app generates its own cryptographic identity, stands up ActivityPub endpoints it serves directly from the device, and ships moderation and abuse defenses as load-bearing infrastructure — not afterthoughts — because retrofitting them onto a live federated network is brutally hard.

## What Changes

- **New:** node identity — on first launch the app generates an Ed25519 key pair and a fully-specified ActivityPub Actor; the private key is stored exclusively in the device secure enclave (iOS Keychain / Android Keystore) and never leaves it; the raw `@user@node` handle exists in the protocol but is never the primary UI presentation
- **New:** account portability — a key migration mechanism modeled on Mastodon's `Move` activity so a user upgrading or replacing a device can carry their identity, followers, and following forward rather than orphaning the account; designed now so it is never a retrofit
- **New:** WebFinger endpoint — the app serves `/.well-known/webfinger` so any other node on the network can discover its Actor
- **New:** ActivityPub layer — the app serves its own inbox, outbox, followers collection, and following collection; all federation traffic is HTTPS/TLS only; all outgoing requests are signed with HTTP Signatures; all incoming requests are verified; stale or replayed signed requests are rejected via nonce/timestamp window
- **New:** moderation and abuse defense — node-level defederation (block an entire hostile node, not just individual actors); rate limiting on inbox delivery; allow/deny list scaffolding; activity validation and sanitization on every ingested payload
- **New:** node reachability (best-effort) — the app attempts to maintain a reachable address but treats unreachability as the expected state; relay-assisted inbox delivery when the node is not directly reachable; connection state management with retry/reconnection; activity queueing so deliveries survive an offline node
- **New:** Phase 3 debug overlay additions — federation inspector tab and WebFinger resolution debugger (compile-time gated, dev-only, no shake gesture)

## Capabilities

### New Capabilities

- `node-identity`: Generate and persist a federated identity on first launch — Ed25519 key pair (private key in device secure enclave only), ActivityPub Actor object (id, inbox, outbox, followers, following, publicKey), WebFinger endpoint served from the app; account portability via `Move` activity so identity survives a device change; raw handle never surfaced as primary UI
- `activitypub-layer`: Stand up and operate the node's ActivityPub surface — serve inbox, outbox, followers collection, and following collection; enforce HTTPS/TLS on all connections; sign all outgoing requests and verify all incoming with HTTP Signatures; reject replayed or stale requests via nonce/timestamp window; fetch and resolve remote Actor objects by handle; deliver signed activities to remote node inboxes
- `moderation-abuse-defense`: Built-in safeguards against hostile nodes — node-level defederation (block an entire node); rate limiting on inbox delivery; allow/deny list scaffolding for nodes; strict activity validation and sanitization on every ingested payload (never trust incoming data)
- `node-reachability`: Best-effort network presence layer — attempt to maintain a reachable address while treating unreachability as the normal state; relay-assisted inbox delivery when not directly reachable; connection state management with retry and reconnection logic; activity queueing so activities for an offline node are held and delivered when it returns
- `federation-debug-inspector`: Phase 3 debug overlay additions — federation inspector tab (outgoing activity log with full JSON and HTTP response, incoming activity log, HTTP Signature verification status including replay-rejection events, actor resolution cache viewer, node reachability status, defederation/rate-limit state viewer) and WebFinger resolution debugger; compile-time gated, never in release builds

### Modified Capabilities

## Impact

- **Dependencies added:** `shelf` (or `dart_frog`) for serving ActivityPub endpoints from the device; `ed25519_edwards` or `cryptography` for Ed25519 key operations; `flutter_secure_storage` for secure enclave integration; `http_parser` for HTTP Signature construction and verification; `drift` migration (already present from Phase 2) extended with federation schema tables
- **Platform entitlements:** iOS Keychain entitlement (`keychain-access-groups`); Android Keystore usage (no additional manifest permission, but Keystore API must target API 23+)
- **Architecture:** introduces `lib/features/federation/` as the primary new feature tree; `lib/core/crypto/` for key management; `lib/core/activitypub/` for Actor, activity, and collection types; `lib/core/http_server/` for the embedded endpoint server; federation schema tables added to the existing Drift database
- **Debug overlay:** one new tab (`FederationInspectorTab`) registered into the existing Phase 1 overlay infrastructure
- **No breaking changes** to Phase 1 or Phase 2 deliverables; the `AudioSource` abstraction from Phase 2 is intentionally left untouched (Phase 4 extends it)
