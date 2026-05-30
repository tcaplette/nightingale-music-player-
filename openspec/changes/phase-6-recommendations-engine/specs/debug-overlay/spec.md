## ADDED Requirements

### Requirement: Phase 6 tabs added to debug overlay
The existing in-app debug overlay SHALL be extended with three new tabs for Phase 6: "Rec Engine" (recommendation engine inspector), "Signals" (signal event log), and "Affinity" (taste affinity matrix viewer). These tabs SHALL be added in the same tab bar as the existing Phase 2–5 tabs.

#### Scenario: Phase 6 tabs appear in dev overlay tab bar
- **WHEN** the developer opens the debug overlay in a dev build
- **THEN** the tab bar includes "Rec Engine", "Signals", and "Affinity" tabs alongside the existing phase tabs

#### Scenario: Phase 6 tabs absent in release build
- **WHEN** the app is built in release mode
- **THEN** the Phase 6 debug tabs are entirely absent; the release build contains no reference to them
