## ADDED Requirements

### Requirement: Follow an actor
The system SHALL allow the local user to follow any resolvable actor on the network by sending a signed `Follow` activity to the remote actor's inbox via the existing ActivityPub federation layer.

#### Scenario: Follow a public account
- **WHEN** the user taps Follow on a profile that has `manuallyApprovesFollowers: false`
- **THEN** the system sends a signed `Follow` activity to the remote actor's inbox, records the relationship in the local `follows` table with state `accepted`, and updates the following list UI immediately

#### Scenario: Follow a private account
- **WHEN** the user taps Follow on a profile that has `manuallyApprovesFollowers: true`
- **THEN** the system sends a signed `Follow` activity to the remote actor's inbox, records the relationship in `follow_requests` with state `pending`, and displays a "Request sent" indicator on the profile — not "Following"

#### Scenario: Follow while remote node is offline
- **WHEN** the user taps Follow and the remote node is unreachable
- **THEN** the system queues the `Follow` activity for relay-assisted delivery, records the relationship locally with state `pending_delivery`, and surfaces an honest "Waiting to deliver" indicator — not "Following"

#### Scenario: Remote node accepts follow request
- **WHEN** an `Accept{Follow}` activity arrives in the local inbox
- **THEN** the system transitions the follow request state from `pending` to `accepted` and updates the UI

#### Scenario: Remote node rejects follow request
- **WHEN** a `Reject{Follow}` activity arrives in the local inbox
- **THEN** the system transitions the follow request state from `pending` to `rejected`, removes the entry from the pending list, and surfaces a dismissible notification

---

### Requirement: Unfollow an actor
The system SHALL allow the local user to unfollow any currently followed actor by sending a signed `Undo{Follow}` activity and removing the local relationship record.

#### Scenario: Successful unfollow
- **WHEN** the user confirms unfollow on a profile they follow
- **THEN** the system sends a signed `Undo{Follow}` activity, removes the row from `follows`, and updates the following list and profile screen immediately

#### Scenario: Unfollow while remote node is offline
- **WHEN** the user unfollows and the remote node is unreachable
- **THEN** the local relationship is removed immediately (the user's local state is authoritative) and the `Undo{Follow}` is queued for eventual delivery

---

### Requirement: Incoming follow handling
The system SHALL process incoming `Follow` activities from remote actors and apply the local user's account privacy setting to determine acceptance or queuing.

#### Scenario: Public account receives a follow
- **WHEN** a signed `Follow` activity arrives in the local inbox from a non-blocked actor
- **THEN** the system records the follower in the local `followers` table, sends a signed `Accept{Follow}` back to the sender's inbox, and surfaces the new follower in the notification inbox

#### Scenario: Private account receives a follow
- **WHEN** a signed `Follow` activity arrives and `manuallyApprovesFollowers` is `true`
- **THEN** the system holds the follow in `follow_requests` with state `pending_review` and sends no `Accept` until the user manually approves

#### Scenario: User approves a pending follow request
- **WHEN** the user taps Accept on a pending follow request
- **THEN** the system moves the actor to `followers`, sends a signed `Accept{Follow}` activity, and removes the item from the pending requests list

#### Scenario: User rejects a pending follow request
- **WHEN** the user taps Reject on a pending follow request
- **THEN** the system sends a signed `Reject{Follow}` activity and removes the item from the pending requests list without adding the actor to followers

#### Scenario: Follow from a blocked actor is silently dropped
- **WHEN** a `Follow` activity arrives from an actor on the local block list
- **THEN** the system discards the activity without sending Accept or Reject and without surfacing a notification

---

### Requirement: Block an actor
The system SHALL allow the local user to block any actor, stopping all incoming activity from that actor and propagating the block to the network.

#### Scenario: User blocks an actor
- **WHEN** the user confirms block on a profile
- **THEN** the system records the actor in `blocks`, sends a signed `Block` activity to the actor's inbox, removes any existing follow relationship in both directions (sends `Undo{Follow}` for local follows), and stops processing any future inbox activities from that actor

#### Scenario: Block from debug or settings context
- **WHEN** a block is triggered from any entry point (profile, long-press, settings)
- **THEN** the same `Block` activity and local state update occur — entry point is irrelevant to the outcome

#### Scenario: Blocked actor attempts to follow
- **WHEN** a `Follow` activity arrives from a blocked actor
- **THEN** the system discards it without any response

---

### Requirement: Unblock an actor
The system SHALL allow the local user to unblock a previously blocked actor, resuming normal activity processing.

#### Scenario: User unblocks an actor
- **WHEN** the user confirms unblock from the blocked list
- **THEN** the system removes the actor from `blocks`, sends a signed `Undo{Block}` activity, and resumes processing incoming activities from that actor

---

### Requirement: Mute an actor
The system SHALL allow the local user to mute an actor, suppressing their content from the feed and notifications without notifying the remote actor.

#### Scenario: User mutes an actor
- **WHEN** the user mutes an actor from any entry point
- **THEN** the system records the actor in `mutes`, hides their activities from the social feed and notifications, and does NOT send any activity to the remote node

#### Scenario: Muted actor's activities arrive
- **WHEN** an activity from a muted actor is delivered to the local inbox
- **THEN** the system stores the activity (for potential unmute recovery) but does not surface it in the feed or notifications

#### Scenario: User unmutes an actor
- **WHEN** the user unmutes from the muted list
- **THEN** the system removes the actor from `mutes` and their activities resume appearing in the feed from the next refresh onward

---

### Requirement: Followers and following lists are person-first
The system SHALL display followers and following as a list of people (avatar + display name) and SHALL NOT show raw `@user@node` handles as the primary identifier.

#### Scenario: Viewing the following list
- **WHEN** the user opens the Following screen
- **THEN** each entry shows avatar, display name, and follow state — the raw handle is not displayed unless the user taps an "info" affordance on the individual entry

#### Scenario: Pending follow requests in following list
- **WHEN** the following list contains entries with state `pending` or `pending_delivery`
- **THEN** those entries are grouped under a "Pending" section with honest state labels ("Awaiting approval", "Waiting to deliver")
