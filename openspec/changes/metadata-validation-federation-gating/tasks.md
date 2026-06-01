## 1. Database & Model

- [x] 1.1 Add nullable `isrc TEXT` column to `TracksTable` in `lib/core/database/tables/tracks_table.dart`
- [x] 1.2 Write Drift schema migration that adds the `isrc` column with `NULL` default for existing rows
- [x] 1.3 Add optional `isrc` field to `TrackModel` in `lib/features/library/models/track_model.dart`
- [x] 1.4 Update `TrackModel.fromRow()` and `toCompanion()` to include `isrc`

## 2. Library Scanning — ISRC Read

- [x] 2.1 In `library_repository_impl.dart`, read ISRC from scanned file tags via `metadata_god` (`TSRC` for MP3, `ISRC=` for FLAC) and populate `TrackModel.isrc` at scan time
- [x] 2.2 Confirm ISRC is stored as `NULL` (not empty string) when the tag is absent

## 3. MetadataValidator Service

- [x] 3.1 Create `lib/features/library/services/metadata_validator.dart` with a `MetadataValidator` class and `validate(TrackModel)` method
- [x] 3.2 Define `MetadataComplete` and `MetadataIncomplete` result types; `MetadataIncomplete` carries a `List<String> missingFields`
- [x] 3.3 Implement the 7-field completeness check: `title`, `artist`, `album`, `albumArtist`, `artworkPath`, `genre`, `releaseYear`
- [x] 3.4 Verify `trackNumber`, `discNumber`, and `isrc` are explicitly excluded from the required-fields check

## 4. Acoustic Deduplication — ISRC First-Pass

- [x] 4.1 In `acoustic_fingerprint_service.dart`, add an ISRC equality check at the top of `findDuplicates()` (or equivalent method)
- [x] 4.2 If both tracks have non-null, non-empty `isrc` values that match, return "same track" without computing Chromaprint
- [x] 4.3 If either `isrc` is null/empty, fall through to existing Chromaprint comparison unchanged

## 5. Track Metadata Badge

- [x] 5.1 Add a `MetadataBadge` widget (small filled circle, 8dp) to `lib/features/library/widgets/` that accepts a `MetadataValidationResult` and renders red, green, or invisible
- [x] 5.2 In `track_tile.dart`, inject whether the track is in the published library scope
- [x] 5.3 Render `MetadataBadge` on the tile only when the track is in the published library; pass validator result as input
- [x] 5.4 Confirm no badge renders for tracks outside the published library regardless of completeness

## 6. Metadata Editor Bottom Sheet

- [x] 6.1 Create `lib/features/library/widgets/metadata_editor_sheet.dart` as a `DraggableScrollableSheet`
- [x] 6.2 Accept a `TrackModel` and a `List<String> missingFields`; render a labelled `TextFormField` for each missing field (and all 7 fields when opened from a complete track)
- [x] 6.3 Implement Save handler: call `metadata_god` to write values to the physical file for MP3 (ID3v2) and FLAC (Vorbis Comments)
- [x] 6.4 Only update the Drift `TracksTable` row after `metadata_god` confirms a successful write
- [x] 6.5 On `FileSystemException` or unsupported format error from `metadata_god`, display an inline error message inside the sheet and make no DB changes
- [x] 6.6 Ensure `isrc` field is absent from the editor form entirely

## 7. Long-Press Trigger

- [x] 7.1 In `track_tile.dart`, wire `onLongPress` to open `MetadataEditorSheet` when the track has a red badge (i.e. is in published library and incomplete)
- [x] 7.2 Confirm long-press on unshared tracks (no badge) does not trigger the editor

## 8. Federation Metadata Gate

- [x] 8.1 Create `lib/features/federation/guards/metadata_gate.dart` with a `MetadataGate` class and `check(TrackModel)` method
- [x] 8.2 `check()` calls `MetadataValidator.validate()`; if `MetadataIncomplete`, throws `MetadataIncompleteException(missingFields)`
- [x] 8.3 In `LibraryPublisher`, call `MetadataGate.check()` before emitting any track; catch `MetadataIncompleteException` and exclude the track from the Collection silently
- [x] 8.4 In `ActivityService.announce()`, call `MetadataGate.check()` before dispatching; on `MetadataIncompleteException`, block the activity and surface the rejection UX
- [x] 8.5 In the library Collection endpoint handler, filter out tracks that fail `MetadataGate.check()` before serialising the `OrderedCollection` response

## 9. Gate Rejection UX

- [x] 9.1 Create a `MetadataGateRejectionSheet` (or reuse `MetadataEditorSheet`) that presents the list of missing fields and a primary CTA to open the editor
- [x] 9.2 Wire the CTA to open `MetadataEditorSheet` for the affected track
- [x] 9.3 After the user saves in the editor and all fields are complete, the share action can be retried directly without showing the gate prompt again

## 10. Settings — Excluded Tracks Count

- [x] 10.1 In the sharing/library settings screen, display a count of tracks in the published scope that are currently excluded due to incomplete metadata
- [x] 10.2 Tapping the count opens a filtered list of those tracks (each with a red badge and long-press editor access)
