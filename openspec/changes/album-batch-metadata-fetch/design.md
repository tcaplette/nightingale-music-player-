## Context

`MetadataLookupService` already provides `_lookupMusicBrainz`, `_lookupItunes`, and `downloadArtwork`. The single-track `lookup()` method applies a MusicBrainz-wins merge with iTunes for missing fields. This change introduces `AlbumMetadataFetchService` which operates at the release level: one MusicBrainz release query returns the full track listing, enabling local matching rather than N per-track network calls.

`AlbumModel` carries `id`, `name`, `artist`, `artworkPath`, `releaseYear`, and `trackCount`. `TrackModel` carries `title`, `artist`, `durationMs`, `trackNumber`, `discNumber`, `genre`, `releaseYear`, `artworkPath`, and `albumArtist`. The existing `trackDao.updateTrack()` writes a `TracksTableCompanion` back to the database, and `metadata_god` handles file tag write-back (already used by the single-track editor).

## Goals / Non-Goals

**Goals:**
- One network round-trip to MusicBrainz to get the full track listing for an album
- Album-level field merge (genre, year, artwork) from iTunes when MusicBrainz is incomplete
- Per-track matching using a confidence-scored cascade: track number → duration ±4 s → title fuzzy match
- Only fill empty fields — never overwrite existing values
- Write matched metadata to both the physical file and the database
- Surface a result summary to the user

**Non-Goals:**
- Matching tracks across multiple discs of a box set (disc number is used as a tiebreaker but multi-disc edge cases are not a priority)
- Editing matched values before committing (the existing per-track editor handles that)
- Batch fetch from the album detail screen (only the album tile long-press for now)
- Offline queuing of failed fetches

## Decisions

### D1: Single MusicBrainz release query, not N recording queries

Querying MusicBrainz per-track would cost N HTTP calls and hit rate limits on any album larger than a few tracks. The release endpoint (`/ws/2/release?query=release:"<album>" AND artist:"<artist>"&inc=recordings`) returns the complete track listing in one response. Local matching is then O(N) with no additional network cost.

**Alternative considered:** re-use the existing `_lookupMusicBrainz` recording search per track. Rejected — too slow, rate limit risk, and the recording search doesn't guarantee all tracks come from the same release.

### D2: Confidence threshold of 2 signals required to commit a match

A single signal (e.g. title alone) can produce false positives — live albums, remasters, and compilations frequently have tracks with the same title at different durations. Requiring at least two agreeing signals (track number + duration, or duration + title) keeps false-positive matches near zero.

Signal weights:
| Signal | Score |
|---|---|
| Track number matches release position | 3 |
| Duration within ±4 seconds | 2 |
| Normalised title match | 1 |

Commit threshold: score ≥ 3. This means track number alone is sufficient (score 3), duration + title is sufficient (score 3), but title alone is not (score 1).

**Alternative considered:** threshold of 2. Rejected — title alone scoring 1 would never pass anyway, but duration-only (score 2) could match wrong tracks on albums with many similar-length tracks (e.g. classical).

### D3: iTunes merge at album level only, before per-track matching

iTunes does not provide a structured track listing, so it cannot contribute to per-track matching. It is only consulted to fill album-level fields (genre, year, artwork URL) that MusicBrainz left null. The same MusicBrainz-wins merge used in `MetadataLookupService.lookup()` is replicated here.

### D4: Artwork written to all tracks in the album, not just the album row

`TrackModel.artworkPath` is the authoritative artwork source for track tiles and the now-playing screen. Writing artwork only to `AlbumsTable` would leave track tiles without art. The single artwork file is downloaded once and its path written to every track in the album that has an empty `artworkPath`.

### D5: `AlbumMetadataFetchService` is a plain Dart class registered in `service_locator.dart`

Consistent with `MetadataLookupService` and `MastodonBridgeService`. No Riverpod provider needed — the service is stateless and called imperatively from the UI.

### D6: Progress feedback via a modal progress indicator, not a background task

The fetch takes 2–8 seconds (one MusicBrainz call + optional iTunes call + Cover Art Archive). Showing an in-place loading state on the album tile (or a modal) keeps the interaction simple. Background queuing would require a task runner and notification infrastructure that doesn't exist yet.

## Risks / Trade-offs

- **MusicBrainz rate limit (1 req/sec)** — the batch makes at most 3 requests (release search, Cover Art Archive, optional iTunes). The existing 1100 ms delay before the Cover Art Archive call (already in `_fetchCoverArt`) is sufficient. → No additional mitigation needed.
- **Album name ambiguity** — common album names ("Greatest Hits", "Self-Titled") may match the wrong release on MusicBrainz. → Duration matching acts as a guard: if the retrieved track listing doesn't have durations close to the local tracks, the match scores stay below threshold and nothing is written.
- **Tracks without track numbers** — files ripped without track number tags fall back to duration + title matching only (score cap 3). Duration + title (score 3) still meets the commit threshold. → Acceptable; unmatched tracks are reported in the summary sheet.
- **File write failure mid-batch** — if `metadata_god` fails on one track, the service continues with remaining tracks and includes the failed track in an "errors" list shown in the summary sheet. → Partial writes are acceptable; the user can fix individual tracks via the single-track editor.
