## ADDED Requirements

### Requirement: Library metadata published as ActivityPub Collection
The node SHALL expose its shared library metadata as an ActivityPub `OrderedCollection` at a well-known endpoint. The collection SHALL contain `Audio` objects representing tracks, grouped into pages by album.

#### Scenario: Fetching a public library
- **WHEN** any actor requests `GET /users/<username>/library`
- **THEN** the node responds with an `OrderedCollection` containing `Audio` objects for all tracks the user has chosen to share publicly

#### Scenario: Fetching a followers-only library
- **WHEN** a non-follower requests `GET /users/<username>/library`
- **AND** the user's sharing setting is "followers-only"
- **THEN** the node responds with HTTP 403 Forbidden

#### Scenario: Private library
- **WHEN** any actor requests `GET /users/<username>/library`
- **AND** the user's sharing setting is "private"
- **THEN** the node responds with HTTP 403 Forbidden

### Requirement: User controls sharing scope
The app SHALL provide UI for the user to select what is shared: full library, selected playlists, or nothing. The sharing setting SHALL default to "private" (opt-in).

#### Scenario: User enables full library sharing
- **WHEN** the user sets sharing to "full library"
- **THEN** all tracks in the local library are included in the published Collection

#### Scenario: User disables sharing
- **WHEN** the user sets sharing to "private"
- **THEN** the library endpoint returns 403 for all requests

### Requirement: Collection includes track metadata only
The published Collection SHALL include track titles, artists, album names, durations, and artwork URLs. It SHALL NOT include file paths or local storage details.

#### Scenario: Audio object structure
- **WHEN** a track is included in the published Collection
- **THEN** the `Audio` object contains `name`, `artist`, `album`, `duration`, and `url` (pointing to the authenticated stream endpoint)
- **AND** the `Audio` object does NOT contain `filePath` or local identifiers

### Requirement: Privacy enforced per-request
The node SHALL evaluate the requesting actor's relationship (public / follower / self) on every library Collection request and filter the response accordingly.

#### Scenario: Follower accessing followers-only library
- **WHEN** a verified follower requests the library
- **AND** the sharing setting is "followers-only"
- **THEN** the node responds with the full Collection

#### Scenario: Self-access always allowed
- **WHEN** the node owner requests their own library
- **THEN** the node responds with the full Collection regardless of sharing setting
