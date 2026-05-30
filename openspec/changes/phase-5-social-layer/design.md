## Context

Nightingale's ActivityPub stack (Phase 3) already handles HTTP Signatures, inbox/outbox serving, actor resolution, and defederation at the node level. Phase 4 added library federation, best-effort streaming, and the follow-to-subscribe relationship needed to receive remote libraries. Phase 5 builds the full social interaction layer on top: a bidirectional social graph (not just library subscriptions), activity emission and reception (Like, Announce, Listen, Block), and the feed/notification/profile surfaces that make the network feel alive.

The core challenge is that a federated social layer deals with two distinct realities simultaneously: the richness of local, synchronous state (the user's own graph and actions) and the fundamental unreliability of remote state (follower counts, incoming activities, peer profiles). Every design decision here must respect the "communicate state honestly" principle — pending delivery, offline recipients, and partial data are the normal case.

## Goals / Non-Goals

**Goals:**
- Full bidirectional social graph: Follow, Unfollow, Block, Mute, and Accept/Reject for private accounts
- Five social activity types: Listen (Now Playing), Save, Share (Announce), Like, Playlist publish
- Chronological social feed and grouped notification inbox
- Per-actor profile view that hides the raw handle behind an "advanced info" tap
- Phase 5 debug panels in the existing dev overlay (compile-time gated)
- Reuse all existing infrastructure: HTTP Signatures, Drift, Riverpod, go_router, ActivityPub transport

**Non-Goals:**
- Direct messaging between actors (deferred — requires a separate Mastodon-compatible DM model)
- Group or community actors (out of scope for Phase 5)
- Comment threads on tracks or playlists
- Algorithmic feed ranking or recommendation (Phase 6)
- Any new encryption — social data is unencrypted like the library; private key management is unchanged

## Decisions

### 1. Social graph stored separately from library subscriptions

**Decision:** Create a dedicated `follows` table in Drift rather than reusing the Phase 4 "subscription" relationship.

**Rationale:** The Phase 4 subscription is tightly coupled to library sync — it drives background refresh of remote library Collections. The social graph follow is a different semantic: it gates activity delivery (to the follower's inbox), drives the social feed, and is the unit of block/mute. Conflating the two makes both harder to reason about. The Phase 4 subscription can be derived from or linked to the follow relationship, but they are not the same thing.

**Alternatives considered:**
- Extend Phase 4 subscription model with social flags → rejected; leads to a single bloated table trying to serve two concerns
- Single `relationships` table with type column → possible, but the type-dispatch logic at the repository layer makes queries more complex than two narrow tables

---

### 2. Follow request state machine is local-authoritative

**Decision:** Pending follow requests are tracked locally in a `follow_requests` table with states `[pending, accepted, rejected, cancelled]`. The canonical source of truth is local state; the network confirms or denies via Accept/Reject activities.

**Rationale:** Remote nodes may be offline when a Follow is sent. The UI must show "request sent, awaiting response" without blocking on the remote node being reachable. The state machine persists across app restarts.

**Alternatives considered:**
- Treat follow as optimistic (show as following immediately, roll back on Reject) → rejected; violates "communicate state honestly" — showing a follow as confirmed when it is pending is a lie
- Block the UI until Accept is received → rejected; the remote node may be offline indefinitely

---

### 3. Activity delivery via existing federation layer, not a new queue

**Decision:** Outgoing social activities (Like, Announce, Block, Listen) are routed through the existing signed-inbox-delivery infrastructure from Phase 3, not a new queue.

**Rationale:** Phase 3 already handles queueing for offline recipients, relay fallback, and delivery status tracking. Adding a parallel queue for social activities would duplicate that logic. The federation layer treats all outgoing activities uniformly — the social layer is just a new caller.

**Alternatives considered:**
- Separate high-priority queue for social activities → rejected; adds complexity with no clear benefit given all recipients are mobile nodes with similar reachability profiles

---

### 4. Feed hydration is pull-on-open, not push-streaming

**Decision:** The social feed screen fetches from the local activity store (populated by the existing inbox processor) on open. It does not maintain a live WebSocket or SSE connection.

**Rationale:** Mobile nodes are not always online; a persistent streaming connection would drain battery and break constantly. The inbox processor (Phase 3) already delivers incoming activities to the local store in the background. The feed reads from that store — refreshing on open and on pull-to-refresh is sufficient for the use case.

**Alternatives considered:**
- SSE or long-poll feed endpoint on each node → rejected; requires each mobile node to maintain a persistent server, which contradicts the best-effort reachability model
- Firebase / push-based notification for new activity → possible for Phase 7 polish; deferred because it introduces a centralized dependency

---

### 5. Person-first presentation enforced at the component level, not at the data layer

**Decision:** The `PersonTile`, `ActivityCard`, and `ProfileHeader` shared components accept a display name and avatar URL, not a raw actor object. The raw handle (`@user@node`) is an optional field surfaced only when the user explicitly requests it (an "advanced info" tap).

**Rationale:** If the data layer returns actor objects with handles and the UI decides whether to show them, the handle will leak. Enforcing person-first at the component boundary makes it structurally impossible for raw handles to appear in primary flows.

**Alternatives considered:**
- Pass full actor object and let each screen format it → rejected; too easy for a future contributor to accidentally render the handle in a list item
- Store display name separately from handle in the DB → done implicitly; the `actors` table stores `display_name`, `avatar_url`, and `handle` as separate columns, and components are typed to accept the display fields only

---

### 6. Block propagates a `Block` activity; mute is local-only

**Decision:** `Block` sends a signed `Block` activity to the remote actor's inbox (consistent with Mastodon and the broader fediverse) and locally stops processing any incoming activities from that actor. `Mute` is enforced locally only — the remote node is not notified.

**Rationale:** Block is a strong signal the remote actor should be aware of (to stop sending activities), and propagating it is standard fediverse behavior. Mute is a UI-level suppression: the user wants to stop seeing content from someone without the social weight of a block. Propagating mutes would leak information about local preferences to remote nodes.

**Alternatives considered:**
- Local-only block → rejected; would still receive (and discard) activities from the blocked actor, wasting bandwidth and leaving the blocked node unaware
- Propagate mutes → rejected; violates user privacy expectation that mutes are quiet

---

### 7. Playlist published as ActivityPub `OrderedCollection`

**Decision:** Playlists are published as ActivityPub `OrderedCollection` objects served from the local HTTP server, with a `Create` activity announcing them to followers.

**Rationale:** `OrderedCollection` is the standard ActivityPub type for ordered sets of objects; it is what outboxes and followers collections already use. Reusing it for playlists means remote nodes can fetch and render them with the same actor-resolution infrastructure.

**Alternatives considered:**
- Custom `Playlist` activity type → rejected; non-standard types break interoperability with other ActivityPub clients
- Include full track list in the `Create` announce → rejected; large playlists would bloat inbox delivery; lazy-fetch via Collection URL is better

---

### 8. Debug panels are additive tabs, not standalone screens

**Decision:** Phase 5 adds three new tabs to the existing in-app dev overlay (`lib/core/debug/`): Social Graph Inspector, Activity Delivery Report, and Feed Hydration Log. All panels are `const`-guarded with `kDebugMode` (consistent with existing panels).

**Rationale:** One surface, compile-time gated — consistent with the debugging philosophy established in Phase 1. Adding standalone debug screens would fragment the diagnostic UX.

## Risks / Trade-offs

**Inbox flooding from high-follower accounts** → The rate-limiting infrastructure from Phase 3 already applies to incoming inbox delivery. If a followed node has thousands of followers re-announcing, the local inbox processor will throttle. The trade-off is that high-volume accounts may have delayed feed entries on low-power devices.

**Follow request delivery to offline nodes** → A Follow sent to an offline node queues in the relay. If the relay drops the activity, the follow request is silently lost from the remote node's perspective. Mitigation: the local `follow_requests` table records the activity ID; a retry mechanism (or user-visible "resend" option) can re-deliver if the remote node comes online.

**Feed consistency across nodes** → Two users following the same person will see the same activities only if those activities were successfully delivered to both. Missed inbox delivery means gaps. This is acknowledged as expected behavior in a best-effort federated system; the UI should not imply the feed is complete.

**Avatar and display name staleness** → Remote actor profiles are cached locally. A followed user who changes their display name or avatar will not be reflected until the next actor refresh. Mitigation: re-fetch actor objects on profile view open; background refresh periodically for active follows.

**Announce (Share) of followers-only content** → A user can `Announce` a track that is marked followers-only on the hosting node. The hosting node enforces access at stream time (Phase 4), but the metadata (track title, artist) will be visible in the feed. This is acceptable — the metadata is not the protected asset; the audio bytes are.

## Migration Plan

Phase 5 is additive — no existing tables or routes are modified, no existing activity types are changed. Database migrations add new Drift tables (`follows`, `follow_requests`, `blocks`, `mutes`, `activities`, `notifications`, `playlists`). go_router gains new routes; the existing navigation tree is unchanged. The ActivityPub serializer gains new activity type handlers alongside existing ones.

No data migration needed. Existing users will start with empty social graphs, which is correct — the social graph is built by user action, not migrated from prior state.

Rollback: because all changes are additive, removing Phase 5 code restores the Phase 4 state without data loss (the new tables would simply be unused).

## Open Questions

- **Notification grouping threshold**: At what count should "3 people liked your track" collapse into "N people liked your track"? Suggest starting with 3+ → grouped, revisit after real usage.
- **Feed pagination depth**: How many activities should the initial feed load? Suggest 50 with infinite scroll; tune after performance profiling on a real device.
- **Now Playing broadcast granularity**: Should each track play emit a `Listen` activity, or only tracks the user finishes (>80% played)? The ROADMAP says opt-in per session; the completion threshold affects recommendation signal quality in Phase 6. For Phase 5, emit on play-start with a flag for completion; Phase 6 can weight accordingly.
- **Profile bio**: Is bio free-text (local only) or federated as part of the Actor object update? Suggest federated via `Update` activity on save — consistent with how Mastodon handles profile edits.
