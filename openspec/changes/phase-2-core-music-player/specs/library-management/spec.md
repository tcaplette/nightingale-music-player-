## ADDED Requirements

### Requirement: Device library scanning
The system SHALL scan device storage for audio files using the OS media store (Android `MediaStore`, iOS `MPMediaQuery`) and fall back to direct filesystem/tag reading for files not indexed by the OS scanner.

#### Scenario: Initial scan on first launch
- **WHEN** the app is launched for the first time
- **THEN** the system performs a full library scan and populates the local database with all discovered audio files

#### Scenario: Media store fallback
- **WHEN** an audio file exists on device but is not indexed in the OS media store
- **THEN** the system SHALL attempt to read its metadata directly from the file's tags and include it in the library

#### Scenario: Unsupported or corrupt file
- **WHEN** a file is discovered that cannot be parsed (corrupt tags, unsupported format)
- **THEN** the system SHALL skip that file, log a parse error to the library scan log, and continue scanning

---

### Requirement: Metadata tag parsing
The system SHALL parse the following ID3/metadata fields from each audio file: title, artist, album, album artist, artwork (cover image), duration, track number, disc number, genre, and release year.

#### Scenario: Partial metadata
- **WHEN** a file is missing some metadata fields (e.g. no artwork, no genre)
- **THEN** the system SHALL store the available fields and use sensible defaults for missing ones (e.g. "Unknown Artist", "Unknown Album")

#### Scenario: Embedded artwork
- **WHEN** a file contains embedded album artwork
- **THEN** the system SHALL extract and persist the artwork as a file path reference in the database (not as a binary blob)

---

### Requirement: Local library database
The system SHALL persist the scanned library in an unencrypted Drift/SQLite database. The database SHALL be unencrypted by deliberate design — the music catalog is not sensitive data.

#### Scenario: Library persists across app launches
- **WHEN** the app is relaunched after a successful scan
- **THEN** the library is immediately available from the database without requiring a rescan

#### Scenario: Schema migration
- **WHEN** the app is updated and the database schema version changes
- **THEN** the system SHALL run the registered Drift migration and preserve all existing library data

---

### Requirement: Library views
The system SHALL expose the scanned library through four views: All Songs (flat list sorted by title), Albums (grouped by album), Artists (grouped by artist), and Genres (grouped by genre).

#### Scenario: All Songs view
- **WHEN** the user navigates to the All Songs view
- **THEN** the system displays all tracks sorted alphabetically by title

#### Scenario: Albums view
- **WHEN** the user navigates to the Albums view
- **THEN** the system displays albums sorted alphabetically, each showing artwork, album name, and artist name

#### Scenario: Empty library
- **WHEN** no audio files are found on the device
- **THEN** each library view displays a purposeful empty state (on-brand, not a blank screen)

---

### Requirement: Manual library refresh
The system SHALL allow the user to manually trigger a library rescan at any time.

#### Scenario: Manual refresh triggered
- **WHEN** the user initiates a manual library refresh
- **THEN** the system re-queries the OS media store, diffs against the stored library, adds new tracks, removes deleted tracks, and updates changed metadata

#### Scenario: Refresh progress feedback
- **WHEN** a library scan is in progress
- **THEN** the system SHALL display a scan progress indicator in the UI and log scan activity to the library scan log (dev builds)

---

### Requirement: Automatic change detection
The system SHALL automatically detect library changes when the app is foregrounded after being backgrounded.

#### Scenario: App foregrounded after new file added
- **WHEN** the user adds an audio file to their device and then foregrounds the app
- **THEN** the system SHALL detect the new file on the next app-resume scan and add it to the library

#### Scenario: Media store indexing delay
- **WHEN** a newly added file has not yet been indexed by the OS media store
- **THEN** the system SHALL surface a "Library may be incomplete" state using the Phase 1 partial-library UI component, and the manual refresh option SHALL remain available
