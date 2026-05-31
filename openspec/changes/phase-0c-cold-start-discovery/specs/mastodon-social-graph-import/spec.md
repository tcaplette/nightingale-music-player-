## ADDED Requirements

### Requirement: Mastodon handle entry and resolution
The app SHALL accept a Mastodon handle in `@username@instance` format and resolve it to a Mastodon actor object via WebFinger, using the existing `ActorResolver` WebFinger path.

#### Scenario: Valid handle resolves successfully
- **WHEN** the user enters a valid Mastodon handle (e.g. `@howard@mastodon.social`)
- **THEN** the app resolves the handle via WebFinger and retrieves the Mastodon actor object

#### Scenario: Invalid handle format is rejected inline
- **WHEN** the user enters a string that does not match `@username@instance` format
- **THEN** the app displays an inline validation error and does not attempt resolution

#### Scenario: Unreachable Mastodon instance
- **WHEN** WebFinger resolution fails due to network error or non-existent instance
- **THEN** the app displays a non-blocking error message and allows retry without losing the entered handle

---

### Requirement: Followers and following collection fetch
After resolving the user's Mastodon actor, the app SHALL fetch the actor's `followers` and `following` ActivityPub collections and retrieve up to 200 items per collection.

#### Scenario: Collections fetched successfully
- **WHEN** the Mastodon actor object is resolved
- **THEN** the app fetches the `followers` and `following` collection URLs from the actor object and paginates through results up to 200 items per collection

#### Scenario: Collection access restricted by instance policy
- **WHEN** the `followers` or `following` collection returns HTTP 401 or 403
- **THEN** the app continues with whatever collections it could fetch and surfaces results from accessible collections only, without an error state

#### Scenario: Empty collection
- **WHEN** a collection returns zero items
- **THEN** the app treats this as a valid result and proceeds to the match phase with an empty set for that collection

---

### Requirement: Nightingale actor detection via `x-nightingale-actor-url`
For each actor in the fetched collections, the app SHALL check for the presence of an `x-nightingale-actor-url` field in the actor object. If present, the value is treated as the Nightingale actor URL for that contact.

#### Scenario: Extension field present on Mastodon actor
- **WHEN** a Mastodon actor object contains a top-level `x-nightingale-actor-url` field with a valid HTTPS URL
- **THEN** the app records the mapping from that Mastodon actor's URL to the Nightingale actor URL

#### Scenario: Extension field absent
- **WHEN** a Mastodon actor object does not contain `x-nightingale-actor-url`
- **THEN** the app skips that actor silently; no error is surfaced

#### Scenario: Extension field contains malformed URL
- **WHEN** the `x-nightingale-actor-url` value is not a valid HTTPS URL
- **THEN** the app ignores the field and does not attempt to resolve it

---

### Requirement: Suggested follows surface
The app SHALL surface all discovered Nightingale actors as a deduplicated list of suggested follows, showing each person's display name and avatar (not their raw handle), with a "Follow all" action and individual per-person follow controls.

#### Scenario: Matches found
- **WHEN** the Mastodon import process finds one or more Nightingale actors
- **THEN** the app displays each match as a person card (name, avatar) with an individual follow button and a "Follow all" button

#### Scenario: No matches found
- **WHEN** the Mastodon import process finds zero Nightingale actors in the user's connections
- **THEN** the app displays an encouraging empty state ("None of your Mastodon connections are on Nightingale yet") with a prompt to share the app

#### Scenario: "Follow all" action
- **WHEN** the user taps "Follow all"
- **THEN** the app sends a `Follow` activity to every listed Nightingale actor's inbox in sequence and updates each card to a "Following" state

#### Scenario: Individual follow action
- **WHEN** the user taps the follow button on a single suggested contact
- **THEN** the app sends a `Follow` activity to that actor's inbox and updates that card to "Following" state

---

### Requirement: Mastodon import is optional and non-blocking
The Mastodon import flow SHALL be entirely optional. The user can dismiss or skip it at any point without affecting any other app functionality.

#### Scenario: User skips import
- **WHEN** the user dismisses or skips the Mastodon import screen
- **THEN** no network requests are made to any Mastodon instance and the app proceeds normally

#### Scenario: Import can be re-triggered after onboarding
- **WHEN** the user navigates to the Find People screen after onboarding
- **THEN** the Mastodon import option is accessible and functions identically to the onboarding path
