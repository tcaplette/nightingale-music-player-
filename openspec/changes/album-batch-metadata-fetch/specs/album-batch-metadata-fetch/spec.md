## ADDED Requirements

### Requirement: Long-press on album tile triggers batch metadata fetch
`_AlbumTile` in `AlbumsView` SHALL respond to a long-press gesture by showing a context menu containing a "Fetch metadata for all tracks" action. Tapping this action SHALL initiate the batch fetch flow for that album.

#### Scenario: Long-press shows context menu
- **WHEN** the user long-presses an album tile
- **THEN** a context menu appears with a "Fetch metadata for all tracks" option

#### Scenario: Tapping action starts fetch
- **WHEN** the user taps "Fetch metadata for all tracks"
- **THEN** a progress indicator is shown on the album tile and the batch fetch begins

---

### Requirement: MusicBrainz release query retrieves full track listing
`AlbumMetadataFetchService` SHALL query the MusicBrainz release endpoint with the album name and artist to retrieve a matching release including its full ordered track listing (title, duration, track number per track).

#### Scenario: Release found with full track listing
- **WHEN** MusicBrainz returns a matching release for the album name and artist
- **THEN** the service extracts the release's track listing (title, duration in milliseconds, track number, disc number) for use in local matching

#### Scenario: No matching release found
- **WHEN** MusicBrainz returns no results for the album name and artist
- **THEN** the service proceeds to the iTunes query for album-level fields; per-track matching is skipped and all tracks are reported as unmatched

#### Scenario: MusicBrainz request fails
- **WHEN** the MusicBrainz request times out or returns a non-200 status
- **THEN** the service falls back to iTunes for album-level fields and reports all tracks as unmatched

---

### Requirement: iTunes consulted when MusicBrainz album-level fields are incomplete
If the MusicBrainz result is missing genre, release year, or artwork URL, `AlbumMetadataFetchService` SHALL query the iTunes Search API for the same album and merge the missing fields using MusicBrainz-wins priority.

#### Scenario: MusicBrainz missing genre and artwork — iTunes fills gaps
- **WHEN** the MusicBrainz release has no genre tags and no Cover Art Archive entry
- **THEN** the service queries iTunes, takes the genre and artwork URL from iTunes, and retains MusicBrainz values for any fields it did return

#### Scenario: MusicBrainz complete — iTunes not queried
- **WHEN** the MusicBrainz release has genre, release year, and artwork URL
- **THEN** the service does not query iTunes

#### Scenario: Both sources missing a field
- **WHEN** neither MusicBrainz nor iTunes can supply a field (e.g. genre)
- **THEN** that field remains unset and is not written to any track

---

### Requirement: Track matching uses a confidence-scored cascade
For each local track in the album, `AlbumMetadataFetchService` SHALL score candidate matches from the MusicBrainz track listing using the following signals and commit a match only when the total score is ≥ 3:

| Signal | Score |
|---|---|
| Track number matches release position | 3 |
| Duration within ±4 seconds | 2 |
| Normalised title match | 1 |

#### Scenario: Track number present and matches — committed
- **WHEN** the local track has a track number and it matches the position of exactly one MusicBrainz track entry
- **THEN** the match is committed (score 3) regardless of title or duration

#### Scenario: No track number — duration and title agree — committed
- **WHEN** the local track has no track number, its duration is within ±4 seconds of exactly one MusicBrainz entry, and the normalised titles match
- **THEN** the match is committed (score 3)

#### Scenario: Duration alone matches — not committed
- **WHEN** only the duration signal fires (score 2) with no track number or title agreement
- **THEN** no match is committed for that track and it is reported as unmatched

#### Scenario: No signal fires — track unmatched
- **WHEN** no MusicBrainz track entry scores ≥ 3 against the local track
- **THEN** the track is added to the unmatched list and no fields are written for it

#### Scenario: Multiple candidates tie — not committed
- **WHEN** two or more MusicBrainz entries reach the same highest score for a local track
- **THEN** no match is committed and the track is reported as unmatched

---

### Requirement: Only empty fields are written
`AlbumMetadataFetchService` SHALL write a matched field value to a local track only if that field is currently empty or null. Existing non-empty values SHALL never be overwritten.

#### Scenario: Field already populated — skipped
- **WHEN** a local track already has a genre value and the matched MusicBrainz entry also has a genre
- **THEN** the local track's genre is not changed

#### Scenario: Field empty — written
- **WHEN** a local track has no release year and the matched entry provides one
- **THEN** the release year is written to the file tags and the database record

---

### Requirement: Artwork fetched once and applied to all tracks
Artwork SHALL be fetched a single time (Cover Art Archive for MusicBrainz releases; iTunes artwork URL as fallback) and its local file path written to every track in the album whose `artworkPath` is currently empty.

#### Scenario: Artwork fetched from Cover Art Archive
- **WHEN** the MusicBrainz release has a Cover Art Archive entry
- **THEN** the front cover image is downloaded once and its path written to all tracks with empty `artworkPath`

#### Scenario: Cover Art Archive unavailable — iTunes artwork used
- **WHEN** the Cover Art Archive returns 404 or times out
- **THEN** the iTunes artwork URL (600×600) is downloaded and applied instead

#### Scenario: Track already has artwork — skipped
- **WHEN** a track in the album already has a non-empty `artworkPath`
- **THEN** its artwork is not replaced

---

### Requirement: Writes applied to physical file and database
For each matched track, `AlbumMetadataFetchService` SHALL write filled fields to the physical audio file via `metadata_god` and update the corresponding `TracksTable` row. The database update SHALL only occur after the file write succeeds.

#### Scenario: File write succeeds — database updated
- **WHEN** `metadata_god` successfully writes tags to a track file
- **THEN** the `TracksTable` row is updated with the new field values

#### Scenario: File write fails — database unchanged, track reported as error
- **WHEN** `metadata_god` throws an exception for a track
- **THEN** the database row is not updated and the track is included in the error list in the result summary

---

### Requirement: Result summary sheet shown after batch completes
After the batch fetch finishes, a bottom sheet SHALL be displayed summarising the outcome.

#### Scenario: All tracks matched
- **WHEN** every track in the album was successfully matched and written
- **THEN** the summary sheet shows "All N tracks updated"

#### Scenario: Partial match
- **WHEN** some tracks were matched and some were not
- **THEN** the summary sheet shows "M of N tracks matched" and lists the unmatched track titles

#### Scenario: Write errors occurred
- **WHEN** one or more file writes failed
- **THEN** the summary sheet lists those track titles under an "Errors" section with a brief reason

#### Scenario: No match found at all
- **WHEN** MusicBrainz and iTunes both returned no usable data
- **THEN** the summary sheet shows "No metadata found for this album" with a suggestion to try editing tracks individually
