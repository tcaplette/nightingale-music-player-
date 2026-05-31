## ADDED Requirements

### Requirement: Onboarding fires on first open
The app SHALL redirect any user who has not completed onboarding to the onboarding flow immediately on launch, regardless of what route was requested.

#### Scenario: Fresh install with no identity and no onboarding flag
- **WHEN** the app is launched for the first time with no stored identity and no onboarding-complete flag
- **THEN** the user is redirected to `/onboarding` before any main-app route is shown

#### Scenario: Install with existing identity but no onboarding flag
- **WHEN** the app is launched and a node identity exists in the database but the onboarding-complete flag is absent in secure storage
- **THEN** the user is redirected to `/onboarding` before any main-app route is shown

#### Scenario: Completed onboarding
- **WHEN** the app is launched and the onboarding-complete flag is `true` in secure storage
- **THEN** the user proceeds directly to the library without seeing the onboarding flow

### Requirement: Router re-evaluates redirect after async state changes
The router SHALL re-run its redirect logic whenever onboarding state or identity state changes after the initial synchronous render.

#### Scenario: Onboarding state resolves to required after startup
- **WHEN** the app starts, the router initially renders with providers in their loading states, and then `onboardingProvider` resolves to `OnboardingRequired`
- **THEN** the router automatically redirects to `/onboarding` without requiring any user navigation action

#### Scenario: Onboarding completed mid-session
- **WHEN** the user completes the onboarding flow and `onboardingProvider` transitions to `OnboardingComplete`
- **THEN** the router automatically redirects to `/library`

### Requirement: Five-step onboarding sequence
The onboarding flow SHALL present steps in this exact order: welcome → identity → mastodon → discovery → complete. Each step SHALL be navigable only in forward order during onboarding.

#### Scenario: Full forward traversal
- **WHEN** a user taps through all steps without skipping
- **THEN** they see welcome, then identity name entry, then Mastodon handle entry, then discovery, then the completion screen, then are routed to the library

#### Scenario: Skipping the Mastodon step
- **WHEN** the user taps "Skip for now" on the Mastodon step
- **THEN** they advance to the discovery step with no handle stored and onboarding continues normally

#### Scenario: Skipping the discovery step
- **WHEN** the user taps "Skip for now" on the discovery step
- **THEN** they advance to the completion step and onboarding continues normally

### Requirement: Onboarding complete flag set only at end of flow
The onboarding-complete flag in secure storage SHALL only be written when the user explicitly reaches and dismisses the completion step. Detecting a pre-existing node identity SHALL NOT implicitly set the flag.

#### Scenario: User finishes the flow
- **WHEN** the user taps the primary action on the completion step
- **THEN** `setOnboardingComplete(true)` is called and the user is routed to the library

#### Scenario: User exits the app mid-onboarding
- **WHEN** the app is backgrounded or killed while the user is on any step before completion
- **THEN** on next launch the user is returned to `/onboarding` (step 1) and the flag remains unset

### Requirement: Dead standalone identity screen removed
The `IdentitySetupScreen` widget and its file SHALL not exist in the codebase.

#### Scenario: No route to standalone screen
- **WHEN** the app is built and all routes are enumerated
- **THEN** no route resolves to `IdentitySetupScreen`
