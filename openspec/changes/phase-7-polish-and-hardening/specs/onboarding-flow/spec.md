## ADDED Requirements

### Requirement: Onboarding guard prevents access to main app until setup is complete
A `OnboardingGuard` integrated with go_router SHALL redirect all navigation attempts to the onboarding shell when `onboardingComplete` is unset in secure storage. The guard SHALL resolve synchronously from a cached value after first read; the initial read SHALL complete before the first route is rendered.

#### Scenario: Fresh install navigates to onboarding
- **WHEN** the app launches for the first time with no `onboardingComplete` flag in secure storage
- **THEN** all routes SHALL redirect to the onboarding shell
- **THEN** the user SHALL NOT be able to navigate to any main app screen by deep link, back gesture, or direct route push

#### Scenario: Returning user bypasses onboarding
- **WHEN** the app launches and `onboardingComplete` is `true` in secure storage
- **THEN** the onboarding guard SHALL pass through and route normally
- **THEN** the onboarding shell SHALL NOT render at all

### Requirement: Onboarding presents identity creation without technical vocabulary
The onboarding flow SHALL complete node identity generation (Ed25519 key pair, actor object, WebFinger endpoint) in the background without showing any raw ActivityPub handle, public key, cryptographic term, or protocol URL to the user. The user SHALL experience a "your music space is ready" narrative, not a "your federated node has been provisioned" narrative.

#### Scenario: Identity generated silently during onboarding
- **WHEN** the user advances past the welcome screen
- **THEN** the app SHALL generate the Ed25519 key pair in the background
- **THEN** the onboarding screen SHALL show a friendly progress state (e.g., "Setting up your space…")
- **THEN** no key material, actor URL, or `@user@node` handle SHALL appear in the UI

#### Scenario: Identity generation failure handled gracefully
- **WHEN** key pair generation fails (e.g., secure enclave unavailable)
- **THEN** the onboarding screen SHALL show a user-friendly error with a retry action
- **THEN** no cryptographic error message or stack trace SHALL be shown to the user

### Requirement: Onboarding surfaces the key-migration story without technical complexity
The onboarding flow SHALL include a screen explaining that the user's music identity can travel with them to a new device, framed in plain language ("Take your music identity with you"). It SHALL offer a "Back up my identity" action that initiates the Phase 3 `Move` activity migration flow. This screen SHALL be skippable.

#### Scenario: Migration story screen displayed
- **WHEN** the user reaches the identity backup screen during onboarding
- **THEN** the screen SHALL describe device migration in plain language with no mention of keys, actors, or ActivityPub
- **THEN** a primary CTA ("Back up") and a secondary skip option SHALL both be present

#### Scenario: User skips migration during onboarding
- **WHEN** the user taps "Skip" on the migration screen
- **THEN** onboarding SHALL proceed to the next screen
- **THEN** the `onboardingComplete` flag SHALL still be set on completion
- **THEN** the user SHALL be able to initiate backup later from Settings

### Requirement: Onboarding completes by writing a durable flag and routing to the main app
When the final onboarding screen is dismissed, the app SHALL write `onboardingComplete = true` to secure storage before transitioning to the main app. The transition SHALL use a purposeful fade animation, not an abrupt cut.

#### Scenario: Onboarding completion routes to home
- **WHEN** the user completes all onboarding steps
- **THEN** `onboardingComplete` SHALL be written to secure storage
- **THEN** the app SHALL navigate to the home route with a fade transition
- **THEN** tapping back from home SHALL NOT return to onboarding

### Requirement: Onboarding flow is fully testable in isolation
The `OnboardingGuard` and each onboarding screen SHALL be independently widget-testable with a mock `SecureStorageService`. The guard logic SHALL be pure Riverpod state, not embedded in router configuration.

#### Scenario: Guard tested with mock storage
- **WHEN** a widget test provides a mock `SecureStorageService` returning `onboardingComplete = false`
- **THEN** the guard SHALL redirect to the onboarding shell route
- **WHEN** the mock returns `onboardingComplete = true`
- **THEN** the guard SHALL pass through to the requested route
