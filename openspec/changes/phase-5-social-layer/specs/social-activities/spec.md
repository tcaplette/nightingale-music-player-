## ADDED Requirements

### Requirement: Now Playing broadcast
The system SHALL allow the local user to opt-in to broadcasting their currently playing track as a `Listen` activity to followers, on a per-session basis.

#### Scenario: User enables Now Playing for the session
- **WHEN** the user enables the Now Playing toggle in the player UI
- **THEN** each subsequent track play emits a signed `Listen` activity to all follower inboxes via the existing federation layer, for the duration of the session

#### Scenario: User disables Now Playing mid-session
- **WHEN** the user disables the Now Playing toggle
- **THEN** no further `Listen` activities are emitted; the current track's activity is not retracted

#### Scenario: Now Playing defaults to off
- **WHEN** the app launches a new session
- **THEN** Now Playing broadcast is disabled by default, regardless of previous session state

#### Scenario: Now Playing activity structure
- **WHEN** a `Listen` activity is emitted
- **THEN** the activity MUST include: actor (local node URL), object (track reference with title, artist, and hosting node), published timestamp — and MUST be signed with the local Ed25519 HTTP Signature

#### Scenario: Delivery failure for Now Playing activity
- **WHEN** a follower node is unreachable at the time of emission
- **THEN** the activity is queued for relay-assisted delivery; the local UI does not block or surface an error — Now Playing delivery is best-effort

---

### Requirement: Save a federated track
The system SHALL allow the user to save a track from another node into their local library or queue.

#### Scenario: User saves a track from the social feed
- **WHEN** the user taps Save on a federated track in the feed
- **THEN** the track metadata is stored in the local library database (same schema as Phase 4 remote tracks) and a confirmation is shown — the audio is not downloaded at save time

#### Scenario: User adds a saved track to the queue
- **WHEN** the user plays a saved remote track
- **THEN** the playback engine resolves the stream source via Phase 4 best-effort streaming, with the same caching and fallback behavior as any other remote track

#### Scenario: Saved track's host goes offline
- **WHEN** a saved track's hosting node is unreachable
- **THEN** the track appears in the library with an offline indicator; cached audio (if any) is available; the UI does not show an error state — it communicates honestly that the host is currently unreachable

---

### Requirement: Share a track or playlist
The system SHALL allow the user to forward a track or playlist to their followers by sending an `Announce` activity.

#### Scenario: User shares a track
- **WHEN** the user taps Share on a track (local or remote)
- **THEN** the system sends a signed `Announce` activity wrapping the track object to all follower inboxes

#### Scenario: User shares a playlist
- **WHEN** the user taps Share on one of their playlists
- **THEN** the system sends a signed `Announce` activity wrapping the playlist `OrderedCollection` URL to all follower inboxes

#### Scenario: Share delivery confirmation
- **WHEN** a Share activity is sent
- **THEN** the activity is recorded in the local activity log with per-recipient delivery state (delivered, queued, relay, failed); the user can inspect this from the debug overlay (dev builds) but the primary UI shows only a confirmation that the share was sent

---

### Requirement: Like a track
The system SHALL allow the user to send a `Like` activity to a track hosted on another node.

#### Scenario: User likes a track
- **WHEN** the user taps Like on a remote track
- **THEN** the system sends a signed `Like` activity to the hosting node's inbox, records the like locally, and updates the Like affordance to a filled/active state

#### Scenario: Like while hosting node is offline
- **WHEN** the user likes a track and the hosting node is unreachable
- **THEN** the `Like` activity is queued for relay-assisted delivery; the local like state is applied immediately so the UI reflects the user's intent

#### Scenario: Unlike a track
- **WHEN** the user taps Like on an already-liked track
- **THEN** the system sends a signed `Undo{Like}` activity and reverts the local like state

---

### Requirement: Publish a playlist as an ActivityPub OrderedCollection
The system SHALL allow the user to publish a local playlist as an ActivityPub `OrderedCollection` served from the local HTTP server, announced to followers via a `Create` activity.

#### Scenario: User publishes a playlist
- **WHEN** the user sets a playlist's visibility to "Public" or "Followers only"
- **THEN** the system creates an `OrderedCollection` object at a stable URL on the local HTTP server, sends a signed `Create{OrderedCollection}` activity to follower inboxes, and records the playlist in the local `playlists` table

#### Scenario: Remote node fetches a published playlist
- **WHEN** a remote actor's node makes an authenticated GET request to the playlist URL
- **THEN** the local HTTP server returns the `OrderedCollection` JSON with track references (metadata only — stream URLs are not embedded)

#### Scenario: Followers-only playlist access
- **WHEN** a request for a followers-only playlist arrives from a node that is NOT in the local followers collection
- **THEN** the local HTTP server returns HTTP 403 and does not serve the playlist content

#### Scenario: User unpublishes a playlist
- **WHEN** the user sets a published playlist's visibility to "Private"
- **THEN** the system sends a signed `Delete{OrderedCollection}` activity to followers and removes the playlist URL from the local HTTP server (subsequent GETs return 404)

---

### Requirement: Incoming Like and Announce activities are processed and stored
The system SHALL process incoming `Like` and `Announce` activities from followed actors and store them as notification events.

#### Scenario: Incoming Like on a locally hosted track
- **WHEN** a signed `Like` activity arrives for a track the local node hosts
- **THEN** the system validates the sender's signature, stores the like event in `notifications` with actor reference and timestamp, and increments the track's like count in the local database

#### Scenario: Incoming Announce from a followed actor
- **WHEN** a signed `Announce` activity arrives from a followed actor
- **THEN** the system stores the activity in the local activity feed database and surfaces it in the social feed as "[Person] shared [track/playlist]"

#### Scenario: Activity from an unknown or unverifiable sender is rejected
- **WHEN** an activity arrives with an invalid HTTP Signature or from an actor that cannot be resolved
- **THEN** the system rejects the activity and logs the rejection — it is not stored or surfaced
