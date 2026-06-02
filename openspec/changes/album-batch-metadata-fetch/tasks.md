## 1. AlbumMetadataFetchService — MusicBrainz Release Query

- [x] 1.1 Create `lib/features/library/services/album_metadata_fetch_service.dart` with a `AlbumMetadataFetchService` class registered in `service_locator.dart`
- [x] 1.2 Implement `_lookupRelease(albumName, artist)` — query `https://musicbrainz.org/ws/2/release?query=release:"<album>" AND artist:"<artist>"&inc=recordings&fmt=json&limit=5`, pick the best release (prefer status "official"), extract track listing (title, duration ms, track number, disc number) and album-level fields (releaseYear, genre from tags)
- [x] 1.3 Implement `_fetchReleaseArtwork(mbid)` — call Cover Art Archive, return front cover URL (reuse the pattern from `MetadataLookupService._fetchCoverArt`)

## 2. AlbumMetadataFetchService — iTunes Merge

- [x] 2.1 Implement album-level iTunes merge: if MusicBrainz result is missing genre, releaseYear, or artworkUrl, call `MetadataLookupService._lookupItunes` (or extract it to an accessible helper) with the album name and artist, then merge using MusicBrainz-wins priority
- [x] 2.2 Define `AlbumLookupResult` data class holding: `List<MbTrackEntry>` (title, durationMs, trackNumber, discNumber), `String? genre`, `int? releaseYear`, `String? artworkUrl`, `String source`

## 3. AlbumMetadataFetchService — Track Matching Engine

- [x] 3.1 Implement `_scoreMatch(TrackModel local, MbTrackEntry candidate)` — returns int score using: track number match = 3, duration within ±4000 ms = 2, normalised title match = 1
- [x] 3.2 Implement `_matchTracks(List<TrackModel> tracks, List<MbTrackEntry> mbTracks)` — for each local track find the highest-scoring candidate; commit only if score ≥ 3 and no tie; return `Map<TrackModel, MbTrackEntry>` for matched pairs and a `List<TrackModel>` for unmatched
- [x] 3.3 Implement title normalisation helper: lowercase, strip `feat.`/`ft.`/`(feat. ...)`/`(ft. ...)`, strip leading/trailing punctuation, collapse whitespace

## 4. AlbumMetadataFetchService — Write & Result

- [x] 4.1 Implement `_applyMatch(TrackModel track, MbTrackEntry mb, AlbumLookupResult albumResult, String? artworkPath)` — build a `TracksTableCompanion` that only sets fields currently empty on the track; write to file via `metadata_god`; update DB via `trackDao.updateTrack()` only after file write succeeds
- [x] 4.2 Implement the public `fetch(AlbumModel album, List<TrackModel> tracks)` method — orchestrates steps 1–4, downloads artwork once via `MetadataLookupService.downloadArtwork`, returns `AlbumFetchResult(matched, unmatched, errors)`
- [x] 4.3 Define `AlbumFetchResult` data class: `int totalTracks`, `List<TrackModel> matched`, `List<TrackModel> unmatched`, `Map<TrackModel, String> errors` (track → error message)

## 5. Result Summary Sheet

- [x] 5.1 Create `lib/features/library/widgets/album_metadata_result_sheet.dart` — `showAlbumMetadataResultSheet(context, AlbumFetchResult)` displays a bottom sheet with: "All N tracks updated" or "M of N tracks matched", unmatched track list, errors section if any, a "Done" button
- [x] 5.2 Handle the "No metadata found" empty state in the sheet (both MusicBrainz and iTunes returned nothing)

## 6. Albums View — Long-Press Trigger

- [x] 6.1 Add `onLongPress` to `_AlbumTile` that calls `showModalBottomSheet` with a single action: "Fetch metadata for all tracks" (use a `ListTile` action sheet pattern)
- [x] 6.2 On action tap: load the album's tracks via `trackDao.getTracksForAlbum(album.id)`, show an `AlertDialog` progress indicator, call `AlbumMetadataFetchService.fetch()`, dismiss progress, then call `showAlbumMetadataResultSheet`
- [x] 6.3 Invalidate `albumsProvider` and `tracksProvider` after a successful fetch so the UI reflects updated artwork and metadata without requiring a full rescan
