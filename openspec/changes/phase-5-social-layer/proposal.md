## Why

Phases 1–4 established the federated infrastructure — identity, ActivityPub transport, library publishing, and best-effort audio streaming — but users cannot yet interact with each other. Phase 5 activates the social graph and activity layer that transforms Nightingale from a personal player with remote libraries into a living, people-first network where music discovery emerges from real relationships.

## What Changes

- **Follow / unfollow actors** — send and receive `Follow` / `Undo` activities over the existing ActivityPub + HTTP Signatures stack; maintain a local followers / following collection
- **Follow requests** — private accounts gate follows behind `Accept` / `Reject`; pending state is surfaced honestly in the UI
- **User-level block and mute** — `Block` / `Undo` activities enforced locally and propagated; builds on the node-level defederation from Phase 3
- **Now Playing broadcast** — opt-in per-session toggle that publishes the current track as a `Listen` activity to followers
- **Save** — store a federated track into the local queue or library
- **Share (Announce)** — forward a track or playlist to followers as an `Announce` activity
- **Like** — send a `Like` activity to a track hosted on another node
- **Playlist share** — publish a playlist as an ActivityPub `OrderedCollection`
- **Social feed** — chronological stream of followed people's listens, shares, and additions; person-first presentation (face, name, action, track)
- **Notification inbox** — new followers, likes, and shares directed at the local user; grouped by type, person-first
- **Profile view** — bio, now playing, library count, recent activity, shared playlists; raw `@user@node` handle hidden behind an "advanced info" tap
- **Phase 5 debug panels** — social graph inspector, activity delivery report, and feed hydration log; compile-time gated, dev overlay only

## Capabilities

### New Capabilities

- `social-graph`: Follow, unfollow, block, and mute actors; manage followers and following collections; handle follow requests for private accounts
- `social-activities`: Emit and receive Like, Announce (Share), Listen (Now Playing), and Save activities; publish playlists as ActivityPub OrderedCollections
- `social-feed`: Chronological feed of followed people's activity; notification inbox for events directed at the local user
- `profile-view`: Per-actor profile screen showing bio, now playing, library, recent activity, and shared playlists; humans-not-handles presentation

### Modified Capabilities

<!-- No existing spec-level capabilities change; all social behaviour is net-new on top of the existing ActivityPub transport and library federation infrastructure -->

## Impact

- **`lib/features/social/`** — new feature module (social graph, activities, feed, profile screens and providers)
- **`lib/core/repositories/`** — new `SocialRepository` and `ActivityRepository` following existing repository pattern
- **`lib/core/activitypub/`** — extend activity serialization / deserialization for Like, Announce, Block, Accept, Reject, OrderedCollection (playlist)
- **`lib/core/database/`** — new Drift tables: `follows`, `blocks`, `mutes`, `activities`, `notifications`, `playlists`
- **`lib/shared/components/`** — new shared components: `PersonTile`, `ActivityCard`, `NotificationItem`, `PlaylistCard`
- **`lib/core/debug/`** — three new dev-overlay tabs: social graph inspector, activity delivery report, feed hydration log
- **`lib/core/router/`** — new routes: `/profile/:actorId`, `/feed`, `/notifications`, `/playlists/:id`
- **No new dependencies expected** — existing `just_audio`, Riverpod, Drift, go_router, and HTTP Signatures infrastructure covers all requirements
- **No new encryption** — social data (follow lists, feed, notifications) stored unencrypted like the library; private key management unchanged
