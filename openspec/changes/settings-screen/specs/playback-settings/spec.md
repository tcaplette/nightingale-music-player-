## ADDED Requirements

### Requirement: User can configure audio buffer size
The app SHALL provide a **Buffer Size** setting with three options: **Efficient**, **Normal**, and **Generous**. These SHALL map to `AndroidLoadControl` parameters as follows:

| Option    | minBuffer | maxBuffer | preRoll | afterRebuffer |
|-----------|-----------|-----------|---------|---------------|
| Efficient | 10 s      | 60 s      | 3 s     | 5 s           |
| Normal    | 15 s      | 120 s     | 5 s     | 8 s           |
| Generous  | 30 s      | 240 s     | 8 s     | 12 s          |

The selected value SHALL be persisted and applied the next time `PlaybackEngine` initialises (i.e. on next app launch). The default SHALL be **Normal** (matching current hardcoded values).

#### Scenario: Default buffer size is Normal
- **WHEN** the user opens Playback settings for the first time
- **THEN** the Buffer Size option shows Normal as selected

#### Scenario: Selecting a different buffer size persists the choice
- **WHEN** the user selects Efficient
- **THEN** the setting is saved and Efficient remains selected on next app open

#### Scenario: User is informed the change takes effect after restart
- **WHEN** the user changes the Buffer Size
- **THEN** a SnackBar informs them the change takes effect next time the app is opened

---

### Requirement: User can configure skip-previous threshold
The app SHALL provide a **Skip Previous Sensitivity** setting: the number of seconds into a track after which tapping "previous" seeks to the start rather than skipping to the previous track. Options: **1 s**, **3 s** (default), **5 s**, **10 s**.

#### Scenario: Default threshold is 3 seconds
- **WHEN** the user opens Playback settings for the first time
- **THEN** Skip Previous Sensitivity shows 3 s as selected

#### Scenario: Threshold change is applied immediately
- **WHEN** the user changes the threshold and plays a track
- **THEN** the new threshold governs the skip-previous behaviour immediately (no restart required)

---

### Requirement: User can configure audio focus behaviour
The app SHALL provide an **Audio Focus** setting controlling what happens when another app takes audio focus. Options: **Duck** (reduce volume to 50%), **Pause** (pause playback), **Do nothing**.

#### Scenario: Default is Duck
- **WHEN** the user opens Playback settings for the first time
- **THEN** Audio Focus shows Duck as selected

#### Scenario: Do nothing disables all focus interruption handling
- **WHEN** the user selects Do nothing and another app takes audio focus
- **THEN** Nightingale continues playing at full volume without interruption

#### Scenario: Audio focus setting is applied on next interruption
- **WHEN** the user changes the setting while a track is playing
- **THEN** the next interruption event uses the new behaviour
