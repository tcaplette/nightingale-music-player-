## ADDED Requirements

### Requirement: Mastodon handle collected during onboarding
The onboarding flow SHALL include a dedicated step that prompts the user to enter their Mastodon handle in `@user@instance.social` format (or `user@instance.social`). The step SHALL be skippable.

#### Scenario: Valid handle entered
- **WHEN** the user enters a well-formed Mastodon handle (e.g. `@howard@mastodon.social`) and taps "Continue"
- **THEN** the handle is validated, stored in secure storage, and the user advances to the discovery step

#### Scenario: Handle without leading @
- **WHEN** the user enters `howard@mastodon.social` (no leading `@`) and taps "Continue"
- **THEN** the handle is accepted as valid, stored, and the user advances

#### Scenario: Malformed handle
- **WHEN** the user enters a string that does not match the `user@instance` pattern (e.g. `justausername` or `@noinstance`)
- **THEN** an inline validation error is shown and the user is not advanced

#### Scenario: Empty input and continue tapped
- **WHEN** the user taps "Continue" with an empty input field
- **THEN** an inline validation error is shown prompting the user to enter a handle or skip

#### Scenario: User skips the step
- **WHEN** the user taps "Skip for now"
- **THEN** no handle is stored and the user advances to the discovery step

### Requirement: Mastodon handle persisted in secure storage
The app SHALL store the validated Mastodon handle under a dedicated key in `SecureStorageService`. The stored value SHALL survive app restarts.

#### Scenario: Handle readable after app restart
- **WHEN** a handle was stored during onboarding and the app is restarted
- **THEN** `getMastodonHandle()` returns the previously stored handle

#### Scenario: No handle stored when step was skipped
- **WHEN** the Mastodon onboarding step was skipped
- **THEN** `getMastodonHandle()` returns `null`

### Requirement: Mastodon handle exposed via Riverpod provider
The app SHALL provide a `mastodonAccountProvider` that any Riverpod consumer can read to obtain the stored Mastodon handle without accessing `SecureStorageService` directly.

#### Scenario: Provider returns stored handle
- **WHEN** a handle is stored in secure storage
- **THEN** `mastodonAccountProvider` resolves to that handle string

#### Scenario: Provider returns null when no handle stored
- **WHEN** no handle has been stored (user skipped or fresh install)
- **THEN** `mastodonAccountProvider` resolves to `null`

#### Scenario: Provider reflects updated value after invalidation
- **WHEN** a new handle is written to `SecureStorageService` and `mastodonAccountProvider` is invalidated
- **THEN** the next read of the provider returns the new handle

### Requirement: Discovery step pre-fills stored handle
If a Mastodon handle is already stored, the Mastodon import screen within the discovery step SHALL pre-populate the handle input field with the stored value.

#### Scenario: Handle stored from onboarding step
- **WHEN** the user reaches the discovery step and a handle was entered in the Mastodon step
- **THEN** the handle input in the Mastodon import screen is pre-filled with the stored handle

#### Scenario: No handle stored
- **WHEN** the user reaches the discovery step having skipped the Mastodon step
- **THEN** the handle input in the Mastodon import screen is empty
