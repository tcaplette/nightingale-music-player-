## ADDED Requirements

### Requirement: Long-press opens metadata editor bottom sheet
A long-press gesture on any track tile that has a red metadata badge SHALL open a bottom sheet presenting only the missing required fields for that track. The bottom sheet SHALL not display fields that are already populated.

#### Scenario: Long-press on incomplete shared track
- **WHEN** the user long-presses a track tile with a red badge
- **THEN** a bottom sheet opens showing a labelled text input for each missing required field

#### Scenario: Long-press on complete shared track
- **WHEN** the user long-presses a track tile with a green badge
- **THEN** the bottom sheet opens showing all 7 required fields in read-only or editable form (no red-dot prompt needed, but editing remains accessible)

#### Scenario: Long-press on unshared track
- **WHEN** the user long-presses a track tile with no badge
- **THEN** existing long-press behaviour (if any) is unchanged; the metadata editor is NOT triggered

---

### Requirement: Metadata editor writes to physical file tags
On save, the metadata editor SHALL write the entered values to the physical audio file using `metadata_god`. The editor SHALL support MP3 (ID3v2) and FLAC (Vorbis Comments) formats. For unsupported formats, the editor SHALL surface an error and make no changes.

#### Scenario: Successful tag write — MP3
- **WHEN** the user fills in missing fields and taps Save on an MP3 file
- **THEN** `metadata_god` writes the values to the file's ID3v2 tags
- **AND** the local database record is updated to match
- **AND** the track tile badge transitions to green if all required fields are now complete

#### Scenario: Successful tag write — FLAC
- **WHEN** the user fills in missing fields and taps Save on a FLAC file
- **THEN** `metadata_god` writes the values to the file's Vorbis Comments
- **AND** the local database record is updated to match

#### Scenario: Unsupported format
- **WHEN** the user taps Save and the file format is not supported by `metadata_god` for writing
- **THEN** the editor displays an inline error: "Cannot edit tags for this file format"
- **AND** no changes are made to the file or the database

#### Scenario: File write permission denied
- **WHEN** the user taps Save and the system cannot write to the file (read-only storage, permission denied)
- **THEN** the editor displays an inline error: "Cannot write to this file — check storage permissions"
- **AND** no changes are made to the database

---

### Requirement: Database updated only after confirmed file write
The Drift/SQLite track record SHALL be updated only after `metadata_god` confirms the file write succeeded. If the file write fails for any reason, the database SHALL remain unchanged.

#### Scenario: File write succeeds — DB updated
- **WHEN** `metadata_god` reports a successful write
- **THEN** the corresponding row in `TracksTable` is updated with the new field values

#### Scenario: File write fails — DB unchanged
- **WHEN** `metadata_god` throws an exception during write
- **THEN** the `TracksTable` row retains its previous values
- **AND** the track tile badge remains red

---

### Requirement: ISRC field is not editable
The metadata editor SHALL NOT expose the `isrc` field for user input. The field is read-only and populated only at scan time.

#### Scenario: ISRC absent from editor form
- **WHEN** the metadata editor bottom sheet is open for any track
- **THEN** no input field for ISRC is rendered
