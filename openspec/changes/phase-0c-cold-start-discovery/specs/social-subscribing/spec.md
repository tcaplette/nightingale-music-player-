## MODIFIED Requirements

### Requirement: Follow any actor
The user SHALL be able to follow any actor on the network by their actor URL or WebFinger handle. Following an actor subscribes the user to that actor's library activity and triggers a background peer exchange to expand the local actor cache with the new contact's social connections.

#### Scenario: Follow an actor
- **WHEN** the user initiates a follow for an actor
- **THEN** the app sends a `Follow` activity to the target actor's inbox
- **AND** adds the actor to the local following list
- **AND** enqueues a background peer exchange job for the followed actor

#### Scenario: Unfollow an actor
- **WHEN** the user unfollows an actor
- **THEN** the app sends an `Undo(Follow)` activity to the target actor's inbox
- **AND** removes the actor from the local following list
