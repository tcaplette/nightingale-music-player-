## 1. Database Schema

- [x] 1.1 Add Drift table `follows` (id, local_actor_id, remote_actor_url, state, created_at, updated_at) with index on remote_actor_url
- [x] 1.2 Add Drift table `follow_requests` (id, direction [incoming/outgoing], actor_url, state [pending/pending_review/accepted/rejected/cancelled/pending_delivery], activity_id, created_at, updated_at)
- [x] 1.3 Add Drift table `blocks` (id, actor_url, created_at) and `mutes` (id, actor_url, created_at)
- [x] 1.4 Add Drift table `activities` (id, type, actor_url, object_json, published_at, raw_json) for feed storage
- [x] 1.5 Add Drift table `notifications` (id, type, from_actor_url, object_ref, read, created_at) with index on read + created_at
- [x] 1.6 Add Drift table `playlists` (id, title, visibility [public/followers/private], collection_url, track_ids_json, created_at, updated_at)
- [x] 1.7 Write and run Drift migration; verify schema with existing Phase 4 migration sequence

## 2. ActivityPub Serialization Extensions

- [x] 2.1 Add serializer/deserializer for `Follow` activity in `lib/core/activitypub/`
- [x] 2.2 Add serializer/deserializer for `Undo{Follow}`, `Accept{Follow}`, `Reject{Follow}`
- [x] 2.3 Add serializer/deserializer for `Block` and `Undo{Block}`
- [x] 2.4 Add serializer/deserializer for `Like` and `Undo{Like}`
- [x] 2.5 Add serializer/deserializer for `Announce` (Share)
- [x] 2.6 Add serializer/deserializer for `Create{OrderedCollection}` and `Delete{OrderedCollection}` (playlist publish/unpublish)
- [x] 2.7 Add `OrderedCollection` object type to serve playlists from the local HTTP server endpoint

## 3. Social Repository

- [x] 3.1 Create `SocialRepository` in `lib/core/repositories/` with interface for follow, unfollow, block, mute, and pending-request management
- [x] 3.2 Implement follow: write to `follow_requests` (outgoing, pending_delivery), dispatch signed `Follow` activity via existing federation layer
- [x] 3.3 Implement unfollow: remove from `follows`, dispatch signed `Undo{Follow}` (best-effort delivery)
- [x] 3.4 Implement incoming follow handling: write to `follow_requests` (incoming), auto-accept for public accounts (dispatch `Accept{Follow}`), queue for manual approval for private accounts
- [x] 3.5 Implement accept/reject for pending incoming follow requests: dispatch `Accept{Follow}` or `Reject{Follow}`, update local state
- [x] 3.6 Implement block: write to `blocks`, dispatch `Block` activity, remove any existing follow in both directions
- [x] 3.7 Implement unblock: remove from `blocks`, dispatch `Undo{Block}`
- [x] 3.8 Implement mute/unmute: write/remove from `mutes` — no outgoing activity
- [x] 3.9 Handle incoming `Accept{Follow}` / `Reject{Follow}` in inbox processor: transition `follow_requests` state accordingly, emit notification for Reject

## 4. Activity Repository

- [x] 4.1 Create `ActivityRepository` in `lib/core/repositories/` with interface for emitting and querying activities
- [x] 4.2 Implement Now Playing emit: build signed `Listen` activity from current track, dispatch to all follower inboxes; session-scoped opt-in flag stored in app state
- [x] 4.3 Implement Like/Unlike: dispatch signed `Like` / `Undo{Like}`, write to local `activities` table
- [x] 4.4 Implement Share (Announce): dispatch signed `Announce` for track or playlist URL to all follower inboxes
- [x] 4.5 Implement playlist publish: create `OrderedCollection` at a stable URL, register with local HTTP server, dispatch `Create{OrderedCollection}`; implement unpublish with `Delete` + 404 handler
- [x] 4.6 Implement Save: write federated track metadata to local library DB (reuse Phase 4 remote track model)
- [x] 4.7 Incoming activity processing: extend inbox processor to handle `Like`, `Announce`, `Listen`, write to `activities` and `notifications` tables; reject activities from blocked actors; suppress notifications from muted actors
- [x] 4.8 Validate and verify incoming activity signatures before storing (reuse existing HTTP Signature verifier)

## 5. Social Graph Feature Module

- [x] 5.1 Create `lib/features/social/` directory structure: `providers/`, `screens/`, `widgets/`
- [x] 5.2 Implement `SocialGraphNotifier` Riverpod provider: exposes following list, followers list, pending requests, blocks, mutes; backed by `SocialRepository`
- [x] 5.3 Build Following screen: person-first list with `PersonTile` component; "Pending" section for unconfirmed outgoing requests; states: "Awaiting approval", "Waiting to deliver"
- [x] 5.4 Build Followers screen: person-first list; pending incoming follow requests section with Accept/Reject actions
- [x] 5.5 Build Blocked/Muted list screen accessible from settings

## 6. Social Feed & Notifications Feature Module

- [x] 6.1 Implement `SocialFeedNotifier` Riverpod provider: queries `activities` table ordered by published_at desc, filters out blocked/muted actors, paginates 50 per page
- [x] 6.2 Build Social Feed screen: chronological list using `ActivityCard` shared component; pull-to-refresh; empty state for zero follows; paginated infinite scroll; offline banner when cached
- [x] 6.3 Implement `NotificationsNotifier` Riverpod provider: queries `notifications` table, groups by type+object when count ≥ 3, surfaces unread count
- [x] 6.4 Build Notifications screen: grouped notification list using `NotificationItem` shared component; badge count on tab icon; mark-all-read action
- [x] 6.5 Implement feed hydration log data collection: record fetch count, filter reasons, render count per feed open (stored in memory, exposed to debug overlay only)

## 7. Profile View Feature Module

- [x] 7.1 Implement `ProfileNotifier` Riverpod provider: fetches and caches actor object on open, exposes relationship state (following/blocked/muted/pending), recent activities, shared playlists
- [x] 7.2 Build Profile screen: avatar, display name, bio, Now Playing section (conditional on recent Listen), Playlists section, recent activity list, Follow/Unfollow/Request button with correct state per spec
- [x] 7.3 Implement "advanced info" affordance on Profile: bottom sheet revealing raw handle, node URL, account created date
- [x] 7.4 Implement overflow menu on Profile: Block, Mute actions with confirmation prompts
- [x] 7.5 Implement stale-cache render with background refresh: show cached actor data immediately, refresh actor object from remote, apply diff without jarring reload; show "Last updated" indicator when node is unreachable

## 8. Shared Components

- [x] 8.1 Build `PersonTile` shared component in `lib/shared/components/`: avatar + display name + secondary label slot; no handle visible; used by Following/Followers/Feed screens
- [x] 8.2 Build `ActivityCard` shared component: [Avatar] [Name] [verb] [track/playlist]; handles Listen, Announce, Save activity types
- [x] 8.3 Build `NotificationItem` shared component: single and grouped variants; [Avatar(s)] [N people] [verb] [object]; tap navigates to relevant profile or track
- [x] 8.4 Build `PlaylistCard` shared component: playlist name, track count, tap-to-browse affordance

## 9. Playlist Detail Screen

- [x] 9.1 Build Playlist Detail screen: ordered track list fetched from `OrderedCollection` URL; each track has a stream affordance (Phase 4 best-effort); honest offline state per track
- [x] 9.2 Add route `/playlists/:id` to go_router; handle both local and remote playlist URLs

## 10. Now Playing Toggle & Player Integration

- [x] 10.1 Add Now Playing broadcast toggle to the player UI (Now Playing screen or mini-player overflow menu); defaults to off per session; persists toggle state in session-scoped provider
- [x] 10.2 Wire toggle to `ActivityRepository.emitNowPlaying()` on each track play event when enabled; ensure no emission when toggle is off

## 11. Router & Navigation

- [x] 11.1 Add route `/profile/:actorId` to go_router pointing to Profile screen
- [x] 11.2 Add route `/feed` for Social Feed screen
- [x] 11.3 Add route `/notifications` for Notifications screen
- [x] 11.4 Add bottom navigation tab or home screen entry points for Feed and Notifications
- [x] 11.5 Wire `PersonTile` and `ActivityCard` taps to navigate to `/profile/:actorId`

## 12. Local HTTP Server — Playlist Endpoint

- [x] 12.1 Register `/users/:id/playlists/:playlistId` endpoint on the existing local HTTP server in `lib/core/http_server/`
- [x] 12.2 Implement access control: public playlists served to any authenticated requester; followers-only playlists verified against local followers collection; return HTTP 403 for unauthorized; return HTTP 404 for deleted/unpublished playlists

## 13. Debug Overlay — Phase 5 Panels

- [x] 13.1 Add Social Graph Inspector tab to the dev overlay: follower count, following count, pending follow requests (in/out), block list, mute list, defederation state (from Phase 3); all wrapped in `kDebugMode` guard
- [x] 13.2 Add Activity Delivery Report tab: per-activity log with recipient node, delivery state (delivered/queued/relay/failed), timestamp, activity type; sourced from existing federation layer delivery status
- [x] 13.3 Add Feed Hydration Log tab: activities fetched, filtered (with reason), and rendered per feed open; data collected by the feed notifier; reset on each feed open

## 14. Tests

- [x] 14.1 Unit test `SocialRepository`: follow state machine transitions (pending → accepted, pending → rejected, pending_delivery → accepted); block removes follow in both directions
- [x] 14.2 Unit test incoming `Follow` handling: auto-accept for public, queue for private, discard for blocked sender
- [x] 14.3 Unit test `ActivityRepository`: Like/Unlike local state toggle; Now Playing session-scoped opt-in; incoming Like/Announce storage; reject on invalid signature
- [x] 14.4 Unit test ActivityPub serialization for all new activity types: round-trip JSON parse and emit
- [x] 14.5 Widget test `PersonTile`: renders display name and avatar; does NOT render raw handle in primary layout
- [x] 14.6 Widget test `ActivityCard`: correct verb per activity type; handles missing avatar gracefully
- [x] 14.7 Widget test Profile screen: shows "Requested" state (not "Following") when follow is pending; shows "Blocked" state when blocked
- [x] 14.8 Widget test Social Feed: empty state when no follows; offline banner when no connectivity; muted actor activities absent from rendered list
- [x] 14.9 Widget test Notifications: grouped entry appears when ≥ 3 same-type notifications exist; badge count correct
