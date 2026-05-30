## ADDED Requirements

### Requirement: HTTPS/TLS enforcement
The system SHALL accept and serve all ActivityPub and WebFinger traffic exclusively over HTTPS/TLS. Plaintext HTTP connections to ActivityPub endpoints SHALL be refused or redirected; plaintext HTTP connections to remote endpoints SHALL never be initiated by the app.

#### Scenario: Incoming plaintext connection is rejected
- **WHEN** an incoming ActivityPub request arrives over plaintext HTTP
- **THEN** the server returns HTTP 301 redirect to HTTPS, or closes the connection without processing the payload

#### Scenario: Outgoing requests use HTTPS only
- **WHEN** the app delivers an activity to a remote inbox
- **THEN** the request is sent over HTTPS
- **WHEN** the remote inbox URL uses a plaintext `http://` scheme
- **THEN** the delivery is rejected and logged as a configuration error — not silently upgraded

---

### Requirement: HTTP Signature signing on outgoing requests
The system SHALL sign all outgoing ActivityPub HTTP requests using the node's Ed25519 private key and the draft-cavage-http-signatures-12 `Signature` header scheme. Unsigned outgoing requests to federation endpoints SHALL not be sent.

#### Scenario: Outgoing inbox delivery is signed
- **WHEN** the app delivers an activity to a remote node's inbox
- **THEN** the HTTP request includes a `Signature` header containing the key ID, algorithm, signed headers, and signature value
- **THEN** the signed headers include at minimum `(request-target)`, `host`, `date`, and `digest`
- **THEN** the signature is produced using the local Ed25519 private key via the platform secure enclave API

#### Scenario: Signature uses the correct key ID
- **WHEN** a remote node verifies the signature on an incoming request
- **THEN** the `keyId` field in the `Signature` header resolves via HTTP GET to the local actor's `publicKey.id`
- **THEN** the public key retrieved at that URL matches the key used for signing

---

### Requirement: HTTP Signature verification on incoming requests
The system SHALL verify the HTTP Signature on every incoming request to the inbox endpoint. Requests without a valid signature, or with a signature that fails verification, SHALL be rejected with HTTP 401.

#### Scenario: Valid incoming signature is accepted
- **WHEN** an incoming inbox POST carries a well-formed `Signature` header with a valid Ed25519 or RSA signature
- **THEN** the system fetches the signing actor's public key (from cache or via actor fetch), verifies the signature against the request headers, and processes the activity

#### Scenario: Missing signature is rejected
- **WHEN** an incoming inbox POST has no `Signature` header
- **THEN** the system returns HTTP 401 and drops the request

#### Scenario: Invalid signature is rejected
- **WHEN** an incoming inbox POST has a `Signature` header that fails cryptographic verification
- **THEN** the system returns HTTP 401, logs the failure (dev: with detail; prod: without key information), and drops the request

---

### Requirement: Signature replay protection
The system SHALL reject replayed or stale HTTP Signatures. Any incoming signed request whose `Date` header is outside a ±30-second window of server time SHALL be rejected. Any incoming signed request whose nonce has been seen within the current time window SHALL be rejected.

#### Scenario: Stale request is rejected
- **WHEN** an incoming signed request carries a `Date` header more than 30 seconds in the past or future relative to server time
- **THEN** the system returns HTTP 400 and drops the request without processing

#### Scenario: Replayed nonce is rejected
- **WHEN** an incoming signed request carries a nonce value that has been received within the past 60 seconds
- **THEN** the system returns HTTP 400 and drops the request
- **THEN** the replay rejection event is logged and visible in the federation inspector (dev)

#### Scenario: Fresh unique request is accepted
- **WHEN** an incoming signed request has a `Date` within the ±30-second window and a previously unseen nonce
- **THEN** the nonce is recorded and the request proceeds to signature verification

---

### Requirement: Inbox endpoint
The system SHALL serve an ActivityPub inbox endpoint that receives and processes incoming activities from remote nodes.

#### Scenario: Inbox accepts a valid signed POST
- **WHEN** a remote node POSTs a signed, valid ActivityPub activity to the local inbox URL
- **THEN** the system verifies the signature, validates and sanitizes the payload, and stores the activity in the local inbox database table
- **THEN** the system returns HTTP 202 Accepted

#### Scenario: Inbox rejects oversized payloads
- **WHEN** an incoming POST body exceeds the configured size limit (default: 64 KB)
- **THEN** the system returns HTTP 413 and drops the payload without processing

#### Scenario: Inbox ignores unknown activity types
- **WHEN** an incoming activity has an unrecognized `type` value
- **THEN** the system returns HTTP 202 (to avoid leaking information about what is or is not supported) and silently drops the activity

---

### Requirement: Outbox endpoint
The system SHALL serve an ActivityPub outbox endpoint that exposes the local user's published activity history as a paginated `OrderedCollection`.

#### Scenario: Outbox serves the activity collection
- **WHEN** a remote node or client fetches the outbox URL with `Accept: application/activity+json`
- **THEN** the response is an `OrderedCollection` with a `totalItems` count and a `first` page link
- **THEN** the response is served over HTTPS with `Content-Type: application/activity+json`

#### Scenario: Outbox page is paginated
- **WHEN** a request is made for an outbox page URL
- **THEN** the response is an `OrderedCollectionPage` with up to 20 items, and `next`/`prev` links where applicable

---

### Requirement: Followers and Following collections
The system SHALL serve ActivityPub `followers` and `following` collection endpoints reflecting the local user's social graph.

#### Scenario: Followers collection is served
- **WHEN** a remote node fetches the local followers collection URL
- **THEN** the response is a valid `OrderedCollection` with a `totalItems` count

#### Scenario: Following collection is served
- **WHEN** a remote node fetches the local following collection URL
- **THEN** the response is a valid `OrderedCollection` with a `totalItems` count

---

### Requirement: Actor fetch and resolution
The system SHALL be able to resolve any ActivityPub actor handle (`@user@domain`) or actor URL to a remote Actor object, with results cached locally.

#### Scenario: Actor is resolved from a handle
- **WHEN** the app needs to look up a remote actor by handle (e.g., to deliver an activity)
- **THEN** the system performs a WebFinger lookup on the handle's domain, retrieves the actor URL from the `rel: self` link, fetches the Actor JSON, and caches the result

#### Scenario: Actor resolution cache is used on repeat lookups
- **WHEN** the app looks up an actor that was resolved within the cache TTL
- **THEN** the cached Actor object is returned without making a new network request

#### Scenario: Actor resolution fails gracefully
- **WHEN** WebFinger or the actor fetch returns a non-2xx response or times out
- **THEN** the resolution fails with a typed error
- **THEN** no unhandled exception propagates to the UI

---

### Requirement: Signed inbox delivery to remote nodes
The system SHALL deliver outgoing ActivityPub activities to remote node inboxes via signed HTTPS POST, with retry on transient failure and relay handoff on sustained failure.

#### Scenario: Direct delivery succeeds
- **WHEN** the app sends a signed POST to a remote inbox and receives HTTP 2xx
- **THEN** the activity is marked delivered in the outgoing queue

#### Scenario: Transient delivery failure is retried
- **WHEN** the remote inbox returns a 5xx response or a network timeout
- **THEN** the delivery is retried with exponential back-off (max 3 attempts before relay handoff)

#### Scenario: Sustained delivery failure triggers relay handoff
- **WHEN** all direct delivery retry attempts are exhausted
- **THEN** the activity is handed to the relay with the destination actor URL for queued delivery
- **THEN** the outgoing queue entry is updated to "relayed" status
