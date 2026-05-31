## Context

Phase 0b delivered stable addressing (STUN), same-network peer discovery (mDNS), and queue-and-retry delivery. The network layer works correctly once two nodes know each other. What is missing is any mechanism for **first contact** between strangers — a new user on a fresh install has no path to discover anyone. The existing `ActorResolver` already supports WebFinger resolution; `SocialSubscribingService` already fires background peer indexing on follow, but that indexing is shallow and untested. Phase 0c completes the discovery story before any feature work depends on having a populated social graph.

The three mechanisms — Mastodon import, peer exchange, and onboarding discovery — are complementary and independently valuable. A user with a Mastodon account gets instant value from import. A user without one still benefits from peer exchange the moment they follow a single person (via mDNS, QR code, or link). The onboarding step surfaces both paths at the right moment.

## Goals / Non-Goals

**Goals:**
- A new user can find and follow at least one person within 60 seconds on any network, without knowing an IP or raw URL
- Mastodon users can import their social graph immediately using public ActivityPub endpoints
- Every follow event propagates the followed node's social graph to the local device (peer exchange)
- Discovery degrades gracefully — if Mastodon or any external endpoint is unreachable, existing mDNS and actor cache paths still work
- No central authority required for any of this to function

**Non-Goals:**
- A Nightingale-operated bootstrap directory (may be added later as an optional accelerant, not a dependency)
- Crawling the wider fediverse beyond direct followers/following collections
- Real-time "who's online" presence
- Mastodon OAuth login or write access to Mastodon accounts

## Decisions

### Decision 1: `x-nightingale-actor-url` as the primary cross-platform bridge, directory as optional

**Choice:** Primary detection path is scanning fetched Mastodon actor objects for an `x-nightingale-actor-url` extension field. A Nightingale user who wants to be discoverable via their Mastodon profile sets this field on Mastodon. No directory required.

**Rationale:** A bootstrap directory is infrastructure to operate, a single point of failure, and a governance burden. The `x-nightingale-actor-url` approach is fully decentralised: a user opts in by editing their Mastodon profile, Nightingale reads it from the public actor object, and no intermediary is involved. The directory can be added later as an optional accelerant (useful for the bootstrap period before `x-nightingale-actor-url` adoption grows) but must never be a hard dependency.

**Alternative considered:** Registering Nightingale users in a central directory indexed by Mastodon handle. Rejected: requires operating infrastructure, creates a privacy surface (mapping Mastodon identity → Nightingale actor URL), and adds a hard dependency on uptime.

---

### Decision 2: Peer exchange is background-only and depth-limited

**Choice:** On follow, fire a background job (via `SocialSubscribingService`) that fetches the new contact's followers and following collections and caches actor objects. This runs after the `Follow` activity is sent and does not block the follow UX. Depth is limited to **one hop** (direct connections only; no recursive expansion). Per-collection fetch is capped at **200 actors**.

**Rationale:** Peer exchange without depth limits fans out explosively — a node with 10,000 followers would trigger 10,000 actor fetches when followed. One hop (direct connections of the new contact) provides meaningful social graph expansion (typically dozens to hundreds of nodes) with predictable and bounded cost. The cap of 200 is consistent with typical ActivityPub `first`/`next` page navigation and avoids runaway pagination.

**Alternative considered:** Unbounded recursive expansion. Rejected: O(n²) fetch volume in the worst case, battery and bandwidth prohibitive on mobile.

---

### Decision 3: `MastodonBridgeService` as a distinct service

**Choice:** Create `lib/features/federation/discovery/mastodon_bridge_service.dart` to own: handle parsing, WebFinger resolution, followers/following collection fetch, `x-nightingale-actor-url` extraction, and match surfacing. `ActorResolver` is called internally but the orchestration lives in the bridge.

**Rationale:** `ActorResolver` is a low-level resolver; the Mastodon import flow has its own multi-step lifecycle (enter handle → resolve → fetch collections → scan → produce suggestions) that belongs in a dedicated service. Keeping the bridge isolated also makes it easy to test and to swap out later (e.g. replacing the `x-nightingale-actor-url` field name or adding a directory lookup step).

---

### Decision 4: Actor cache extended via existing `NodeDiscoveryService`

**Choice:** Actors discovered through peer exchange and Mastodon import are persisted through the existing `NodeDiscoveryService` / actor cache layer. No new database table.

**Rationale:** The actor cache already stores resolved actor objects with a source URL key. Peer-exchange-discovered actors are just more resolved actors. Reusing the existing path avoids schema fragmentation and keeps the reachability and delivery layers aware of newly discovered nodes automatically.

**Source tagging:** Each cached actor record gets a `discoverySource` enum (`mDNS`, `stun`, `peerExchange`, `mastodonImport`, `manual`) to enable debug panel filtering and future analytics. This is an additive column on the existing cache table.

---

### Decision 5: Onboarding discovery step is shown once, post-identity-setup

**Choice:** A new `DiscoveryOnboardingStep` widget is inserted immediately after identity setup in the onboarding flow. It is shown exactly once (persisted by a `onboardingDiscoveryShown` flag in local prefs). The step is skippable; tapping skip sets the flag and proceeds. The Mastodon import path is the primary CTA; username search is secondary.

**Rationale:** The discovery step must appear at the moment the user has identity but no connections — that window is onboarding. Showing it on every launch would be intrusive. Skipping must always be available; the app is valid for solo use.

## Risks / Trade-offs

- **Mastodon rate limiting on collection fetches** → Mitigation: fetch at most one page (200 items) per collection; add a per-instance rate-limit guard (max one import attempt per instance per hour) with exponential backoff on 429 responses.

- **`x-nightingale-actor-url` adoption is slow early on** → Mitigation: this is expected. Peer exchange and mDNS still work independently. The import flow surfaces an explanation of what the field is and how to set it on Mastodon, creating a natural onboarding path for new Mastodon users.

- **Mastodon instances with closed followers/following collections** → Mitigation: handle 401/403 gracefully; surface zero results without an error state ("no connections found" rather than "failed"). Some instances restrict collection visibility by policy.

- **Peer exchange storm on following a very popular node** → Mitigation: the 200-actor per-collection cap and one-hop depth limit bound this. Additionally, peer exchange jobs are enqueued with low priority and rate-limited to avoid starving foreground network use.

- **Privacy: fetching someone's full social graph on follow** → Mitigation: followers/following collections are public ActivityPub endpoints by spec; no private data is accessed. The `discoverySource` tag lets users see in a future debug/settings panel where each cached contact came from.

## Open Questions

- **Bootstrap directory:** Should Phase 0c ship a lightweight read-only directory endpoint (e.g. a static JSON file on a CDN, manually curated) to accelerate the cold-start period before `x-nightingale-actor-url` adoption grows? This could be added as a non-blocking optional fetch in `MastodonBridgeService` without changing the architecture.
- **"Find by username" scope in onboarding:** Username search currently means "actor URL or WebFinger handle." Should the onboarding secondary path surface a curated list of known-good seed nodes (e.g. developer accounts) rather than a freeform handle entry, to reduce the "I don't know any handles" dead end?
