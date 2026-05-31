## Context

The app uses `go_router` for navigation with a `redirect` function that guards all main routes behind onboarding completion. State is managed via Riverpod (`onboardingProvider`, `nodeIdentityProvider`). Both providers initialise with a loading state and resolve asynchronously on startup.

The current failure has two compounding causes:

1. **No `refreshListenable`** — `GoRouter` only re-evaluates its `redirect` when a navigation event occurs or when a registered `Listenable` notifies. Without one, the redirect runs once at startup (when both providers are still in their loading states) and then never again — so `OnboardingRequired` is set correctly but nothing acts on it.

2. **Migration bypass** — `OnboardingNotifier._check()` reads `nodeIdentityProvider` at call time. If the identity check resolves first (common on warm starts), the notifier sees `NodeIdentityReady`, writes `onboarding_complete = true` to secure storage, and emits `OnboardingComplete` — the full flow is skipped permanently.

The Mastodon handle is entered on the existing Discovery step but is only used in-memory for that one import; it is never written to storage. This means the handle is unavailable to any other service (feed, discovery, future cross-posting) and the user must re-enter it each time.

## Goals / Non-Goals

**Goals:**
- Onboarding fires on every fresh install and cannot be bypassed by pre-existing state
- Router redirect re-evaluates correctly after async provider resolution
- Mastodon handle is collected once during onboarding and stored durably
- Any Riverpod consumer in the app can read the stored handle via a provider
- Dead code (`IdentitySetupScreen`) is removed

**Non-Goals:**
- Mastodon OAuth / authenticated API access — the handle is used only for public WebFinger lookups; no token exchange is in scope
- Making Mastodon entry mandatory — the step remains skippable; solo use must remain valid
- Changing the social graph import logic inside `MastodonBridgeService`
- Any UI redesign beyond inserting the new step

## Decisions

### 1. refreshListenable via ProviderListenable bridge

**Decision:** Create a `RouterRefreshNotifier` — a `ChangeNotifier` that subscribes to `onboardingProvider` and `nodeIdentityProvider` via `ref.listen` and calls `notifyListeners()` on any state change. Pass it to `GoRouter(refreshListenable: ...)`.

**Why not use `StreamProvider` or polling?** `ChangeNotifier` is the idiomatic go_router integration point. Riverpod's `ProviderContainer.listen` gives precise, synchronous callbacks on state changes without any polling overhead.

**Alternative considered:** Wrap the entire router in a `ConsumerWidget` and call `router.refresh()` on provider changes. Rejected — `appRouter` is a top-level singleton; rebuilding the widget tree to drive routing is architecturally backwards.

### 2. Remove the migration bypass entirely

**Decision:** Delete the `if (identityState is NodeIdentityReady)` block from `OnboardingNotifier._check()`. Onboarding completion is determined solely by the `nightingale_onboarding_complete` flag in secure storage.

**Why this is safe:** The flag is written by `completeOnboarding()` at the end of the flow. Any user who genuinely completed onboarding already has the flag set. Users who set up an identity via the old standalone screen do NOT have the flag, so they will be shown the onboarding — this is intentional; we want them to go through the Mastodon step.

**Risk:** Existing users with a node identity but without the flag will be sent through onboarding again. The identity step will still work correctly (it calls `createIdentity` which is idempotent in its side effects, though it re-generates keys). See Migration Plan.

**Alternative considered:** Checking both the flag and a separate `legacy_identity_migrated` flag. Rejected — adds complexity for a one-time migration and the re-onboarding experience is acceptable given the early stage of the app.

### 3. New `_MastodonStep` inserted between Identity and Discovery

**Decision:** Add `mastodon` to the `_OnboardingStep` enum. The step renders a single handle input (reusing the same validation from `MastodonBridgeService.validateHandle`). On "Continue", the handle is written to `SecureStorageService`. The step is skippable with a "Skip for now" link. Advancing from this step goes directly to `discovery`.

**Why a dedicated step rather than elevating the existing Discovery sub-screen?** The Discovery step currently presents a choice between Mastodon import and username search. Elevating Mastodon to its own step makes the value proposition clearer ("bring your network with you") and keeps Discovery focused on the search/follow UX.

**Why not replace Discovery entirely?** Discovery (find by username, mDNS) remains useful and distinct from account linking. They serve different goals: Mastodon step = link your existing identity; Discovery step = find people on the Nightingale network.

### 4. Mastodon handle stored in SecureStorageService

**Decision:** Add `nightingale_mastodon_handle` key to `SecureStorageService` with `getMastodonHandle()` / `setMastodonHandle(String)` / `clearMastodonHandle()`. Expose via a new `mastodonAccountProvider` (`FutureProvider<String?>`) that reads from the service.

**Why SecureStorage and not SharedPreferences?** The handle is not sensitive on its own, but keeping all user-identity-related data in one place (SecureStorage) is consistent with existing patterns and avoids introducing a second storage dependency.

**Why a `FutureProvider` rather than a `StateProvider`?** The handle is read from async storage; `FutureProvider` is the correct primitive. Mutating it goes through `SecureStorageService` directly (same pattern used by `onboardingProvider`); consumers that need to react to changes can `ref.invalidate(mastodonAccountProvider)` after a write.

## Risks / Trade-offs

- **Re-onboarding existing users** — users with a node identity but no onboarding flag will go through the flow again, including the identity step which regenerates keys. This changes their actor URL (new LAN IP resolution, new keypair). Followers from the old identity will not carry over automatically. Acceptable at current stage; noted for Phase 7 identity migration work.

- **Skipping the Mastodon step** — users who skip will have no stored handle; `mastodonAccountProvider` returns `null`. All services consuming the provider must handle the null case gracefully.

- **Handle change after onboarding** — no UI is provided in this change to update the stored Mastodon handle post-onboarding. A settings screen for this is out of scope but should be tracked for a follow-up.

## Migration Plan

1. On update, the `nightingale_onboarding_complete` flag is absent for users who used the old `IdentitySetupScreen` path.
2. On next launch, `OnboardingNotifier` reads the flag as `false` → emits `OnboardingRequired`.
3. The router redirect (now wired via `refreshListenable`) sends the user to `/onboarding`.
4. The user goes through the full flow; the Identity step re-creates their identity (new keypair, new actor URL).
5. At completion, `completeOnboarding()` sets the flag; they are not shown onboarding again.

No database migrations are required. No rollback mechanism is needed — this is a client-side onboarding gate.

## Open Questions

- Should the Mastodon step pre-fill the handle and immediately trigger the social graph import (as the current Discovery step does), or should it only collect and store, deferring import to the Discovery step? Current design: collect-and-store only in the Mastodon step; the Discovery step retains the import UI and pre-fills the stored handle. This keeps responsibilities clean.
- Should `createIdentity` be made explicitly idempotent (no-op if identity already exists) to protect against accidental re-onboarding data loss? Recommended as a follow-up; out of scope for this change.
