## ADDED Requirements

### Requirement: Unified AudioSource abstraction
The system SHALL model all audio sources — local files and remote streams — through a sealed `AudioSource` type with two concrete subtypes: `LocalAudioSource` (file path) and `RemoteAudioSource` (URI with best-effort semantics). The `PlaybackEngine` SHALL operate exclusively on `AudioSource` and SHALL NOT branch on source type in transport logic.

#### Scenario: Local file source
- **WHEN** a track from the local library is queued for playback
- **THEN** it is wrapped in a `LocalAudioSource` and the engine resolves it to a file URI without network access

#### Scenario: Remote source (stub in Phase 2)
- **WHEN** a `RemoteAudioSource` is present in the queue
- **THEN** the engine SHALL treat it as best-effort: attempt to connect, and surface a stream-failed state via the Phase 1 network-state component if unreachable (Phase 2 UI will not produce remote sources; this path is tested by type but not exercised end-to-end until Phase 4)

---

### Requirement: Core playback controls
The system SHALL support the following transport controls: play, pause, stop, skip to next, skip to previous, seek to position.

#### Scenario: Play/pause toggle
- **WHEN** the user taps the play/pause control
- **THEN** playback toggles between playing and paused without interrupting the queue

#### Scenario: Seek
- **WHEN** the user drags the playback scrubber to a new position
- **THEN** playback resumes from that position within 300ms

#### Scenario: Skip to next at end of queue
- **WHEN** the user skips forward at the last track in the queue and repeat mode is off
- **THEN** playback stops and the queue position remains at the last track

---

### Requirement: Queue management
The system SHALL maintain a playback queue supporting: enqueue (append), play next (insert at current + 1), remove by position, reorder by drag, and clear all.

#### Scenario: Enqueue track
- **WHEN** the user adds a track to the queue
- **THEN** the track appears at the end of the queue and plays when its turn arrives

#### Scenario: Reorder queue
- **WHEN** the user drags a track to a new position in the queue view
- **THEN** the queue order updates immediately and playback order reflects the change

#### Scenario: Remove currently playing track from queue
- **WHEN** the user removes the currently playing track from the queue
- **THEN** playback advances to the next track seamlessly

---

### Requirement: Shuffle and repeat modes
The system SHALL support shuffle (on/off) and repeat modes (off, repeat one, repeat all).

#### Scenario: Shuffle on
- **WHEN** the user enables shuffle
- **THEN** the queue is presented in a randomised order; the currently playing track remains current

#### Scenario: Repeat one
- **WHEN** repeat-one mode is active and the current track ends
- **THEN** the same track restarts from the beginning

#### Scenario: Repeat all
- **WHEN** repeat-all mode is active and the last track in the queue ends
- **THEN** playback wraps to the first track in the queue

---

### Requirement: Background playback and system media session
The system SHALL continue audio playback when the app is backgrounded. The system SHALL register a system media session that exposes playback controls on the lock screen, notification shade, and connected accessories (headphones, CarPlay/Android Auto).

#### Scenario: App backgrounded during playback
- **WHEN** the user presses the home button while music is playing
- **THEN** playback continues without interruption

#### Scenario: Lock screen controls
- **WHEN** the device is locked and music is playing
- **THEN** the lock screen displays track title, artist, album artwork, and play/pause/skip controls that correctly control playback

#### Scenario: Notification controls (Android)
- **WHEN** music is playing on Android
- **THEN** a media notification is visible in the notification shade with play/pause/skip controls

---

### Requirement: Gapless playback
The system SHALL play consecutive tracks in the queue without an audible gap between them.

#### Scenario: Track boundary
- **WHEN** one track ends and the next begins
- **THEN** there is no audible silence or click at the transition

---

### Requirement: Audio focus handling
The system SHALL respond to audio focus changes according to platform conventions: pause on incoming phone call; duck (reduce volume) when a notification sound plays; resume on focus regain.

#### Scenario: Incoming call
- **WHEN** an incoming phone call interrupts audio focus
- **THEN** playback pauses immediately; playback resumes when the call ends and focus is returned

#### Scenario: Notification sound
- **WHEN** a notification causes a transient audio focus loss
- **THEN** playback volume ducks for the duration of the notification and returns to normal volume when focus is restored

---

### Requirement: Playback state exposure
The system SHALL expose a reactive playback state (via Riverpod provider) containing: playing/paused/stopped status, current track, current position, total duration, buffer status, shuffle mode, repeat mode, and stream source type (local vs. remote).

#### Scenario: Position updates
- **WHEN** a track is playing
- **THEN** the current position in the playback state updates at least once per second

#### Scenario: Buffer status
- **WHEN** a remote source is buffering (Phase 4 path)
- **THEN** the buffer status in the state reflects the buffered duration, and the Phase 1 buffering UI component is triggered
