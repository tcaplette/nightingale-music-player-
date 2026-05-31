## Why

New users open the app and are shown only a bare username prompt — the multi-step onboarding flow exists in code but never fires because the router has no mechanism to re-evaluate its redirect after asynchronous state changes, and a migration shortcut silently marks onboarding complete for any install that already has a node identity. This leaves users without the Mastodon connection step that is the designated answer to cold-start: a new user on a fresh network has no one to follow and nothing in their feed.

## What Changes

- **Fix router redirect trigger** — wire a `refreshListenable` to `appRouter` so the `GoRouter` redirect re-evaluates whenever `onboardingProvider` or `nodeIdentityProvider` state changes asynchronously
- **Remove dead code** — delete `IdentitySetupScreen` (`lib/features/node_identity/screens/identity_setup_screen.dart`), which is the old standalone username-only first-launch screen, now orphaned and unreachable
- **Fix migration bypass** — remove the `OnboardingNotifier` shortcut that auto-completes onboarding when `NodeIdentityReady` is detected; onboarding completion must be set explicitly by the user finishing the flow
- **Add Mastodon account step** — insert a dedicated Mastodon handle entry step into `OnboardingShell` between identity creation and discovery; the entered handle is validated, stored in `SecureStorageService`, and exposed via a Riverpod provider
- **Persist Mastodon handle** — extend `SecureStorageService` with `getMastodonHandle` / `setMastodonHandle` and create a `mastodonAccountProvider` so any service in the app can read the stored handle without re-prompting the user

## Capabilities

### New Capabilities

- `onboarding-flow`: Multi-step first-launch flow (welcome → identity → mastodon → discovery → complete) that fires reliably on first open, guards all main routes until complete, and cannot be bypassed by pre-existing identity state
- `mastodon-account`: Persistent storage and app-wide access to the user's Mastodon handle, collected during onboarding, validated against `@user@instance` format, and exposed via a Riverpod provider for use by federation and discovery services

### Modified Capabilities

<!-- No existing specs to modify -->

## Impact

- `lib/core/router/app_router.dart` — add `refreshListenable` wired to onboarding and identity providers
- `lib/features/onboarding/onboarding_notifier.dart` — remove migration bypass logic
- `lib/features/onboarding/screens/onboarding_shell.dart` — add `_MastodonStep` between identity and discovery steps; update `_OnboardingStep` enum
- `lib/features/onboarding/secure_storage_service.dart` — add `mastodon_handle` key and read/write methods
- `lib/features/node_identity/screens/identity_setup_screen.dart` — deleted
- New file: `lib/features/onboarding/mastodon_account_provider.dart` — Riverpod provider that reads the stored handle from `SecureStorageService`
