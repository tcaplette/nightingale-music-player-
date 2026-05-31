## ADDED Requirements

### Requirement: Peer exchange triggered on follow
When the user follows any actor, the app SHALL enqueue a background job to fetch that actor's `followers` and `following` ActivityPub collections and resolve and cache all discovered actor objects, up to 200 items per collection.

#### Scenario: Follow triggers peer exchange
- **WHEN** the user follows an actor and the `Follow` activity is sent
- **THEN** the app enqueues a background peer-exchange job for that actor without blocking the follow confirmation

#### Scenario: Peer exchange runs in background
- **WHEN** the peer exchange job runs
- **THEN** it fetches the new contact's `followers` and `following` collection pages (up to 200 items each) and caches each resolved actor object via `NodeDiscoveryService`

#### Scenario: Peer exchange does not block UI
- **WHEN** the peer exchange job is running
- **THEN** the follow action completes and the UI returns to normal state; no loading indicator is shown for the exchange

---

### Requirement: Peer exchange depth is limited to one hop
The peer exchange SHALL fetch only the direct connections of the newly followed actor. It SHALL NOT recursively fetch connections of discovered actors.

#### Scenario: One-hop limit enforced
- **WHEN** a peer exchange job resolves 50 actor objects from the new contact's connections
- **THEN** the app caches those 50 actors but does NOT enqueue follow-on peer exchange jobs for any of them

---

### Requirement: Per-collection fetch cap of 200 actors
Each individual collection fetch (followers or following) during peer exchange SHALL retrieve at most 200 actor objects, stopping pagination after that limit regardless of collection size.

#### Scenario: Large collection is capped
- **WHEN** a peer exchange job fetches a `followers` collection with 5,000 entries
- **THEN** the app fetches the first 200 items and stops, without error

---

### Requirement: Peer exchange rate limiting
Peer exchange jobs SHALL be enqueued at low priority and rate-limited to avoid starving foreground network activity.

#### Scenario: Multiple follows in quick succession
- **WHEN** the user follows five actors in rapid succession
- **THEN** five peer exchange jobs are enqueued; they run sequentially at low priority, not concurrently

#### Scenario: App is foregrounded during exchange
- **WHEN** a peer exchange job is in progress and the user initiates a foreground network action
- **THEN** the peer exchange job yields priority to the foreground action

---

### Requirement: Discovered actors tagged with discovery source
Actor objects cached via peer exchange SHALL be stored with a `discoverySource` value of `peerExchange` so they can be distinguished from actors discovered by other means.

#### Scenario: Peer exchange source tag set
- **WHEN** an actor is added to the cache by a peer exchange job
- **THEN** the `discoverySource` field on the cached actor record is set to `peerExchange`

#### Scenario: Existing actor not overwritten with peer exchange source
- **WHEN** peer exchange resolves an actor that is already cached with a higher-priority source (e.g. `manual` or `mDNS`)
- **THEN** the existing cache entry is updated with any new address information but the `discoverySource` is not downgraded to `peerExchange`

---

### Requirement: Peer exchange failure is silent
If a peer exchange job fails (network error, unreachable node, malformed collection), it SHALL log the failure at debug level and discard the job without surfacing an error to the user.

#### Scenario: Collection endpoint unreachable
- **WHEN** the newly followed actor's node is unreachable when the peer exchange job runs
- **THEN** the job is discarded silently; no error is shown to the user; the follow remains in effect
