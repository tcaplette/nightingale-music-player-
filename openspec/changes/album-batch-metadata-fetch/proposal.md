## Why

Populating metadata track-by-track is tedious for large libraries. When a user already has an album grouping, all tracks share the same release context (album name, artist, year, genre, artwork) — a single album-level MusicBrainz query can populate all of them at once, and the track listing returned by that query provides enough structure to match each track reliably without a per-track network call.

## What Changes

- **Albums tab gains a long-press action** — long-pressing an album tile shows a context menu with "Fetch metadata for all tracks". Tapping it launches the batch fetch flow.
- **New `AlbumMetadataFetchService`** — queries MusicBrainz for the release by album name + artist, retrieves the full track listing, merges missing album-level fields (genre, year, artwork) from iTunes using the same MusicBrainz-wins pattern as single-track lookup, matches each local track via a scoring cascade (track number → duration ±4 s → title fuzzy match), and writes results only to missing fields.
- **Result summary bottom sheet** — shown after the batch completes, reporting "N of M tracks matched" and listing any unmatched tracks by name.
- **Artwork applied album-wide** — artwork is fetched once (Cover Art Archive → iTunes fallback) and written to all tracks in the album.

## Capabilities

### New Capabilities

- `album-batch-metadata-fetch`: The full batch flow — long-press trigger on album tile, `AlbumMetadataFetchService` (MusicBrainz release lookup, iTunes merge, track matching engine, field write), and the result summary sheet.

### Modified Capabilities

<!-- none — MetadataLookupService internals are unchanged; AlbumMetadataFetchService calls its public methods -->

## Impact

- New: `lib/features/library/services/album_metadata_fetch_service.dart`
- New: `lib/features/library/widgets/album_metadata_result_sheet.dart`
- `lib/features/library/screens/albums_view.dart` — add long-press to `_AlbumTile`
- `lib/features/library/services/metadata_lookup_service.dart` — no changes; `AlbumMetadataFetchService` calls its existing public `lookup()` and `downloadArtwork()` methods
- `lib/core/database/daos/track_dao.dart` — existing `updateTrack` used for writes; no schema changes
- No new dependencies
