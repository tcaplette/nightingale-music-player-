## ADDED Requirements

### Requirement: Follow any actor
The user SHALL be able to follow any actor on the network by their actor URL or WebFinger handle. Following an actor subscribes the user to that actor's library activity.

#### Scenario: Follow an actor
- **WHEN** the user initiates a follow for an actor
- **THEN** the app sends a `Follow` activity to the target actor's inbox
- **AND** adds the actor to the local following list

#### Scenario: Unfollow an actor
- **WHEN** the user unfollows an actor
- **THEN** the app sends an `Undo(Follow)` activity to the target actor's inbox
- **AND** removes the actor from the local following list

### Requirement: Fetch and cache remote libraries
The app SHALL fetch remote library Collections from followed actors and cache them locally for offline browsing.

#### Scenario: Fetch remote library
- **WHEN** the user views a followed actor's library
- **AND** the actor's node is reachable
- **THEN** the app fetches the Collection and caches it locally

#### Scenario: Browse cached library offline
- **WHEN** the user views a followed actor's library
- **AND** the actor's node is unreachable
- **THEN** the app displays the last cached version of the library

### Requirement: Library cache refresh
The app SHALL periodically refresh cached remote libraries in the background and on user request.

#### Scenario: Manual refresh
- **WHEN** the user pulls to refresh on a remote library view
- **THEN** the app re-fetches the Collection from the hosting node

#### Scenario: Background refresh
- **WHEN** the app is foregrounded
- **THEN** the app refreshes cached libraries for followed actors that have not been updated in the last 24 hours

### Requirement: Remote tracks unified with local tracks
Remote tracks SHALL use the same `TrackModel` schema as local tracks, with additional fields for source node and reachability status.

#### Scenario: Unified track list
- **WHEN** displaying a playlist or queue containing both local and remote tracks
- **THEN** all tracks render identically except for a reachability indicator on remote tracks
