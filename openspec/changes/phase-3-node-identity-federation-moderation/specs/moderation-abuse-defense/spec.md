## ADDED Requirements

### Requirement: Node-level defederation
The system SHALL allow the user to block an entire remote node, causing all incoming activities from any actor on that node to be rejected and all outgoing deliveries to that node to be suppressed. Defederation operates at the node (domain) level, not the individual actor level.

#### Scenario: Defederated node's inbox posts are rejected
- **WHEN** an incoming inbox POST originates from an actor whose domain is in the defederation list
- **THEN** the system returns HTTP 403 and drops the activity without processing or logging the payload content

#### Scenario: Outgoing delivery to a defederated node is suppressed
- **WHEN** the app would deliver an activity to an actor on a defederated domain
- **THEN** the delivery is cancelled before any network request is made
- **THEN** the suppression is recorded in the federation inspector log

#### Scenario: User adds a node to the defederation list
- **WHEN** the user blocks a node via the moderation settings interface
- **THEN** the node's domain is written to the Drift defederation table
- **THEN** the block takes effect immediately for all subsequent incoming and outgoing requests

#### Scenario: User removes a node from the defederation list
- **WHEN** the user removes a block on a node via the moderation settings interface
- **THEN** the node's domain is deleted from the Drift defederation table
- **THEN** deliveries to and from that node resume normally

---

### Requirement: Rate limiting on inbox delivery
The system SHALL enforce per-source-node rate limits on incoming inbox delivery to protect against flooding and spam from hostile or runaway nodes. The default limit SHALL be 60 activities per minute per source node.

#### Scenario: Source node within rate limit is processed normally
- **WHEN** a source node has delivered fewer than 60 activities in the current 60-second window
- **THEN** the incoming activity is processed normally

#### Scenario: Source node exceeding the rate limit receives HTTP 429
- **WHEN** a source node exceeds 60 inbox deliveries in a 60-second sliding window
- **THEN** the system returns HTTP 429 with a `Retry-After: 60` header
- **THEN** the excess activity is dropped without being stored
- **THEN** the rate limit event is recorded in the federation inspector (dev overlay)

#### Scenario: Defederated node check precedes rate limit check
- **WHEN** an incoming request comes from a defederated node
- **THEN** the request is rejected with HTTP 403 before any rate limit counter is consulted or incremented

#### Scenario: Rate limit state resets after window expiry
- **WHEN** 60 seconds have elapsed since the first counted activity from a source node
- **THEN** the sliding window counter for that node resets to zero

---

### Requirement: Allow/deny list scaffolding
The system SHALL provide persistent allow and deny list storage for nodes, ready for user-level and future community-level policy. In Phase 3 the lists are configurable by the local user but not yet automatically populated from any network source.

#### Scenario: Allow list entry permits a node
- **WHEN** a domain is on the allow list and the system operates in allow-list mode
- **THEN** activities from that domain are accepted regardless of other heuristics

#### Scenario: Deny list entry rejects a node
- **WHEN** a domain is on the deny list
- **THEN** activities from that domain are rejected at the same point as defederation (HTTP 403)

#### Scenario: Lists are persisted across restarts
- **WHEN** the app is restarted after allow or deny list entries have been added
- **THEN** all entries are present and enforced on the first incoming request after restart

---

### Requirement: Activity validation and sanitization on ingestion
The system SHALL validate and sanitize every incoming ActivityPub payload before any part of it is stored or processed. Malformed, oversized, or schema-invalid payloads SHALL be silently dropped in production and logged in development. The system SHALL never pass unsanitized content from an incoming payload to any storage layer or UI.

#### Scenario: Payload with invalid JSON is dropped
- **WHEN** an incoming inbox POST body is not valid JSON
- **THEN** the system returns HTTP 400 and discards the payload
- **THEN** in development builds, the parse error is logged to the federation inspector

#### Scenario: Payload with unrecognized activity type is dropped silently
- **WHEN** an incoming payload has a `type` field that is not a recognized ActivityPub activity type
- **THEN** the system returns HTTP 202 (to avoid leaking capability information) and discards the payload

#### Scenario: HTML content in string fields is stripped
- **WHEN** an incoming payload contains HTML markup in a string field (e.g., `name`, `content`, `summary`)
- **THEN** the HTML is stripped before the value is stored — only plain text is retained

#### Scenario: Non-HTTPS URLs in payload are rejected
- **WHEN** an incoming payload contains a URL field (e.g., `url`, `icon`, `image`) that uses a non-HTTPS scheme
- **THEN** that URL field is nulled out before storage; the rest of the payload proceeds through validation

#### Scenario: Oversized payload is rejected before parsing
- **WHEN** an incoming POST body exceeds 64 KB
- **THEN** the system returns HTTP 413 without reading or parsing the body
