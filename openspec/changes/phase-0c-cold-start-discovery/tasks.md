## 1. Actor Cache — Discovery Source Tagging

- [x] 1.1 Add `discoverySource` enum (`mDNS`, `stun`, `peerExchange`, `mastodonImport`, `manual`) to the actor cache schema in `NodeDiscoveryService`
- [x] 1.2 Migrate existing cache entries to default `discoverySource` of `manual`
- [x] 1.3 Update `NodeDiscoveryService.cacheActor` to accept and persist `discoverySource`
- [x] 1.4 Ensure higher-priority sources are not overwritten by lower-priority ones on cache update

## 2. Peer Exchange — Core Implementation

- [x] 2.1 Create `PeerExchangeJob` data class with fields: `actorUrl`, `enqueuedAt`
- [x] 2.2 Implement `PeerExchangeService` in `lib/features/federation/discovery/peer_exchange_service.dart` with a low-priority queue and sequential execution
- [x] 2.3 Implement collection fetch in `PeerExchangeService`: fetch `followers` and `following` from a given actor URL, paginate up to 200 items each, resolve each actor object via `ActorResolver`
- [x] 2.4 Persist resolved actors to `NodeDiscoveryService` with `discoverySource = peerExchange`
- [x] 2.5 Enforce one-hop limit: do NOT enqueue follow-on peer exchange jobs for discovered actors
- [x] 2.6 Enforce per-collection cap of 200 items regardless of collection size
- [x] 2.7 Handle fetch failures silently: log at debug level and discard the job; do not surface errors to the user
- [x] 2.8 Wire rate limiting so peer exchange jobs yield to foreground network activity

## 3. Peer Exchange — Follow Integration

- [x] 3.1 In `SocialSubscribingService.follow()`, enqueue a `PeerExchangeJob` for the newly followed actor after the `Follow` activity is sent
- [x] 3.2 Verify the follow confirmation UI is not blocked or delayed by the peer exchange enqueue
- [x] 3.3 Update `social-subscribing` tests to assert peer exchange is triggered on follow

## 4. Mastodon Bridge Service

- [x] 4.1 Create `MastodonBridgeService` in `lib/features/federation/discovery/mastodon_bridge_service.dart`
- [x] 4.2 Implement handle parsing: validate `@username@instance` format and extract host; return inline validation error for malformed input
- [x] 4.3 Implement Mastodon actor resolution via `ActorResolver.resolveWebFinger` using the parsed handle
- [x] 4.4 Implement followers/following collection fetch: retrieve up to 200 items per collection with graceful handling of 401/403 (skip inaccessible collections, not an error)
- [x] 4.5 Implement `x-nightingale-actor-url` extraction: scan each fetched actor object for the extension field; validate it is a valid HTTPS URL; ignore malformed values silently
- [x] 4.6 Deduplicate the result list (a contact may appear in both followers and following)
- [x] 4.7 Resolve each discovered Nightingale actor URL and cache via `NodeDiscoveryService` with `discoverySource = mastodonImport`
- [x] 4.8 Implement per-instance rate limiting: max one import attempt per instance per hour with exponential backoff on 429

## 5. Mastodon Import UI

- [x] 5.1 Create `MastodonImportScreen` widget with handle input field, validate-on-submit, and loading state
- [x] 5.2 Implement suggested follows list: person cards (display name, avatar, no raw handles) with individual follow buttons and a "Follow all" button
- [x] 5.3 Implement "Follow all" action: send `Follow` activities sequentially; update each card to "Following" state on success
- [x] 5.4 Implement empty state: "None of your Mastodon connections are on Nightingale yet" with a share-the-app prompt
- [x] 5.5 Ensure the screen is dismissible at any point (skip/back) without leaving pending network requests

## 6. Onboarding Discovery Step

- [x] 6.1 Add `onboardingDiscoveryShown` boolean flag to local preferences (persisted across launches)
- [x] 6.2 Create `DiscoveryOnboardingStep` widget with Mastodon import CTA (primary) and "Find by username" (secondary) and a "Skip" link
- [x] 6.3 Wire `DiscoveryOnboardingStep` into the onboarding flow immediately after identity setup, gated by `onboardingDiscoveryShown == false`
- [x] 6.4 Implement "Find by username" path in onboarding: handle/URL input → `ActorResolver` → single suggested follow card
- [x] 6.5 Mark `onboardingDiscoveryShown = true` on: skip, successful import completion (even with zero matches), or successful follow from username search
- [x] 6.6 Verify the step does not appear on second launch regardless of how it was dismissed

## 7. Find People Screen — Post-Onboarding Discovery

- [x] 7.1 Add "Connect Mastodon" entry point to `FindPeopleScreen` that opens `MastodonImportScreen`
- [x] 7.2 Add username/handle search field to `FindPeopleScreen` with the same resolution flow as the onboarding step
- [x] 7.3 Show a persistent non-blocking empty-state banner in the social feed when the user has zero follows, linking to `FindPeopleScreen`
- [x] 7.4 Dismiss the empty-state banner once the user has at least one follow

## 8. Tests

- [x] 8.1 Unit test `MastodonBridgeService`: valid handle parsing, invalid format rejection, `x-nightingale-actor-url` extraction, deduplication, rate limiting
- [x] 8.2 Unit test `PeerExchangeService`: one-hop limit, 200-item cap, silent failure on fetch error, discovery source tagging
- [x] 8.3 Unit test `SocialSubscribingService`: assert peer exchange job is enqueued on follow, assert no job on unfollow
- [x] 8.4 Widget test `MastodonImportScreen`: empty state, matches list, "Follow all" action, skip path
- [x] 8.5 Widget test `DiscoveryOnboardingStep`: shown once, skip sets flag, Mastodon CTA navigates to import screen
- [x] 8.6 Integration test: follow an actor → verify peer exchange job runs → verify discovered actors appear in actor cache with correct `discoverySource`
