## 1. Remove Dead Code

- [x] 1.1 Delete `lib/features/node_identity/screens/identity_setup_screen.dart`
- [x] 1.2 Verify no import or reference to `IdentitySetupScreen` remains in the codebase (grep for `IdentitySetupScreen`)

## 2. Fix OnboardingNotifier Migration Bypass

- [x] 2.1 In `lib/features/onboarding/onboarding_notifier.dart`, remove the `if (identityState is NodeIdentityReady)` block that auto-sets `onboarding_complete` and emits `OnboardingComplete`
- [x] 2.2 Simplify `_check()` so it reads only `storage.getOnboardingComplete()` and emits `OnboardingComplete` or `OnboardingRequired` based solely on that flag

## 3. Wire Router refreshListenable

- [x] 3.1 Create `lib/core/router/router_refresh_notifier.dart` — a `ChangeNotifier` that takes a `Ref` (or `ProviderContainer`), listens to `onboardingProvider` and `nodeIdentityProvider` via `ref.listen`, and calls `notifyListeners()` on any state change
- [x] 3.2 In `lib/core/router/app_router.dart`, change `appRouter` from a top-level constant to a function `buildRouter(ProviderContainer container)` that instantiates `RouterRefreshNotifier` and passes it to `GoRouter(refreshListenable: ...)`
- [x] 3.3 In `lib/app.dart`, update `_AppBodyState` to call `buildRouter(ProviderScope.containerOf(context))` and hold the result, replacing the direct `appRouter` reference

## 4. Extend SecureStorageService for Mastodon Handle

- [x] 4.1 Add constant `_kMastodonHandleKey = 'nightingale_mastodon_handle'` to `lib/features/onboarding/secure_storage_service.dart`
- [x] 4.2 Add `getMastodonHandle()`, `setMastodonHandle(String handle)`, and `clearMastodonHandle()` to the `SecureStorageService` abstract interface
- [x] 4.3 Implement the three methods in `FlutterSecureStorageService`

## 5. Create mastodonAccountProvider

- [x] 5.1 Create `lib/features/onboarding/mastodon_account_provider.dart` with a `FutureProvider<String?>` named `mastodonAccountProvider` that reads `getMastodonHandle()` from `sl<SecureStorageService>()`

## 6. Add Mastodon Step to OnboardingShell

- [x] 6.1 In `lib/features/onboarding/screens/onboarding_shell.dart`, add `mastodon` to the `_OnboardingStep` enum between `identity` and `discovery`
- [x] 6.2 Update `_IdentityStep.onNext` to advance to `_OnboardingStep.mastodon` (was `migration`)
- [x] 6.3 Remove the `_MigrationStep` from `OnboardingShell` and delete its class — the migration story screen is no longer part of the flow
- [x] 6.4 Implement `_MastodonStep` as a `ConsumerStatefulWidget` with: a handle `TextEditingController`, inline validation using `MastodonBridgeService.validateHandle`, a "Continue" button that calls `sl<SecureStorageService>().setMastodonHandle(handle)` then `widget.onNext()`, and a "Skip for now" `TextButton` that calls `widget.onNext()` directly
- [x] 6.5 Wire `_MastodonStep` into the `switch` in `OnboardingShell.build`, advancing to `_OnboardingStep.discovery` on completion or skip
- [x] 6.6 Update `_DiscoveryStep` / `DiscoveryOnboardingStep` to read `mastodonAccountProvider` and pre-fill the handle field in `MastodonImportScreen` when a stored handle exists

## 7. Pre-fill MastodonImportScreen with Stored Handle

- [x] 7.1 Add an optional `initialHandle` parameter to `MastodonImportScreen`
- [x] 7.2 In `_MastodonImportScreenState.initState`, set `_controller.text = widget.initialHandle ?? ''` if provided
- [x] 7.3 In `DiscoveryOnboardingStep`, read `mastodonAccountProvider` and pass the resolved handle as `initialHandle` to `MastodonImportScreen`

## 8. Verification

- [ ] 8.1 Cold-start test: clear app data, launch — confirm the full 5-step onboarding flow appears immediately (welcome → identity → mastodon → discovery → complete)
- [ ] 8.2 Skip test: tap "Skip for now" on both Mastodon and Discovery steps — confirm onboarding completes and library loads
- [ ] 8.3 Handle persistence test: enter a valid handle in the Mastodon step, complete onboarding, re-launch — confirm `mastodonAccountProvider` returns the stored handle
- [ ] 8.4 Validation test: enter a malformed handle — confirm the error message appears and the user is not advanced
- [ ] 8.5 Router redirect test: confirm the app does not briefly flash the library before redirecting to onboarding on a fresh install
- [ ] 8.6 Re-onboarding test: existing identity with no flag — confirm onboarding is shown and completion sets the flag correctly
<!-- Manual device tests — to be verified by running the app -->
