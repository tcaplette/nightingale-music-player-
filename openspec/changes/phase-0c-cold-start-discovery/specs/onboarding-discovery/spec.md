## ADDED Requirements

### Requirement: Discovery step shown once after identity setup
The onboarding flow SHALL include a discovery step that is presented exactly once, immediately after node identity setup is complete.

#### Scenario: Discovery step shown on first launch
- **WHEN** the user completes node identity setup for the first time
- **THEN** the app navigates to the discovery step before entering the main app

#### Scenario: Discovery step not shown on subsequent launches
- **WHEN** the user has previously completed or skipped the discovery step
- **THEN** the app does not show the discovery step again on subsequent launches and navigates directly to the main app

---

### Requirement: Mastodon import as primary discovery path
The discovery step SHALL present Mastodon social graph import as the primary call to action, with a prominent "Connect your Mastodon account" entry point.

#### Scenario: Mastodon import initiated from onboarding
- **WHEN** the user taps the Mastodon import CTA in the discovery step
- **THEN** the app presents the Mastodon handle entry flow as defined in the `mastodon-social-graph-import` spec

#### Scenario: Mastodon import completes during onboarding
- **WHEN** the user completes a Mastodon import (even with zero matches)
- **THEN** the app marks the discovery step as complete and navigates to the main app

---

### Requirement: Username search as secondary discovery path
The discovery step SHALL provide a secondary option to search for a specific person by username (WebFinger handle or actor URL).

#### Scenario: Username search initiated from onboarding
- **WHEN** the user taps the "Find by username" option in the discovery step
- **THEN** the app presents a handle/URL input field and resolves it via `ActorResolver` on submission

#### Scenario: Successful username resolution in onboarding
- **WHEN** the resolved actor is a valid Nightingale node
- **THEN** the app presents the actor as a single suggested follow card with a follow button; following completes and marks the discovery step as done

#### Scenario: Failed username resolution in onboarding
- **WHEN** the handle cannot be resolved (not found, network error)
- **THEN** the app displays an inline error and allows the user to retry or skip

---

### Requirement: Discovery step is skippable
The discovery step SHALL provide a clearly visible skip action. Skipping immediately marks the step as complete and navigates to the main app.

#### Scenario: User skips discovery
- **WHEN** the user taps "Skip" on the discovery step
- **THEN** the app marks the step as complete, makes no network requests related to discovery, and navigates to the main app

---

### Requirement: Discovery re-entry from Find People screen
After onboarding, the full discovery surface (Mastodon import and username search) SHALL remain accessible from the Find People screen so users can run the import at any time.

#### Scenario: Post-onboarding Mastodon import
- **WHEN** the user navigates to the Find People screen and taps "Connect Mastodon"
- **THEN** the Mastodon handle entry flow runs exactly as it does during onboarding

#### Scenario: Post-onboarding username search
- **WHEN** the user navigates to the Find People screen and searches by username
- **THEN** the handle is resolved and presented as a suggested follow card

---

### Requirement: Empty main app state prompts discovery
If the user enters the main app with zero follows (having skipped or completed onboarding with no connections made), the app SHALL surface a persistent but non-intrusive prompt to find people.

#### Scenario: Empty social graph on first app entry
- **WHEN** the user enters the main app after onboarding with zero follows
- **THEN** a non-blocking banner or empty-state card is shown in the social feed directing the user to the Find People screen
