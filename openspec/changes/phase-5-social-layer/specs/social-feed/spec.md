## ADDED Requirements

### Requirement: Chronological social feed
The system SHALL display a chronological feed of activities from followed actors, ordered newest-first, presented in person-first format.

#### Scenario: Feed shows followed actors' listens
- **WHEN** the user opens the social feed
- **THEN** each `Listen` activity from a followed actor is shown as: [Avatar] [Display Name] is listening to [Track Title] · [Artist] with a relative timestamp — the raw handle is not visible

#### Scenario: Feed shows shares and new additions
- **WHEN** an `Announce` or library addition activity is in the feed
- **THEN** it is rendered as: [Avatar] [Display Name] shared / added [Track Title] · [Artist] — action verb matches the activity type

#### Scenario: Feed is empty with no follows
- **WHEN** the user has no follows
- **THEN** the feed shows a purposeful empty state ("Follow people to see what they're listening to") with a prompt to discover actors — it does not show an error

#### Scenario: Feed updates on pull-to-refresh
- **WHEN** the user pulls to refresh the feed
- **THEN** the system re-queries the local activity store (populated by the inbox processor) and renders any new activities at the top of the list

#### Scenario: Feed renders offline
- **WHEN** the device has no network connectivity
- **THEN** the feed shows activities already in the local store; a non-intrusive banner indicates the feed is showing cached content

#### Scenario: Feed activities are paginated
- **WHEN** the user scrolls to the bottom of the visible feed
- **THEN** the system loads the next page of activities from the local store (50 per page) without a full reload

---

### Requirement: Muted and blocked actors are excluded from the feed
The system SHALL exclude activities from muted and blocked actors from the social feed without any indication that activities were filtered.

#### Scenario: Activity from a muted actor
- **WHEN** an activity from a muted actor is in the local store
- **THEN** it does not appear in the feed; no gap or placeholder is shown

#### Scenario: Activity from a blocked actor
- **WHEN** an activity from a blocked actor somehow exists in the local store
- **THEN** it does not appear in the feed

---

### Requirement: Notification inbox
The system SHALL maintain a notification inbox that surfaces events directed at the local user: new followers, likes received, and shares of local content.

#### Scenario: New follower notification
- **WHEN** a remote actor successfully follows the local user
- **THEN** the notification inbox gains an entry: [Avatar] [Display Name] started following you · [timestamp]

#### Scenario: Incoming Like notification
- **WHEN** a `Like` activity is received for a locally hosted track
- **THEN** the notification inbox gains an entry: [Avatar] [Display Name] liked [Track Title] · [timestamp]

#### Scenario: Incoming Share (Announce) notification
- **WHEN** an `Announce` activity is received that references a locally hosted track or playlist
- **THEN** the notification inbox gains an entry: [Avatar] [Display Name] shared [Track Title / Playlist Name] · [timestamp]

#### Scenario: Notifications grouped by type when multiple arrive
- **WHEN** 3 or more unread notifications of the same type exist (e.g., 3 new likes on the same track)
- **THEN** they are collapsed into a single grouped entry: [3 people] liked [Track Title] — tapping expands to individual entries

#### Scenario: Notification badge on tab
- **WHEN** unread notifications exist in the inbox
- **THEN** a numeric badge (capped at 99+) is shown on the notifications tab icon

#### Scenario: Notifications from blocked or muted actors are suppressed
- **WHEN** an activity from a blocked or muted actor would generate a notification
- **THEN** no notification entry is created

---

### Requirement: Feed hydration log in debug overlay
The system SHALL expose a Feed Hydration Log tab in the dev overlay (compile-time gated) that shows which activities were fetched, filtered, and rendered.

#### Scenario: Viewing the feed hydration log
- **WHEN** a developer opens the Feed Hydration Log tab in the debug overlay
- **THEN** the panel shows a timestamped list of: activities fetched from the local store, activities filtered (with reason: muted/blocked/invalid), and activities rendered — each entry includes source actor node URL and activity type

#### Scenario: Log is reset on each feed open
- **WHEN** the social feed screen is opened or refreshed
- **THEN** the hydration log for that session is cleared and repopulated with the new fetch/filter/render cycle
