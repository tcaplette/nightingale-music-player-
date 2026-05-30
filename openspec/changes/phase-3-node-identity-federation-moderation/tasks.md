## 1. Dependencies & Package Setup

- [x] 1.1 Add `cryptography` (Ed25519 key operations) to `pubspec.yaml`
- [x] 1.2 Add `flutter_secure_storage` (secure enclave integration) to `pubspec.yaml`
- [x] 1.3 Add `shelf` and `shelf_router` (embedded ActivityPub HTTP server) to `pubspec.yaml`
- [x] 1.4 Add `http` (outgoing federation HTTP client) to `pubspec.yaml` if not already present
- [x] 1.5 Configure iOS Keychain entitlement (`keychain-access-groups`) in `ios/Runner.entitlements`
- [x] 1.6 Verify Android `minSdkVersion` is 23+ (required for Android Keystore API)

## 2. Drift Schema — Federation Tables

- [x] 2.1 Create Drift table `node_identity`: stores actor URL, public key PEM, preferred username, display name, created timestamp
- [x] 2.2 Create Drift table `inbox_activities`: stores incoming ActivityPub activities (id, type, actor, object JSON, received timestamp, processed flag)
- [x] 2.3 Create Drift table `outbox_activities`: stores outgoing activities (id, type, target inbox URL, payload JSON, status enum: pending/retrying/relayed/delivered/failed, attempt count, last attempted timestamp)
- [x] 2.4 Create Drift table `actor_cache`: stores resolved remote Actor objects (actor URL, actor JSON, cached timestamp, ttl)
- [x] 2.5 Create Drift table `followers`: stores follower actor URLs and their fetch timestamps
- [x] 2.6 Create Drift table `following`: stores following actor URLs and their fetch timestamps
- [x] 2.7 Create Drift table `defederated_nodes`: stores blocked domain strings and block timestamps
- [x] 2.8 Create Drift table `node_allow_deny_list`: stores domain strings with a `policy` enum (allow/deny)
- [x] 2.9 Write and run Drift migration to add all new tables to the existing Phase 2 database schema

## 3. Crypto & Secure Storage Layer (`lib/core/crypto/`)

- [x] 3.1 Create `CryptoService` abstract class with methods: `generateKeyPair()`, `sign(List<int> message)`, `getPublicKeyPem()`
- [x] 3.2 Implement `PlatformCryptoService` using `flutter_secure_storage` for private key persistence and `cryptography` package for Ed25519 operations; private key bytes are stored under a fixed Keychain/Keystore key and never returned to caller
- [x] 3.3 Implement `sign()` such that it reads the private key from secure storage, performs Ed25519 signing, and returns only the signature bytes
- [x] 3.4 Implement `getPublicKeyPem()` to return the Ed25519 public key in PEM-encoded `SubjectPublicKeyInfo` format suitable for ActivityPub `publicKeyPem`
- [x] 3.5 Write unit tests: verify `sign()` produces a signature verifiable with the corresponding public key; verify private key is never surfaced in return values or logs

## 4. ActivityPub Typed Models (`lib/core/activitypub/`)

- [x] 4.1 Create `Actor` Dart class covering all required fields: `id`, `type`, `inbox`, `outbox`, `followers`, `following`, `preferredUsername`, `name`, `publicKey` (nested `PublicKey` object with `id`, `owner`, `publicKeyPem`); add `fromJson` / `toJson`
- [x] 4.2 Create `Activity` sealed class hierarchy covering: `Create`, `Update`, `Delete`, `Follow`, `Accept`, `Reject`, `Undo`, `Like`, `Announce`, `Move`; each with `fromJson` / `toJson`
- [x] 4.3 Create `OrderedCollection` and `OrderedCollectionPage` classes with `fromJson` / `toJson`
- [x] 4.4 Create `WebFingerJrd` class covering `subject`, `aliases`, `links` (with `rel`, `type`, `href`); add `fromJson`
- [x] 4.5 Add `@context` constants for ActivityStreams 2.0 and W3C security context
- [x] 4.6 Write unit tests for serialization round-trips of all model types

## 5. Activity Validation & Sanitization (`lib/core/activitypub/`)

- [x] 5.1 Create `ActivitySanitizer` class that: strips HTML from all string fields, nulls out non-HTTPS URLs, rejects payloads exceeding 64 KB before parsing
- [x] 5.2 Create `ActivityValidator` that maps incoming `type` field to the `Activity` sealed class and returns a typed error for unknown types (never throws)
- [x] 5.3 Write unit tests: HTML in `name` field is stripped; non-HTTPS `url` is nulled; oversized payload returns error before parse; unknown type returns typed drop result

## 6. Node Identity — First Launch & Actor Management (`lib/features/node_identity/`)

- [x] 6.1 Create `NodeIdentityRepository` with methods: `hasIdentity()`, `generateIdentity(displayName)`, `getLocalActor()`, `getActorUrl()`
- [x] 6.2 Implement `generateIdentity()`: call `CryptoService.generateKeyPair()`, build `Actor` object with all required fields, persist to `node_identity` Drift table
- [x] 6.3 Create `NodeIdentityNotifier` (Riverpod) that checks for an existing identity on app start and triggers first-launch setup if none exists
- [x] 6.4 Create the first-launch identity setup screen: asks for display name and optional avatar only — no mention of handles, federation, or ActivityPub in the UI copy
- [x] 6.5 Ensure `NodeIdentityNotifier` is initialized at app startup before any federation-dependent feature is accessed

## 7. Embedded ActivityPub HTTP Server (`lib/core/http_server/`)

- [x] 7.1 Create `FederationServer` that starts a `shelf` HTTP server in an Isolate on a system-assigned port; exposes `start()`, `stop()`, and `currentPort` getter
- [x] 7.2 Wire `shelf_router` routes: `GET /.well-known/webfinger`, `GET /users/:username`, `POST /users/:username/inbox`, `GET /users/:username/outbox`, `GET /users/:username/followers`, `GET /users/:username/following`
- [x] 7.3 Add middleware: HTTPS-only enforcement (redirect or refuse plaintext), request size limiter (reject >64 KB bodies before routing), `Content-Type: application/activity+json` on all ActivityPub responses
- [x] 7.4 Start `FederationServer` in an Isolate from app startup; surface the assigned port to `NodeReachabilityService` for relay registration
- [x] 7.5 Ensure `FederationServer` isolate is stopped cleanly on app lifecycle pause/resume transitions

## 8. ActivityPub Endpoint Handlers

- [x] 8.1 Implement `WebFingerHandler`: parse `resource` query param, validate it matches the local user, return JRD with `rel: self` link; return 404 for non-matching resources
- [x] 8.2 Implement `ActorHandler`: return the local `Actor` JSON with correct `Content-Type`; serve over HTTPS only
- [x] 8.3 Implement `InboxHandler`: enforce rate limit check → defederation check → HTTP Signature verification → replay protection → payload size check → sanitize → validate → store in `inbox_activities`; return 202 on success, 403/429/400/401 on rejection
- [x] 8.4 Implement `OutboxHandler`: query `outbox_activities` with a page cursor; return `OrderedCollectionPage` with up to 20 items and `next`/`prev` links; return `OrderedCollection` wrapper at the root outbox URL
- [x] 8.5 Implement `FollowersHandler`: return `OrderedCollection` with `totalItems` count from the `followers` Drift table
- [x] 8.6 Implement `FollowingHandler`: return `OrderedCollection` with `totalItems` count from the `following` Drift table

## 9. HTTP Signature Service (`lib/core/federation/`)

- [x] 9.1 Create `HttpSignatureService` with methods: `signRequest(HttpRequest)` → adds `Date`, `Digest`, and `Signature` headers; `verifyRequest(IncomingRequest)` → returns typed `SignatureResult` (verified / failed / missing / replayed)
- [x] 9.2 Implement `signRequest()`: build the signing string from `(request-target)`, `host`, `date`, `digest`; call `CryptoService.sign()`; format as draft-cavage-12 `Signature` header with correct `keyId`, `algorithm`, `headers`, `signature` fields
- [x] 9.3 Implement `verifyRequest()`: extract `Signature` header, fetch signing actor's public key (via actor resolution cache), reconstruct signing string, verify Ed25519 signature; also verify `Date` is within ±30-second window
- [x] 9.4 Implement replay protection in `verifyRequest()`: maintain an in-memory LRU nonce store with 60-second TTL; reject requests whose nonce is already present; record new nonces on acceptance
- [x] 9.5 Write unit tests: sign then verify round-trip succeeds; tampered header fails; expired `Date` fails; replayed nonce fails; missing signature returns `missing` result

## 10. Actor Resolution & Cache (`lib/core/federation/`)

- [x] 10.1 Create `ActorResolver` with `resolve(String handleOrUrl)` returning `Future<Actor>`; checks `actor_cache` Drift table first, fetches from network on cache miss, stores result with a 15-minute TTL
- [x] 10.2 Implement WebFinger step: parse handle `@user@domain`, GET `https://domain/.well-known/webfinger?resource=acct:user@domain`, parse JRD, extract `rel: self` href
- [x] 10.3 Implement actor fetch step: GET the actor URL with `Accept: application/activity+json`, parse response into `Actor` model
- [x] 10.4 Add cache invalidation method `invalidate(String actorUrl)` for use by the debug inspector
- [x] 10.5 Write unit tests: cache hit returns cached actor without network call; cache miss triggers fetch and stores result; WebFinger 404 returns typed error; actor fetch parse failure returns typed error

## 11. Outgoing Activity Delivery (`lib/features/federation/delivery/`)

- [x] 11.1 Create `ActivityDeliveryService` with `deliver(Activity activity, String targetInboxUrl)` that writes to `outbox_activities` with status `pending` and enqueues a delivery job
- [x] 11.2 Implement direct delivery: sign the request with `HttpSignatureService`, POST to `targetInboxUrl` over HTTPS; on 2xx mark as `delivered`; on 5xx or timeout mark as `retrying` with incremented attempt count
- [x] 11.3 Implement exponential back-off retry: delays of 5s, 10s, 20s for attempts 1–3; after 3 failed attempts hand the activity to `RelayClient` and update status to `relayed`
- [x] 11.4 Create `RelayClient` stub with `handOff(Activity activity, String targetActorUrl)` that posts to the relay endpoint (URL from config); update queue entry with relay reference ID on success
- [x] 11.5 Add a startup delivery sweep: on app launch, query `outbox_activities` for entries in `pending` or `retrying` status and re-enqueue them
- [x] 11.6 Write unit tests: successful delivery marks entry delivered; 3 consecutive failures trigger relay handoff; startup sweep re-enqueues stale pending entries

## 12. Moderation & Abuse Defense (`lib/features/federation/moderation/`)

- [x] 12.1 Create `ModerationRepository` with: `isDefederated(String domain)`, `defederate(String domain)`, `removeDefederation(String domain)`, `getDenyList()`, `getAllowList()`, `addToList(String domain, ListPolicy policy)`; backed by Drift
- [x] 12.2 Create `RateLimiter` with `checkAndRecord(String sourceDomain)` → returns `allowed` or `rateLimited`; implements per-source sliding window with 60-activity/minute default; in-memory LRU, not persisted
- [x] 12.3 Wire `ModerationRepository.isDefederated()` as the first check in `InboxHandler` — before rate limiting, before signature verification
- [x] 12.4 Wire `RateLimiter.checkAndRecord()` as the second check in `InboxHandler` — after defederation, before signature verification
- [x] 12.5 Wire outgoing delivery suppression in `ActivityDeliveryService`: before any delivery attempt, check `ModerationRepository.isDefederated(targetDomain)` and cancel the delivery if true
- [x] 12.6 Write unit tests: defederated domain returns 403 before rate limit is checked; rate limit breach returns 429 with `Retry-After`; allow/deny list entries round-trip through Drift

## 13. Node Reachability (`lib/features/federation/reachability/`)

- [x] 13.1 Create `NodeReachabilityService` with `register()` that POSTs the current actor URL and server address/port to the relay registration endpoint; exposes a `ReachabilityState` stream (registered / pending / failed)
- [x] 13.2 Call `register()` on app launch after `FederationServer` starts and the port is known; retry with exponential back-off if registration fails — do not block app startup
- [x] 13.3 Listen for network connectivity changes (via `connectivity_plus` or equivalent) and re-call `register()` on each network transition
- [x] 13.4 Create `ReachabilityState` enum/sealed class: `registered(address, port)`, `pending`, `failed(reason)`, `offline`; expose via Riverpod provider
- [x] 13.5 Ensure the inbox deduplication check is in place: on storing an incoming activity, check `inbox_activities` for an existing record with the same `id` field and discard if found

## 14. Account Portability — Migration Token & Move Activity (`lib/features/node_identity/`)

- [x] 14.1 Create `MigrationService` with `exportToken()` → returns a signed, base64-encoded token containing actor URL and Unix timestamp (signed with the local private key via `CryptoService.sign()`)
- [x] 14.2 Create settings UI entry point "Export migration token" that shows the token as a copyable string and QR code; does not label it with any cryptographic terminology in the primary label
- [x] 14.3 Implement `initiateMove(String migrationToken, String newActorUrl)`: validate the token signature and timestamp (must be within 72 hours, not previously used); broadcast an ActivityPub `Move` activity to all followers; mark the token as used in Drift
- [x] 14.4 Mark used migration tokens in a Drift table (`migration_tokens`) with `token_hash`, `used_at` timestamp, `new_actor_url` to prevent reuse
- [x] 14.5 Write unit tests: expired token (>72h) is rejected; previously used token is rejected; valid token produces a correctly structured `Move` activity with proper `actor` and `object` fields

## 15. Federation Debug Inspector (`lib/features/debug/`)

- [x] 15.1 Create `FederationInspectorTab` widget — a new tab registered into the existing Phase 1 debug overlay tab list; compile-time gated behind the same `kDebugMode` flag as existing overlay tabs
- [x] 15.2 Create `OutgoingActivityLogPanel`: subscribes to a stream of outgoing delivery events; shows timestamp, destination, activity type, JSON payload (formatted, expandable), HTTP response code, and status chip (delivered/retrying/relayed/failed)
- [x] 15.3 Create `IncomingActivityLogPanel`: subscribes to inbox events; shows timestamp, source actor URL, activity type, signature verification result chip (verified/failed/missing), and outcome (accepted/dropped/rate-limited)
- [x] 15.4 Create `SignatureStatusPanel`: lists all incoming requests from the current session with signature outcome; flags replay rejections in a distinct error style showing nonce, timestamp, source (merged into IncomingActivityLogPanel — signature detail shown per-entry)
- [x] 15.5 Create `ActorCachePanel`: reads from the actor resolution cache; lists entries with actor URL, `preferredUsername`, cache age, TTL remaining; includes "Invalidate" button per entry that calls `ActorResolver.invalidate()`
- [x] 15.6 Create `ReachabilityStatusPanel`: reads from `ReachabilityState` stream; shows current address/port, relay registration status, last registered timestamp
- [x] 15.7 Create `ModerationStatePanel`: shows defederated domains list with timestamps; shows live rate-limit sliding-window counters for active source nodes
- [x] 15.8 Create `WebFingerDebuggerPanel`: text field for entering `acct:user@domain` or a URL; "Resolve" button that calls `ActorResolver.resolve()` and displays the WebFinger endpoint called, raw JRD response (formatted), and resolved actor URL — or the error detail on failure
- [x] 15.9 Register all panels as sections within `FederationInspectorTab`; ensure no panel code is included in the release build (verify with `dart compile` tree-shaking in CI)
