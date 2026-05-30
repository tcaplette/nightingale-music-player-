## ADDED Requirements

### Requirement: Cold-start activation condition
The cold-start bootstrap path SHALL activate when the user follows zero nodes OR when the recommendation engine determines that graph-derived signals are below the minimum density threshold required for meaningful trending or affinity results.

#### Scenario: Cold start activates for new user
- **WHEN** the user has just completed onboarding and follows zero nodes
- **THEN** the Discover screen displays cold-start results rather than an empty state

#### Scenario: Cold start deactivates as graph grows
- **WHEN** the user's follow count and signal density rise above the minimum threshold
- **THEN** the engine transitions seamlessly to the full three-path scoring pipeline without requiring a manual action from the user

---

### Requirement: Genre and library overlap matching
The system SHALL attempt to match the user's local library genre tags against genre metadata from any nodes already known to the app (nodes that have delivered ActivityPub activities to the local inbox, whether followed or not). This path requires no outbound network call.

#### Scenario: Genre overlap produces node suggestions
- **WHEN** the user's library contains tracks tagged "jazz" and "soul" and a known node's cached library metadata includes tracks in those genres
- **THEN** that node surfaces as a suggested follow with genre overlap as the stated reason

#### Scenario: Genre matching works fully offline
- **WHEN** the device has no network connectivity
- **THEN** genre/library overlap matching still runs against locally cached node metadata and produces results

---

### Requirement: Server-light node discovery
The system SHALL query a lightweight well-known discovery endpoint to retrieve a list of active nodes that have opted in to being discoverable. The response is a simple JSON list of node URLs and basic metadata (display name, genre tags, track count). This endpoint is queried only when the cold-start path is active and network is available.

#### Scenario: Discovery endpoint returns candidate nodes
- **WHEN** the cold-start path is active and the device is online
- **THEN** the system fetches the discovery list, filters for nodes not already followed, and surfaces them as suggested follows in the Discover screen

#### Scenario: Discovery endpoint unavailable
- **WHEN** the discovery endpoint returns an error or is unreachable
- **THEN** the cold-start path continues using genre matching and trending relay results; no error is shown to the user for the discovery failure specifically

#### Scenario: Discovery is fully optional
- **WHEN** the user has disabled the discovery endpoint in settings
- **THEN** the system SHALL NOT query the endpoint under any circumstances

---

### Requirement: Opt-in global trending relay
The system SHALL support an opt-in global trending feed sourced from a community-operated relay that aggregates anonymized track popularity signals. This feed is disabled by default and requires explicit user opt-in.

#### Scenario: Global trending feed disabled by default
- **WHEN** the app is first launched
- **THEN** the global trending relay is disabled; the Discover screen does not show global trending content unless the user has opted in

#### Scenario: Opt-in enables global trending feed
- **WHEN** the user enables global trending in settings
- **THEN** the cold-start path includes tracks from the relay feed, attributed with "Trending across the network" provenance (no individual actor is attributed)

#### Scenario: Opt-out clears relay data
- **WHEN** the user disables global trending after having enabled it
- **THEN** any cached relay data is purged from local storage and relay results are excluded from all future scoring passes

---

### Requirement: App feels alive on day one
The cold-start bootstrap SHALL ensure the Discover screen always has content to show on first launch, before the user follows anyone. An empty Discover screen is not an acceptable state after cold-start bootstrap has run.

#### Scenario: Discover screen has content on first launch
- **WHEN** the user opens the Discover screen immediately after completing onboarding with zero follows
- **THEN** the Discover screen shows at least one section of content (genre suggestions, discovery candidates, or trending relay if opted in)

#### Scenario: Suggested follows are presented as people, not handles
- **WHEN** cold-start bootstrap surfaces candidate nodes to follow
- **THEN** each candidate is presented with display name and avatar; the raw `@user@node` handle is not shown in the primary presentation

---

### Requirement: Minimum data sent to discovery endpoint
The discovery endpoint request SHALL contain no user-identifying data. The request is a simple unauthenticated GET to a public list. No taste profile data, no track identifiers, no actor ID is included in the request.

#### Scenario: Discovery request contains no user data
- **WHEN** the cold-start path queries the discovery endpoint
- **THEN** the HTTP request contains no Authorization header, no actor ID, and no library or signal data
