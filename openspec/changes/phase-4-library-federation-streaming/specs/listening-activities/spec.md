## ADDED Requirements

### Requirement: Publish Listen activities
The app SHALL publish `Listen` activities to the user's outbox when tracks are played. These activities SHALL include the track reference, timestamp, and duration listened.

#### Scenario: Track starts playing
- **WHEN** the user starts playing a track
- **THEN** the app queues a `Listen` activity for delivery to followers

#### Scenario: Listen activity content
- **WHEN** a `Listen` activity is published
- **THEN** it contains the track's federated identifier, start time, and the actor's identity

### Requirement: Ingest Listen activities
The app SHALL receive and store `Listen` activities from followed actors in the local database as recommendation signals.

#### Scenario: Receive Listen activity
- **WHEN** a `Listen` activity arrives in the inbox from a followed actor
- **THEN** the app stores it in the local signal database

#### Scenario: Ignore Listen from non-follower
- **WHEN** a `Listen` activity arrives from an actor the user does not follow
- **THEN** the app drops the activity without storing it

### Requirement: Opt-in broadcast
Publishing `Listen` activities SHALL be opt-in per session. The user SHALL be able to disable broadcasting at any time.

#### Scenario: Disable broadcast
- **WHEN** the user turns off "Share listening activity"
- **THEN** no `Listen` activities are published for the remainder of the session

#### Scenario: Enable broadcast
- **WHEN** the user turns on "Share listening activity"
- **THEN** `Listen` activities are published for subsequent track plays
