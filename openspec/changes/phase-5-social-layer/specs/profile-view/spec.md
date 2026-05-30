## ADDED Requirements

### Requirement: Profile view shows a person, not a handle
The system SHALL display a per-actor profile screen that centers the person — display name, avatar, bio, and activity — and hides the raw `@user@node` handle behind an explicit "advanced info" affordance.

#### Scenario: Viewing a followed actor's profile
- **WHEN** the user navigates to an actor's profile
- **THEN** the screen shows: avatar (large), display name, bio (if set), Now Playing (if broadcasting), library count, recent shared playlists, and recent activity — no raw handle is visible in the primary layout

#### Scenario: Accessing the raw handle
- **WHEN** the user taps the "advanced info" affordance on a profile
- **THEN** a bottom sheet or secondary section reveals the raw `@user@node` handle, the node URL, and the account creation date — these are never shown at the top level

#### Scenario: Profile of an actor not yet followed
- **WHEN** the user views the profile of an actor they do not follow
- **THEN** the primary action is a Follow button; if the account is private, the button reads "Request to Follow"

#### Scenario: Profile of an actor the local user is already following
- **WHEN** the user views a profile they follow
- **THEN** the Follow button state is "Following" with an unfollow affordance (e.g., long-press or secondary button)

#### Scenario: Profile of a private account with a pending follow request
- **WHEN** the user has sent a Follow request that has not been accepted
- **THEN** the button reads "Requested" — not "Following" — and a secondary label clarifies "Awaiting approval"

---

### Requirement: Profile shows Now Playing when the actor is broadcasting
The system SHALL show the actor's currently playing track on their profile if they have an active Now Playing broadcast.

#### Scenario: Actor is broadcasting Now Playing
- **WHEN** the profile screen is opened and a recent `Listen` activity (within the last 10 minutes) exists for the actor
- **THEN** a "Now Playing" section appears below the bio showing track title, artist, and a stream affordance (streams best-effort via Phase 4)

#### Scenario: Actor is not broadcasting
- **WHEN** no recent `Listen` activity exists
- **THEN** the Now Playing section is not shown — no "not listening" placeholder

---

### Requirement: Profile shows the actor's shared playlists
The system SHALL surface playlists the actor has published as ActivityPub OrderedCollections on their profile.

#### Scenario: Viewing shared playlists on a profile
- **WHEN** the actor has published one or more playlists
- **THEN** a Playlists section shows each playlist as a card: name, track count, and a tap-to-browse affordance

#### Scenario: Actor has no shared playlists
- **WHEN** the actor has no published playlists
- **THEN** the Playlists section is not shown — no empty state placeholder

#### Scenario: Browsing a playlist from a profile
- **WHEN** the user taps a playlist card on a profile
- **THEN** they navigate to the playlist detail screen showing the ordered track list — each track has a stream affordance with honest best-effort state

---

### Requirement: Profile shows recent activity
The system SHALL show the actor's recent social activity (listens, shares) on their profile as a scrollable activity list.

#### Scenario: Recent activity section
- **WHEN** recent activities from the actor exist in the local store
- **THEN** up to 10 recent activities are shown in person-action-track format below the playlists section, newest first

#### Scenario: No recent activity
- **WHEN** no activities from the actor are in the local store
- **THEN** the activity section is not shown

---

### Requirement: Profile reflects local relationship state (block, mute)
The system SHALL show block and mute controls on a profile and reflect the current relationship state accurately.

#### Scenario: User views a profile they have blocked
- **WHEN** the actor is in the local `blocks` table
- **THEN** the profile shows a "Blocked" indicator in place of the Follow button and an Unblock affordance

#### Scenario: User views a profile they have muted
- **WHEN** the actor is in the local `mutes` table
- **THEN** the profile shows a "Muted" secondary indicator alongside the normal Follow state and an Unmute affordance

#### Scenario: Block / mute actions from the profile
- **WHEN** the user opens the profile action menu (e.g., three-dot / overflow)
- **THEN** the menu contains Block and Mute options; tapping either triggers the social graph requirement for that action (confirmation prompt, activity emission, local state update)

---

### Requirement: Profile data is refreshed on open
The system SHALL re-fetch the actor's ActivityPub Actor object and recent activities when the profile screen is opened, using cached data as the immediate render while the fetch completes.

#### Scenario: Profile opens with stale cached data
- **WHEN** the user opens a profile and cached actor data exists
- **THEN** the cached data renders immediately; a background fetch updates display name, avatar, and bio if they have changed — the update is applied without a jarring reload

#### Scenario: Profile opens and remote node is unreachable
- **WHEN** the actor's node is unreachable at open time
- **THEN** the profile renders from cache with a non-intrusive "Last updated [relative time]" indicator — it does not show an error screen
