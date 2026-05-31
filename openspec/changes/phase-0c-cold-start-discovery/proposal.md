## Why

mDNS and STUN solve same-network and cross-network reachability once two nodes already know each other — but neither solves **first contact** between strangers on different networks. A brand-new user who installs Nightingale and knows nobody on the network has no path in; a federated app with no discovery mechanism is a dead app, and this must be fixed before Nightingale is meaningful to use.

## What Changes

- **Mastodon social graph import** — users can enter their Mastodon handle and immediately see which of their Mastodon connections are already on Nightingale, presented as suggested follows with a single "Follow all" action. Uses public ActivityPub endpoints Mastodon already exposes; entirely optional; requires no Mastodon approval.
- **`x-nightingale-actor-url` extension field** — a Mastodon user can annotate their Mastodon actor profile with their Nightingale actor URL, allowing peer detection without a bootstrap directory.
- **Peer exchange at follow time** — when the user follows any actor, the app fetches that actor's followers and following collections and resolves + caches all actor objects. A single shared contact (e.g. via mDNS on first meeting) propagates an entire social graph to the device, making two nodes that have never been on the same network mutually discoverable.
- **Onboarding discovery step** — onboarding gains a new final step offering Mastodon import (primary path) or username search (secondary path). The step is skippable; solo use remains valid. The app must not feel empty on first open.

## Capabilities

### New Capabilities

- `mastodon-social-graph-import`: WebFinger-based resolution of a user's Mastodon followers/following collections, scanning for linked Nightingale actors via `x-nightingale-actor-url`, and surfacing matches as suggested follows.
- `peer-exchange`: On every follow event, fetch and cache the new contact's full followers and following collections so their social graph propagates to the local device.
- `onboarding-discovery`: A post-identity-setup onboarding step that offers Mastodon import or username search as paths to a first connection, skippable for solo use.

### Modified Capabilities

- `social-subscribing`: The follow action now triggers a full peer-exchange fetch of the new contact's followers/following collections in addition to the existing `Follow` activity delivery.

## Impact

- **`SocialSubscribingService`** — extend follow action to trigger peer exchange (fetch + cache followers/following collections of the new contact).
- **`ActorResolver`** — already handles WebFinger; will be used to resolve Mastodon handles and scan `x-nightingale-actor-url` extension fields on fetched actor objects.
- **`NodeDiscoveryService`** — extended or supplemented to cache resolved actors from peer exchange and Mastodon import.
- **Onboarding flow** — new screen/step added after identity setup; integrates Mastodon import and username search.
- **New `MastodonBridgeService`** — orchestrates handle entry, WebFinger resolution, followers/following collection fetch, `x-nightingale-actor-url` scanning, and suggested-follow surfacing.
- **Dependencies** — no new packages required; builds on existing `http`, `ActivityPub`, and `WebFinger` infrastructure already in place.
