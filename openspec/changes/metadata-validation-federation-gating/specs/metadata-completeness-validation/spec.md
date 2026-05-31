## ADDED Requirements

### Requirement: Required field contract
The system SHALL define a fixed set of 7 required metadata fields for federation eligibility: `title`, `artist`, `album`, `albumArtist`, `artworkPath`, `genre`, and `releaseYear`. A track is considered *complete* when all 7 fields are non-null and non-empty. A track is considered *incomplete* when one or more required fields are missing.

#### Scenario: All required fields present
- **WHEN** a `TrackModel` has non-null, non-empty values for all 7 required fields
- **THEN** `MetadataValidator.validate()` returns a `MetadataComplete` result

#### Scenario: One required field missing
- **WHEN** a `TrackModel` has a null or empty value for any single required field
- **THEN** `MetadataValidator.validate()` returns a `MetadataIncomplete` result containing the name of the missing field

#### Scenario: Multiple required fields missing
- **WHEN** a `TrackModel` has null or empty values for more than one required field
- **THEN** `MetadataValidator.validate()` returns a `MetadataIncomplete` result containing the names of all missing fields

#### Scenario: Optional fields ignored
- **WHEN** a `TrackModel` is missing `trackNumber`, `discNumber`, or `isrc`
- **THEN** `MetadataValidator.validate()` does not include those fields in the missing-fields list and does not affect the completeness result

---

### Requirement: ISRC field storage
The `TrackModel` SHALL include an optional, read-only `isrc` field of type `String?`. The field is populated at library scan time if a valid ISRC code is found in the file's tags. It is never written by the user through the metadata editor.

#### Scenario: ISRC present in MP3 file
- **WHEN** an MP3 file contains a populated `TSRC` ID3v2 frame
- **THEN** the scan stores the ISRC value in the `isrc` field of the corresponding `TrackModel`

#### Scenario: ISRC present in FLAC file
- **WHEN** a FLAC file contains an `ISRC=` Vorbis Comment key
- **THEN** the scan stores the ISRC value in the `isrc` field of the corresponding `TrackModel`

#### Scenario: No ISRC in file
- **WHEN** a file has no ISRC tag
- **THEN** the `isrc` field is stored as `NULL` in the database

#### Scenario: ISRC is never user-editable
- **WHEN** the metadata editor bottom sheet is opened for any track
- **THEN** the `isrc` field is NOT displayed and NOT editable

---

### Requirement: Database schema includes ISRC
The `TracksTable` SHALL include a nullable `isrc TEXT` column. The column SHALL be added via a Drift schema migration. Existing rows receive a `NULL` value on migration.

#### Scenario: Migration preserves existing data
- **WHEN** the app is updated from a schema version without the `isrc` column to a version with it
- **THEN** all existing track rows are preserved with `isrc = NULL`
- **AND** no data loss occurs

#### Scenario: ISRC populated on next scan
- **WHEN** the user triggers a library rescan after migration
- **THEN** the `isrc` field is populated for any file that contains a valid ISRC tag
