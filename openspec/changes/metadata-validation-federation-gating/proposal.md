## Why

As Nightingale nodes federate and share tracks across the network, poorly tagged files degrade discovery, break recommendations, and produce unusable `Audio` objects in ActivityPub feeds. There is currently no enforcement mechanism — a track missing artist, genre, or artwork can be published as-is, polluting the network with incomplete data. This change introduces metadata completeness validation as a first-class concern: tracks must meet a minimum tag standard before they can be shared, and the app gives users the tooling to reach that standard without leaving the app.

## What Changes

- **`TrackModel` gains an optional `isrc` field** — read from `TSRC` (MP3/ID3v2) or `ISRC=` (FLAC/Vorbis) at scan time; never user-entered; used as a first-pass deduplication signal before acoustic fingerprinting.
- **`MetadataValidator` service introduced** — evaluates a `TrackModel` against 7 required fields and returns a typed completeness result with the list of missing fields.
- **Track tiles gain a metadata badge** — a red dot (incomplete) or green dot (complete) rendered only on tracks the user has marked for sharing. Tracks not in the published library show no badge.
- **Long-press metadata editor bottom sheet** — surfaces missing fields for a flagged track, accepts user input, writes values back to the physical file via `metadata_god`, and updates the local Drift/SQLite database.
- **Federation sharing gate** — any publish, `Announce`, or library-collection export for a track with incomplete required fields is blocked; the user is shown which fields are missing and offered the editor.

**Required fields for sharing (all 7 must be present):**

| Field | Category |
|---|---|
| `title` | Hard required |
| `artist` | Hard required |
| `album` | Hard required |
| `albumArtist` | Hard required |
| `artworkPath` | Hard required |
| `genre` | Required for discovery |
| `releaseYear` | Required for discovery |

Track number, disc number, ISRC, and MBID are explicitly **not** required and carry no badge or gate.

## Capabilities

### New Capabilities

- `metadata-completeness-validation`: Defines the required-field contract, the `MetadataValidator` service, ISRC read-only field storage, and the completeness result type used by all other capabilities.
- `track-metadata-badge`: Red/green dot badge on track tiles, visibility rules (sharing-scoped only), and the data binding from validator result to tile widget.
- `metadata-editor`: Long-press bottom sheet for entering missing tag values, ID3/Vorbis write-back via `metadata_god`, and local database sync after a successful write.
- `federation-metadata-gate`: Blocking gate on all federation paths (library publish, `Announce` activity, library Collection export) that rejects tracks failing validation, with UX directing the user to the editor.

### Modified Capabilities

- `acoustic-deduplication`: ISRC, when present, becomes the first-pass deduplication signal evaluated before Chromaprint fingerprint comparison is attempted.

## Impact

**Code touched:**
- `lib/features/library/models/track_model.dart` — add optional `isrc` field
- `lib/features/library/library_repository_impl.dart` — read ISRC from tags at scan time
- `lib/core/database/tables/tracks_table.dart` — add `isrc` column, migration
- `lib/features/federation/deduplication/acoustic_fingerprint_service.dart` — ISRC first-pass check
- `lib/features/library/widgets/track_tile.dart` — badge overlay
- New: `lib/features/library/services/metadata_validator.dart`
- New: `lib/features/library/widgets/metadata_editor_sheet.dart`
- New: `lib/features/federation/guards/metadata_gate.dart`

**Dependencies:**
- `metadata_god ^0.3.0+1` — already in `pubspec.yaml`; activated for write path

**Federation contract:**
- `Audio` objects in the published Collection will never contain tracks with missing required fields once gating is enforced; downstream nodes can rely on all 7 fields being present.
