## ADDED Requirements

### Requirement: Now Playing screen
The system SHALL provide a full-screen Now Playing view displaying: album artwork (large, dominant), track title, artist name, album name, a playback scrubber with current position and total duration, and transport controls (previous, play/pause, next). Shuffle and repeat mode toggles SHALL also be accessible on this screen.

#### Scenario: Artwork display
- **WHEN** a track with embedded artwork is playing
- **THEN** the artwork is displayed full-width at the top of the Now Playing screen; it transitions smoothly when the track changes

#### Scenario: Track without artwork
- **WHEN** a track has no embedded artwork
- **THEN** a styled placeholder (typographic or geometric, consistent with the design system) is displayed instead of a blank space

#### Scenario: Scrubber interaction
- **WHEN** the user drags the scrubber
- **THEN** the position label updates in real time during the drag; playback seeks to the released position

#### Scenario: Typographic hierarchy
- **WHEN** the Now Playing screen is rendered
- **THEN** track title is the largest text element; artist name is secondary; album name is tertiary; the layout reads correctly before any color or iconography is applied

---

### Requirement: Persistent mini player
The system SHALL display a mini player bar that persists across all screens via a global shell widget. The mini player SHALL show: a small artwork thumbnail, track title, artist name, and a play/pause button. Tapping the mini player SHALL navigate to the full Now Playing screen.

#### Scenario: Mini player visible on all routes
- **WHEN** a track is in the queue (playing or paused)
- **THEN** the mini player is visible at the bottom of every screen, regardless of the current route

#### Scenario: Mini player hidden when queue is empty
- **WHEN** no track is loaded in the queue
- **THEN** the mini player is not visible; no empty bar or placeholder is shown

#### Scenario: Navigate to Now Playing
- **WHEN** the user taps the mini player
- **THEN** the full Now Playing screen is presented without replacing the current navigation stack

#### Scenario: Mini player does not obstruct content
- **WHEN** the mini player is visible
- **THEN** the page below it has sufficient bottom padding so that list items and controls are not hidden behind the mini player bar

---

### Requirement: Queue view
The system SHALL provide a Queue screen showing the upcoming tracks in order, with the ability to reorder tracks by drag and remove individual tracks by swipe or button.

#### Scenario: View queue
- **WHEN** the user opens the Queue screen
- **THEN** the current track is highlighted at the top; subsequent tracks are listed in playback order

#### Scenario: Reorder by drag
- **WHEN** the user long-presses and drags a track to a new position
- **THEN** the queue order updates in real time during the drag and is committed on release

#### Scenario: Remove track from queue
- **WHEN** the user swipes a track off the queue list or taps a remove button
- **THEN** the track is removed from the queue immediately; if it was the currently playing track, playback advances to the next

---

### Requirement: Album detail screen
The system SHALL provide an Album detail screen showing: album artwork, album name, artist name, release year (if available), and a scrollable track list with track number, title, and duration. The user SHALL be able to play the full album or tap an individual track to start playback from that position.

#### Scenario: Play album
- **WHEN** the user taps "Play Album" on the Album detail screen
- **THEN** the album's tracks replace the current queue and playback starts from track 1

#### Scenario: Play from track
- **WHEN** the user taps a specific track in the album track list
- **THEN** the album's tracks replace the current queue and playback starts from the selected track

---

### Requirement: Artist detail screen
The system SHALL provide an Artist detail screen showing the artist name, a list of the artist's albums (each linking to the Album detail screen), and an option to play all tracks by that artist.

#### Scenario: Navigate to artist
- **WHEN** the user taps an artist name anywhere in the app
- **THEN** they are taken to the Artist detail screen for that artist

#### Scenario: Play all by artist
- **WHEN** the user taps "Play All" on the Artist detail screen
- **THEN** all tracks by that artist are loaded into the queue and playback begins

---

### Requirement: Local library search
The system SHALL provide a search interface that queries the local library across track title, artist name, album name, and genre, returning results as the user types.

#### Scenario: Real-time search
- **WHEN** the user types into the search field
- **THEN** results update within 150ms showing matching tracks, albums, and artists

#### Scenario: No results
- **WHEN** a search query produces no matches
- **THEN** a purposeful "no results" empty state is shown (not a blank screen)

#### Scenario: Search clears on dismiss
- **WHEN** the user dismisses the search screen
- **THEN** the search query is cleared and the library view returns to its previous state

---

### Requirement: Network-state components in player UI
The system SHALL use the Phase 1 network-state primitive components (buffering, host-offline, stream-failed-playing-local) in the player UI wherever a remote audio source may be active, so that the vocabulary for communicating uncertainty is consistent from day one.

#### Scenario: Buffering indicator on remote source
- **WHEN** a `RemoteAudioSource` is buffering
- **THEN** the Phase 1 buffering component is displayed in the Now Playing screen's controls area, not a custom spinner

#### Scenario: Host offline fallback
- **WHEN** a remote host becomes unreachable during playback
- **THEN** the Phase 1 host-offline component is surfaced in the Now Playing screen; playback falls back to cache or local copy if available

---

### Requirement: Design system compliance
All player UI screens SHALL use Phase 1 design tokens (typography scale, color palette, spacing grid, motion constants). No hardcoded colors, font sizes, or spacing values.

#### Scenario: Dark mode
- **WHEN** the device is in dark mode
- **THEN** all player UI screens render correctly using the dark mode token set with no visible artifacts or clipped text

#### Scenario: Whitespace rhythm
- **WHEN** any player screen is rendered
- **THEN** spacing between elements uses the Phase 1 spacing grid tokens; no two adjacent elements are closer than the minimum grid unit
