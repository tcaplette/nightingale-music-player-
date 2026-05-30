## ADDED Requirements

### Requirement: First-launch identity generation
On the very first launch of the app, the system SHALL generate a federated identity automatically, without requiring the user to choose a username, server, or interact with any ActivityPub concept. The identity SHALL consist of an Ed25519 key pair and a fully specified ActivityPub Actor object. The raw `@user@node` handle SHALL exist in protocol data but SHALL NOT be presented as the primary identity in any UI context.

#### Scenario: App generates identity on first launch
- **WHEN** the user launches the app for the first time and no identity record exists
- **THEN** the app generates an Ed25519 key pair using the platform cryptographic API
- **THEN** the private key is stored in the iOS Keychain or Android Keystore (secure enclave) and is never accessible to app code
- **THEN** an ActivityPub Actor JSON-LD object is created and persisted with the fields: `id`, `type` (Person), `inbox`, `outbox`, `followers`, `following`, `preferredUsername`, `name`, `publicKey` (containing the Ed25519 public key in PEM format)
- **THEN** the user is presented with a name/avatar setup screen — never a "choose your handle" prompt

#### Scenario: Identity is not regenerated on subsequent launches
- **WHEN** the app launches and an identity record already exists
- **THEN** the existing identity is loaded and no new key pair is generated

#### Scenario: Raw handle is not surfaced in primary UI
- **WHEN** a user views their own profile in any standard app context
- **THEN** their name and avatar are displayed as the primary presentation
- **THEN** the raw `@user@node` handle is accessible only in a settings or advanced detail context

---

### Requirement: Ed25519 key pair generation and secure storage
The system SHALL generate Ed25519 key pairs using the platform's cryptographic key generation API. The private key SHALL be stored exclusively in the device secure enclave (iOS Keychain / Android Keystore) and SHALL never be written to app storage, the Drift database, log output, or any network payload.

#### Scenario: Private key never leaves the secure enclave
- **WHEN** an HTTP Signature is produced for an outgoing request
- **THEN** the signing operation is performed by passing the message to the platform key API
- **THEN** only the resulting signature bytes are returned to app code — no key material is exposed

#### Scenario: App storage contains no private key material
- **WHEN** the Drift database and all app-accessible file storage are inspected
- **THEN** no Ed25519 private key bytes or PEM representation are present

#### Scenario: Key loss on app uninstall
- **WHEN** the app is uninstalled without a prior migration token export
- **THEN** the private key is destroyed with the secure enclave entry
- **THEN** the account identity cannot be recovered from that key (social graph recovery requires a previously exported migration token)

---

### Requirement: ActivityPub Actor object
The system SHALL generate and serve a conformant ActivityPub Actor object for each node identity. The Actor SHALL include all fields required by the ActivityPub specification and by Mastodon-compatible fediverse implementations for actor discovery and federation.

#### Scenario: Actor object contains required fields
- **WHEN** a remote node or client fetches the actor URL with `Accept: application/activity+json`
- **THEN** the response body is a valid ActivityPub Person Actor containing: `@context`, `id` (canonical URL), `type` ("Person"), `inbox`, `outbox`, `followers`, `following`, `preferredUsername`, `name`, `publicKey` (with `id`, `owner`, `publicKeyPem` fields)
- **THEN** the response `Content-Type` is `application/activity+json`

#### Scenario: Actor URL is stable across app restarts
- **WHEN** the app restarts after identity generation
- **THEN** the actor URL served is identical to the URL generated on first launch

---

### Requirement: WebFinger endpoint
The system SHALL serve a WebFinger endpoint at `/.well-known/webfinger` so that any node on the fediverse can discover the local actor from an `acct:` resource URI.

#### Scenario: WebFinger resolves the local actor
- **WHEN** a remote node sends `GET /.well-known/webfinger?resource=acct:<username>@<node-domain>`
- **THEN** the response is HTTP 200 with `Content-Type: application/jrd+json`
- **THEN** the body is a valid WebFinger JRD containing a `links` array with a `rel: "self"` entry pointing to the actor URL

#### Scenario: WebFinger rejects unknown resources
- **WHEN** a request arrives for a resource that does not match the local user
- **THEN** the response is HTTP 404

#### Scenario: WebFinger is served over HTTPS only
- **WHEN** a WebFinger request arrives over plaintext HTTP
- **THEN** the server returns HTTP 301 redirecting to the HTTPS equivalent, or refuses the connection

---

### Requirement: Account portability via Move activity
The system SHALL implement an account migration mechanism modeled on the ActivityPub `Move` activity and Mastodon's account migration protocol. A user SHALL be able to carry their identity (followers and following graph) to a new device installation without exposing private key material to themselves or any third party.

#### Scenario: Migration token export from old device
- **WHEN** the user initiates "Export migration token" in settings on the old device
- **THEN** the system generates a signed migration token containing the actor URL and a timestamp, signed with the current private key
- **THEN** the token is presented as a human-copyable string (QR code and text) that the user can transfer to their new device
- **THEN** no private key material is included in or derivable from the token

#### Scenario: Identity migration to new device
- **WHEN** the user provides a valid migration token on a new device that already has a fresh identity generated
- **THEN** the new device broadcasts an ActivityPub `Move` activity (`actor: old-actor-URL, object: new-actor-URL`) signed with the old key (authorization validated via the migration token)
- **THEN** the followers collection from the old actor is fetched and each follower is notified of the move
- **THEN** the old actor URL begins serving a tombstone or redirect response

#### Scenario: Migration token is single-use and time-bounded
- **WHEN** a migration token older than 72 hours is presented
- **THEN** the system rejects it and prompts the user to generate a new one
- **WHEN** a migration token has already been used to complete a Move
- **THEN** it is invalidated and a second use is rejected
