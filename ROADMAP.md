# nightingale — Federated Music Player
### Build Roadmap

---

## Vision

nightingale is a federated music player where each user's app is their node on the network. The app hosts the user's music library, publishes listening activity to the network, and streams music from other users' nodes — all over ActivityPub. Federation connects every node into one network, and recommendations emerge from real listening activity across real people. No central server. No middleman. Just the network.

Audio streaming between nodes is **best-effort, not guaranteed.** Mobile devices are not always-on servers, so direct peer-to-peer streaming is treated as a bonus when a host is reachable — not as the default that every interaction depends on. The identity, social, and recommendation layers are fully federated and reliable; the audio bytes are opportunistic, heavily cached, and gracefully degraded when a host is offline. Designing honestly around that reality is the heart of the product.

---

## Principles

- **The app is the node** — each installation of nightingale is a federated node. It hosts the user's library, publishes activity, participates in ActivityPub directly, and *opportunistically* serves and streams audio to and from peers. There is no separate server to connect to, configure, or maintain.
- **Streaming is best-effort** — direct peer-to-peer audio is a bonus, not a promise. The network layer assumes hosts are frequently unreachable and is built around caching, relays, and graceful fallback rather than guaranteed availability.
- **Federation is the backbone, not a feature** — ActivityPub is not bolted on; it is the architecture. Identity, social graph, and recommendation signals federate reliably even when audio does not.
- **Humans, not handles** — the fediverse mechanics (`@user@node`, actors, inboxes) are plumbing. A normal user should rarely if ever see a raw handle. People, faces, and provenance come first; protocol details stay hidden.
- **Communicate state honestly** — a federated player is an *uncertain* system. Buffering, offline hosts, partial libraries, and fallback playback are the normal case, not edge cases. The UI makes unavailability feel intentional, never broken.
- **Phases over timelines** — each phase ships when it is complete, not when a calendar says so.
- **Debugging is a first-class feature** — every phase ships with its own diagnostic tooling baked in.
- **UI is clean, minimal, and typographic** — fresh and simple, generous whitespace, restrained palette, motion with purpose.

---

## Content & Licensing Position

This is decided up front because it is existential — users streaming copyrighted music to each other is straightforwardly infringing and will get the app rejected from both stores and expose real legal liability. nightingale's launch position is one (or a combination) of:

- **Creative Commons / independent / self-owned music only** — honest, legal, and a smaller catalog. Tracks the user legally owns or that carry permissive licenses. This is the default launch scope.
- **Partner with services that license** — resolve playback through a licensed source where one exists, federating everything *except* the audio bytes.
- **A player for music the user already owns** — nightingale is the player and federation layer; the bytes are the user's own files.

The federation, social, and recommendation layers work identically regardless of which scope is active. The licensing position constrains *what* may be streamed, not *how* the network operates. This is settled before Phase 4 (audio streaming), not after.

---

## Phase 0 — De-Risk the Core Premise

### Goals
Before any design system, architecture, or UI work, prove or disprove the single riskiest assumption: **can two real phones actually stream audio to each other reliably in the wild?** This is a throwaway spike, built to be deleted. If it fails, the entire architecture changes — and we want to know that in week two, not month six.

### Deliverables
- Two physical devices, one serving an audio file to the other over a **real cellular network** (not same-wifi, not localhost) — no UI, no polish, no reuse intended
- P2P transport spike: evaluate libp2p and WebRTC-with-relays for NAT traversal between two mobile devices on carrier-grade NAT
- Measure: connection success rate, time-to-first-byte, sustained throughput, drop frequency, reconnection behavior across network transitions (wifi → LTE → different wifi)
- Document relay requirements: how often direct connection fails and a relay is required, and what relay infrastructure that implies
- **Go / no-go decision** on best-effort direct streaming. If direct P2P is unworkable even as a bonus path, fall back to a relay-first or cache-and-forward model before committing to the roadmap below

### Exit Criteria
A written finding: how reliable is direct phone-to-phone streaming, under what conditions, and what does the caching/relay strategy need to be to make the product feel acceptable given that reality.

---

## Phase 1 — Foundation

### Goals
Establish the project structure, architecture patterns, design system primitives, and debugging infrastructure that every subsequent phase builds on. Bake in two principles from the very first commit: **humans, not handles**, and **honest network-state communication.**

### Deliverables

#### Project Setup
- Flutter project initialized (minimum supported SDK defined)
- Monorepo-friendly folder structure (`lib/core`, `lib/features`, `lib/shared`)
- Environment configuration (dev / staging / prod)
- Linting and formatting rules enforced

#### Architecture
- State management pattern selected and scaffolded (Riverpod)
- Navigation layer established (go_router)
- Dependency injection container wired
- Repository pattern defined for all data sources

#### Design System
- Token-based theme: typography scale, color palette, spacing grid, radius constants
- Base component library: buttons, cards, inputs, bottom sheets, modals
- **Network-state component primitives from day one** — buffering, host-offline, stream-failed-playing-local, and partial-library states are first-class shared components, not afterthoughts. The vocabulary for communicating uncertainty is part of the base library.
- **Identity presentation primitive** — a person is shown as a name and avatar, never a raw `@user@node` handle. The handle is metadata, surfaced only in advanced/settings contexts.
- Motion constants: duration, easing curves — subtle, intentional animation
- Dark and light mode support from day one

#### Debugging Infrastructure
- Structured logging layer (`Logger` abstraction over `dart:developer`)
- In-app debug overlay (dev builds only): shows log stream, app version, environment, current route
- **Debug overlay activation does not rely on shake gesture** — shake collides with iOS accessibility shortcuts and system "undo." Use a dev-only entry point (e.g. a settings tap sequence or a debug-build-only button). The overlay must never leak into release builds.
- Error boundary widgets that catch and display Flutter errors gracefully in dev
- Crash reporting hook (stubbed for prod wiring later)
- Network request inspector (in-app, dev only)

---

## Phase 2 — Core Music Player

### Goals
A fully functional local music player. This phase proves the playback engine and establishes the UI language for the player experience.

### Deliverables

#### Library Management
- Scan device storage for audio files
- Parse ID3/metadata tags (title, artist, album, artwork, duration, genre)
- Local database for library state (Drift/SQLite) — **stored unencrypted.** The album list is not sensitive; encrypting it adds key-management and performance friction for no security benefit. Sensitive material (the private key, the taste profile) is encrypted specifically and separately (see Phase 3 and Phase 6).
- Library views: All Songs, Albums, Artists, Genres
- Manual library refresh and auto-detection of changes

#### Playback Engine
- Audio playback via `just_audio`
- Queue management: play, pause, skip, seek, shuffle, repeat (off / one / all)
- Background playback with system media session integration (lock screen controls, notification)
- Gapless playback
- Audio focus handling (pause on call, duck on notification)
- Stream playback support — the playback engine handles local files and remote audio streams from other nodes through the same interface, with remote streams treated as best-effort (may buffer, fall back, or fail)

#### Player UI
- Now Playing screen: artwork, track info, scrubber, controls
- Mini player persistent across all screens
- Queue view: reorder, remove tracks
- Album and artist detail screens
- Search across local library

#### Debugging — Phase 2 Additions
- Playback diagnostics panel (dev overlay tab): current queue state, buffer status, audio session state, active audio format, stream source (local vs. remote node)
- Library scan log: files found, files rejected, parse errors, duration

---

## Phase 3 — Node Identity, Federation Core & Moderation

### Goals
Each app becomes a node with its own federated identity. This phase establishes the ActivityPub layer — serving and receiving — and **builds moderation and abuse defenses in from the start**, because retrofitting them onto a live federated network is brutally hard.

### Deliverables

#### Node Identity
- On first launch, the app generates a federated identity. The raw handle (`@user@node`) exists in the protocol but is **never the primary presentation** — see "humans, not handles."
- Actor object generated per ActivityPub spec (id, inbox, outbox, followers, following, publicKey)
- **Key pair generation using Ed25519** (smaller, faster, and where the modern fediverse is heading) rather than RSA-2048. Private key stored exclusively in the device secure enclave (iOS Keychain / Android Keystore) — never written to app storage or transmitted.
- **Account portability / key migration story** — identity must survive a device change. Implement a migration mechanism modeled on Mastodon's `Move` activity: a user upgrading or replacing a phone can carry their identity, followers, and following forward rather than orphaning the account. This is designed now, not bolted on later.
- WebFinger endpoint served from the app for actor discovery by other nodes

#### ActivityPub Layer
- All federation traffic over HTTPS/TLS — no plaintext connections accepted
- HTTP Signatures implementation (sign all outgoing requests, verify all incoming) — authenticates request origin and guarantees payload integrity in transit
- **Signature-replay protection** — reject replayed or stale signed requests (nonce / timestamp window enforcement) from day one
- The app serves its own ActivityPub endpoints: inbox, outbox, followers collection, following collection
- Actor fetch: resolve any handle to an Actor object on the network
- Inbox delivery: POST signed activities to remote node inboxes
- Outbox: serve the local user's activity history to the network

#### Moderation & Abuse Defense (built in now)
- **Instance / node-level defederation** — the ability to block an entire malicious node, not just individual actors
- **Rate limiting on inbox delivery** — protect against flooding and spam from hostile or runaway nodes
- Allow/deny list scaffolding for nodes, ready for user- and (future) community-level policy
- Activity validation and sanitization on ingestion — never trust incoming payloads

#### Node Reachability (best-effort)
- The app attempts to maintain a reachable address so peers can deliver to its inbox and stream from its library — but treats unreachability as the **expected** state, not an error
- Relay-assisted delivery for inbox activities when the node is not directly reachable
- Connection state management with retry and reconnection logic
- Activity queueing: incoming activities for an offline node are queued (locally or via relay) and delivered when it returns

#### Debugging — Phase 3 Additions
- Federation inspector panel (dev overlay tab):
  - Outgoing activity log with full JSON payload and HTTP response
  - Incoming activity log
  - HTTP Signature verification status per request (including replay-rejection events)
  - Actor resolution cache viewer
  - Node reachability status
  - Defederation / rate-limit state viewer
- WebFinger resolution debugger

---

## Phase 4 — Library Federation & Best-Effort Audio Streaming ✅ COMPLETE

### Goals
Each node publishes its music library to the network and can stream audio from other nodes **when they are reachable.** This is where nightingale becomes a federated music player — with streaming understood as opportunistic, cached, and gracefully degraded.

### Deliverables

#### Library Publishing ✅
- User controls what is shared: full library, selected playlists, or nothing (explicit opt-in)
- Publishing respects the licensing scope (see Content & Licensing Position)
- Library metadata published as ActivityPub Collection (track titles, artists, albums, artwork)
- Audio served opportunistically over the P2P transport (libp2p / WebRTC with relays, per the Phase 0 finding); availability is never guaranteed
- Listening events published as `Listen` activities to the network
- Privacy controls: public, followers-only, private — enforced at the node level on every request
- **Sharing settings UI** with radio options for scope selection
- **Library publishing debug panel** in dev overlay

#### Audio Streaming (best-effort) ✅
- Stream audio from any **currently reachable** node; when a host is offline, fall back cleanly (cache, alternate source, or local copy) rather than failing
- The playback engine resolves a federated track reference to a stream source on a hosting node
- **Aggressive caching** — recently and likely-to-be-played remote audio is cached locally so playback survives a host going offline mid-session
- Authenticated streaming — the hosting node verifies the requesting node's identity via HTTP Signatures before serving audio
- Adaptive buffering for variable and unreliable network conditions
- Followers-only tracks are verified against the followers collection before the stream is served
- Relay fallback for streaming where direct connection fails and a relay path is viable
- **Stream status indicators** on Now Playing screen (buffering, host offline, cached)
- **Stream inspector debug panel** in dev overlay

#### Subscribing ✅
- Follow any actor to subscribe to their library activity (presented as following a *person*, not a handle)
- Fetch and cache remote library Collections — browse other users' libraries even when the host is offline
- Incoming `Listen` activities processed and stored locally as recommendation signals
- **Network tab UI** for browsing followed actors' libraries with pull-to-refresh
- **Background refresh** service for remote libraries
- **Social feed screen** for viewing incoming Listen activities

#### Data Model & Track Identity ✅
- Unified track model: local and remote tracks share one schema; the only difference is stream source and reachability
- **Acoustic fingerprinting for deduplication** — Chromaprint FFI bindings with fallback to perceptual hash comparison. "Artist + title + duration window" both over-merges (distinct live versions collapsed together) and under-merges (the same track with differing metadata kept separate). Fingerprinting is the data-quality backbone of the recommendation engine.
- **Reversible merges with stored provenance** — every dedup decision records why two tracks were or were not merged, and can be undone. A bad merge must never be permanent.
- Attribution preserved: every track knows which node(s) host it
- **Deduplication trace debug panel** in dev overlay

#### Debugging — Phase 4 Additions ✅
- Library sync inspector: what was published, to whom, when, delivery status
- Stream inspector: active remote streams, host node, reachability, bytes received, cache hits, buffer health, relay vs. direct path
- Incoming library feed viewer: raw activity stream from followed nodes
- Deduplication trace: fingerprint comparison, merge decision, provenance, and undo handle

---

## Phase 5 — Social Layer

### Goals
Users interact with each other and their libraries through the federated social graph — always presented as people, never as handles.

### Deliverables

#### Social Graph
- Follow / unfollow any actor on the network
- Followers and following lists (people and avatars first)
- Follow requests (for private accounts)
- **User-level block and mute** — enforced locally, propagated to the network — building on the node-level defederation already in place from Phase 3

#### Activities
- **Now Playing** — broadcast currently playing track as a `Listen` activity (opt-in, per session)
- **Save** — save a track from another node into the local queue or library
- **Share** — forward a track or playlist to followers (`Announce`)
- **Like** — send a `Like` activity to a track hosted on another node
- **Playlist share** — publish a playlist as an ActivityPub `OrderedCollection`

#### Social Feed
- Chronological feed of activity from followed people: listens, shares, new additions
- Notification inbox: new followers, likes, shares directed at the user
- Profile view: bio, now playing, library, recent activity, shared playlists — built around the person, with the raw handle tucked away

#### Debugging — Phase 5 Additions
- Social graph inspector: follower/following counts, pending follow requests, block/mute and defederation state
- Activity delivery report: per-activity delivery status to each recipient node (including relay path)
- Feed hydration log: which activities were fetched, filtered, and rendered

---

## Phase 6 — Recommendations Engine

### Goals
Turn the federated social graph and listening data into meaningful discovery — no central server, no black-box algorithm — and **solve cold start**, so a brand-new user with zero follows still has something worth opening.

### Deliverables

#### Cold-Start Bootstrap (critical)
A brand-new user follows no one, so a recommendation engine that derives everything from followed nodes produces an empty app — the most common failure mode of decentralized social products. nightingale ships a bootstrap path from the first launch:
- **Server-light discovery of popular nodes** — a lightweight discovery mechanism to surface active, interesting nodes worth following
- **Seed recommendations from genre / library overlap** — match the new user's own library against the network to suggest people and tracks immediately
- **Opt-in global "trending across the network" relay** — a network-wide trending feed the user can draw from before they've built a personal graph
- The app must feel alive on day one, before a single follow

#### Signal Collection
- Local signals: play count, skip rate, save, like, playlist add
- Network signals: listens from followed nodes, their saves and likes, what their network is listening to
- **Signals stored locally and the taste profile encrypted at rest** — this is the genuinely sensitive data the album list was not. The user owns their taste profile; it never leaves the device unless shared.

#### Recommendation Logic
- **Network trending**: tracks appearing frequently across followed nodes' recent listens
- **Taste affinity**: surface tracks liked/saved by nodes whose listening overlaps significantly with the user's
- **New from known**: tracks by artists already in the user's library, discovered via the network
- All logic runs on-device — no data leaves unless the user shares it

#### Discovery UI — Provenance as the Feature
Provenance is the entire differentiator from Spotify, so the UI is built around **people, not faceless rows.** A recommendation is never an anonymous suggestion — it carries the human reason it surfaced:
- "Maya has had this on repeat this week"
- "3 people you follow saved this"
- "New from an artist in your library, surfaced by Jordan"
- Discover screen organized around people and reasons, not opaque algorithmic shelves
- Every recommendation shows *who* and *why*, with faces and names
- One-tap stream or save from any recommendation — streams best-effort from the hosting node, with clear state if the host is offline

#### Debugging — Phase 6 Additions
- Recommendation engine inspector: input signals, scored candidates, final ranked output, and which cold-start vs. graph-derived path produced each
- Signal log: every signal event (play, skip, save) with timestamp and weight assigned
- Taste affinity matrix viewer (dev only): similarity scores between local node and each followed node

---

## Phase 7 — Polish & Hardening

### Goals
The app is feature-complete. This phase refines experience quality, resilience, accessibility, and real-world readiness. **Note:** the defining federated-player UX challenge — communicating network state and degraded modes — is *not* deferred to this phase. Those states are first-class from Phase 1; Phase 7 polishes them rather than inventing them.

### Deliverables

#### UX Refinement
- Interaction audit: every tap, swipe, transition reviewed for latency and feel
- Animation polish: entrance/exit choreography, state transitions, loading states
- Polish the (already-built) network-state surfaces: buffering, host-offline, stream-failed-playing-local, partial-library — make each one feel calm and intentional rather than like an error
- Empty states: thoughtful, on-brand empty screens for every list and feed (the cold-start surfaces from Phase 6 included)
- Haptic feedback mapped to meaningful moments (track start, save, error)
- Onboarding flow: first-launch experience that sets up the node identity and migration story without exposing technical complexity — "humans, not handles" carried all the way through

#### Resilience
- Offline mode: full local playback, queued activities delivered when back online
- Graceful degradation when a remote node is unreachable — skip to next available source (cache, relay, local), surface status to the user honestly
- Library corruption recovery: detect and repair broken local database state

#### Accessibility
- Full VoiceOver / TalkBack support
- Minimum touch target sizes enforced
- Color contrast audit against WCAG AA
- Dynamic type support

#### Performance
- App startup time profiling and optimization
- Feed rendering performance (large lists, image loading)
- Memory profile during extended playback sessions
- Battery usage audit (background federation and best-effort serving tuned)
- Stream buffering and cache-eviction optimization across varied network conditions

#### Testing
- Unit tests: recommendation logic, cold-start bootstrap, ActivityPub serialization, HTTP Signature signing/verification + replay protection, acoustic fingerprinting/dedup, stream authentication, key migration
- Widget tests: player controls, feed rendering, library views, network-state components
- Integration tests: full federation round-trip (publish activity → receive on second node → best-effort stream audio → fall back when host drops)

#### Debugging — Phase 7 Additions
- Performance overlay (dev): frame render times, memory usage, network byte counts, stream latency, cache hit rate
- Production error reporting fully wired (non-PII only)
- Debug builds include full overlay; release builds strip all diagnostic code via compile-time flags

---

## Phase 8 — Distribution

### Goals
Ship to real users on both platforms.

### Deliverables
- iOS App Store submission: provisioning, entitlements, App Store Connect setup
- Google Play Store submission: signing, Play Console setup
- **Store-readiness review against the licensing position** — confirm the shipped catalog scope (CC / independent / owned / licensed-partner) satisfies both stores' content policies before submission
- CI/CD pipeline: automated build, test, and distribution on merge to main
- Versioning strategy and changelog process
- Crash reporting dashboard wired to production
- Public issue tracker and feedback channel established

---

## Debugging Philosophy

Every phase ships with debugging tools scoped to what that phase introduces. The in-app debug overlay is the single surface — tabs are added per phase. Debug tooling is:

- **Compile-time gated** — zero overhead in release builds; release builds strip all diagnostic code
- **Dev-entry, never shake** — activated through a dev-build-only entry point, *not* a shake gesture (which collides with iOS accessibility and system undo) and never visible in production UI
- **Structured** — logs are typed and filterable, not raw print statements
- **Non-blocking** — diagnostic panels never interfere with app state

---

## Design Principles (UX/UI)

- **Humans, not handles** — people are shown as names and faces; raw `@user@node` handles are plumbing, surfaced only in advanced contexts
- **Communicate uncertainty honestly** — buffering, offline hosts, fallback playback, and partial libraries are the normal case; the design makes them feel intentional, never broken
- **Provenance is the product** — every recommendation carries its human reason ("Maya's been playing this"); discovery is built around people, not faceless rows
- **Typographic hierarchy does the heavy lifting** — layout is readable before color or iconography
- **One primary action per screen** — no competing CTAs
- **Whitespace is intentional** — breathing room is not wasted space
- **Color is restrained** — near-monochromatic base, single accent, semantic use only
- **Motion has meaning** — nothing animates without communicating state change
- **Controls are obvious** — discoverability over cleverness