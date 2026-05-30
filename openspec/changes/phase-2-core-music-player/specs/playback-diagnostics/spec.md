## ADDED Requirements

### Requirement: Playback diagnostics overlay tab
The system SHALL add a "Playback" tab to the Phase 1 debug overlay. This tab SHALL display, in real time: current queue state (track list with positions), buffer status (buffered duration, buffer health), audio session state (active/interrupted/ducked), active audio format (codec, bit rate, sample rate), and stream source type for the current track (local vs. remote node URI). This tab SHALL only exist in debug/dev builds and SHALL be compile-time gated — it MUST NOT appear in release builds.

#### Scenario: Tab visible in dev build
- **WHEN** a developer opens the debug overlay in a dev build
- **THEN** a "Playback" tab is present and displays current playback engine state

#### Scenario: Tab absent in release build
- **WHEN** the app is compiled in release mode
- **THEN** no playback diagnostics tab exists; the overlay infrastructure itself is stripped at compile time

#### Scenario: Real-time queue state
- **WHEN** the queue changes (track added, removed, or reordered)
- **THEN** the queue state in the Playback tab updates immediately without requiring a manual refresh

#### Scenario: Buffer status display
- **WHEN** a track is playing
- **THEN** the Playback tab shows the current buffer duration in seconds and a health indicator (e.g. healthy / low / empty)

#### Scenario: Stream source display
- **WHEN** a track is playing from a local file
- **THEN** the stream source field shows "local" and the file path; when playing from a remote source it shows "remote" and the node URI

---

### Requirement: Library scan log overlay tab
The system SHALL add a "Library Scan" tab to the Phase 1 debug overlay. This tab SHALL display a timestamped log of the most recent library scan, including: total files found, files successfully parsed, files rejected (with per-file reason), parse errors (file path + error message), and total scan duration. This tab SHALL only exist in debug/dev builds and SHALL be compile-time gated.

#### Scenario: Scan log populated after scan
- **WHEN** a library scan completes in a dev build
- **THEN** the Library Scan tab shows the full results of that scan including counts and any errors

#### Scenario: Per-file parse error
- **WHEN** a file fails to parse during a scan
- **THEN** the Library Scan tab records that file's path and the reason for rejection (corrupt tags, unsupported format, permission denied, etc.)

#### Scenario: Log cleared on new scan
- **WHEN** a new library scan begins
- **THEN** the Library Scan tab clears the previous scan log and shows a "scanning…" state until the new scan completes

#### Scenario: Tab absent in release build
- **WHEN** the app is compiled in release mode
- **THEN** no Library Scan tab exists and no scan log data is collected or stored

---

### Requirement: Debug overlay activation unchanged
The Phase 2 debug additions SHALL use the existing Phase 1 debug overlay activation mechanism (dev-build-only entry point). No new activation gesture or entry point SHALL be introduced. The overlay SHALL never be activated by a shake gesture.

#### Scenario: New tabs accessible via existing entry point
- **WHEN** a developer opens the debug overlay through the Phase 1 dev entry point
- **THEN** the Playback and Library Scan tabs are accessible within the existing overlay UI without any additional activation step

#### Scenario: No shake gesture
- **WHEN** the user shakes the device in either dev or release builds
- **THEN** no debug overlay is triggered; shake is reserved for platform accessibility and system undo functions
