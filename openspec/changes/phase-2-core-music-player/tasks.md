## 1. Dependencies and Platform Configuration

- [x] 1.1 Add `just_audio`, `just_audio_background`, and `audio_session` to `pubspec.yaml`
- [x] 1.2 Add `drift` and `drift_flutter` to `pubspec.yaml`; add `build_runner` and `drift_dev` to dev dependencies
- [x] 1.3 Add `on_audio_query` (library scanning) and `metadata_god` (fallback tag reader) to `pubspec.yaml`
- [x] 1.4 Configure Android permissions in `AndroidManifest.xml`: `READ_EXTERNAL_STORAGE`, `READ_MEDIA_AUDIO`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK`
- [x] 1.5 Configure iOS permissions in `Info.plist`: `NSAppleMusicUsageDescription`, `UIBackgroundModes: audio`
- [x] 1.6 Add `UIBackgroundModes: audio` entitlement to `Runner.entitlements`
- [x] 1.7 Create folder structure: `lib/core/audio/`, `lib/core/database/`, `lib/features/library/`, `lib/features/playback/`, `lib/features/player_ui/`

## 2. Database Schema (Drift)

- [x] 2.1 Define `TracksTable` Drift table with columns: id, filePath, title, artist, albumId, albumArtist, trackNumber, discNumber, genre, releaseYear, durationMs, artworkPath, dateAdded
- [x] 2.2 Define `AlbumsTable` Drift table with columns: id, name, artist, artworkPath, releaseYear, trackCount
- [x] 2.3 Define `ArtistsTable` Drift table with columns: id, name
- [x] 2.4 Create `AppDatabase` Drift database class with schema version 1 and empty migration baseline
- [x] 2.5 Run `build_runner` to generate Drift code and verify compilation
- [x] 2.6 Write `TrackDao`, `AlbumDao`, `ArtistDao` with CRUD operations and query methods needed by library views and search

## 3. AudioSource Abstraction

- [x] 3.1 Create sealed class `AudioSource` in `lib/core/audio/audio_source.dart` with subtypes `LocalAudioSource(String filePath)` and `RemoteAudioSource(Uri uri)` — include a `// Phase 4: remote streaming extends this` comment on the class
- [x] 3.2 Write unit tests for `AudioSource` equality and pattern matching

## 4. Library Management

- [x] 4.1 Create `LibraryRepository` interface in `lib/features/library/` with methods: `scanLibrary()`, `getAllTracks()`, `getAlbums()`, `getArtists()`, `getGenres()`, `searchLibrary(String query)`
- [x] 4.2 Implement `LibraryRepositoryImpl`: use `on_audio_query` as primary scanner; fall back to `metadata_god` for unindexed files
- [x] 4.3 Implement metadata normalisation: apply "Unknown Artist" / "Unknown Album" defaults for missing fields; extract and store artwork as a file path (not a blob)
- [x] 4.4 Implement library diff logic: compare scan results against current database state; insert new tracks, delete removed tracks, update changed metadata
- [x] 4.5 Implement `LibraryScanNotifier` (Riverpod) that exposes scan state (idle, scanning, done, error) and the most recent scan summary (counts, errors)
- [x] 4.6 Implement app-resume hook: register `AppLifecycleListener` to trigger a background rescan when the app returns to foreground; surface partial-library Phase 1 component if the OS media store may be stale
- [x] 4.7 Wire `LibraryRepository` into the DI container

## 5. Playback Engine

- [x] 5.1 Create `PlaybackEngine` class in `lib/core/audio/` wrapping `just_audio`'s `AudioPlayer`; accept a `List<AudioSource>` and expose play/pause/stop/skipNext/skipPrevious/seekTo
- [x] 5.2 Implement `AudioSource` → `just_audio` source resolution: `LocalAudioSource` → `AudioSource.uri(Uri.file(path))`; `RemoteAudioSource` → `AudioSource.uri(uri)` with best-effort error handling
- [x] 5.3 Configure `just_audio_background` initialisation for system media session (lock screen controls, Android notification)
- [x] 5.4 Configure `audio_session` for music category; implement audio focus callbacks (pause on call, duck on notification, resume on focus regain)
- [x] 5.5 Enable gapless playback via `ConcatenatingAudioSource`; verify audible gap is absent between consecutive tracks in test
- [x] 5.6 Create `PlaybackStateModel` (immutable value type): playingStatus, currentTrack, currentPosition, totalDuration, bufferStatus, shuffleMode, repeatMode, streamSourceType
- [x] 5.7 Create `PlaybackNotifier` (Riverpod `AsyncNotifier`) that wraps `PlaybackEngine` and exposes `PlaybackStateModel`; emit position updates at ≥ 1 Hz during playback
- [x] 5.8 Implement shuffle mode: randomise queue order on enable; restore original order on disable; keep current track current
- [x] 5.9 Implement repeat modes: repeat-off, repeat-one (loop single track), repeat-all (loop entire queue)
- [x] 5.10 Wire `PlaybackEngine` and `PlaybackNotifier` into the DI container

## 6. Queue Management

- [x] 6.1 Implement queue operations on `PlaybackNotifier`: enqueue (append), play-next (insert at current + 1), removeAt(index), reorder(from, to), clearAll
- [x] 6.2 Ensure removing the currently playing track advances playback to the next track seamlessly
- [x] 6.3 Write unit tests covering: enqueue, play-next, remove current track, reorder, clear all, skip at end of queue with repeat-off

## 7. Navigation Shell and Routes

- [x] 7.1 Create `PlayerShell` widget in `lib/features/player_ui/`: a `Stack` with the go_router navigator body below and the `MiniPlayer` widget above, with bottom padding injected to prevent content obstruction
- [x] 7.2 Wrap the root go_router navigator with `PlayerShell`; confirm the mini player persists across all route transitions
- [x] 7.3 Define go_router routes: `/library` (default), `/library/albums/:albumId`, `/library/artists/:artistId`, `/search`, `/now-playing`, `/queue`

## 8. Library UI

- [x] 8.1 Implement `AllSongsView`: paginated list of tracks sorted by title; each row shows title, artist, duration with correct typographic hierarchy from Phase 1 tokens
- [x] 8.2 Implement `AlbumsView`: grid/list of albums sorted alphabetically; each card shows artwork (or placeholder), album name, artist name
- [x] 8.3 Implement `ArtistsView`: list of artists sorted alphabetically; each row shows artist name and album count
- [x] 8.4 Implement `GenresView`: list of genres; tapping a genre shows a filtered track list
- [x] 8.5 Implement empty-state widgets for each library view (purposeful on-brand design, not a blank screen)
- [x] 8.6 Implement manual refresh trigger (pull-to-refresh or dedicated button); show scan progress using `LibraryScanNotifier` state
- [x] 8.7 Wire partial-library Phase 1 component to display when `LibraryScanNotifier` reports a stale media store state

## 9. Album and Artist Detail Screens

- [x] 9.1 Implement `AlbumDetailScreen`: artwork header, album name, artist name, release year, scrollable track list (track number, title, duration); "Play Album" button loads all tracks and starts from track 1
- [x] 9.2 Implement tap-on-track in album detail: loads album tracks into queue and starts from the tapped track
- [x] 9.3 Implement `ArtistDetailScreen`: artist name header, list of albums (tapping goes to AlbumDetailScreen), "Play All" button loads all artist tracks into queue

## 10. Search

- [x] 10.1 Implement `SearchScreen` with a text field that queries `LibraryRepository.searchLibrary()` and displays results grouped by type (Tracks, Albums, Artists)
- [x] 10.2 Debounce search input to ≤ 150ms; results update in real time as the user types
- [x] 10.3 Implement "no results" empty state
- [x] 10.4 Clear search query and return to previous state when search is dismissed

## 11. Now Playing Screen

- [x] 11.1 Implement `NowPlayingScreen` layout: large artwork (or placeholder) at top, track title / artist / album text below with Phase 1 typographic hierarchy, scrubber with position + duration labels, transport controls (previous, play/pause, next), shuffle and repeat toggles
- [x] 11.2 Wire scrubber to `PlaybackNotifier`: position updates at ≥ 1 Hz during playback; drag updates the position label in real time; release calls `seekTo`
- [x] 11.3 Animate artwork crossfade on track change using Phase 1 motion constants (duration + easing)
- [x] 11.4 Apply Phase 1 network-state components: show buffering component in controls area when buffer is low; show host-offline component when a remote source is unreachable
- [x] 11.5 Verify dark mode and light mode rendering with no clipped text or misaligned spacing

## 12. Mini Player

- [x] 12.1 Implement `MiniPlayer` widget: small artwork thumbnail, track title (truncated), artist name, play/pause button; hidden when queue is empty
- [x] 12.2 Wire play/pause button to `PlaybackNotifier`
- [x] 12.3 Tap on mini player navigates to `NowPlayingScreen` without replacing the current navigation stack
- [x] 12.4 Verify `MiniPlayer` visibility persists across all routes including nested routes

## 13. Queue View

- [x] 13.1 Implement `QueueScreen`: current track highlighted, upcoming tracks listed in order; each row shows artwork thumbnail, title, artist
- [x] 13.2 Implement drag-to-reorder using `ReorderableListView`; commit reorder to `PlaybackNotifier` on drag end
- [x] 13.3 Implement swipe-to-remove on queue rows; handle remove-current-track case (playback advances to next)

## 14. Debug Overlay — Playback Diagnostics Tab

- [x] 14.1 Create `PlaybackDiagnosticsNotifier` (Riverpod, dev-only) that aggregates: queue list, buffer duration + health, audio session state, audio format metadata, stream source type for current track
- [x] 14.2 Gate `PlaybackDiagnosticsNotifier` registration behind a compile-time `kDebugMode` / `dart.define` flag so it is tree-shaken in release builds
- [x] 14.3 Implement `PlaybackDiagnosticsTab` widget as a new tab in the Phase 1 debug overlay; display all fields from the notifier in real time
- [x] 14.4 Register the new tab in the Phase 1 overlay tab list (dev builds only)
- [x] 14.5 Verify the tab is absent in a release build profile

## 15. Debug Overlay — Library Scan Log Tab

- [x] 15.1 Create `LibraryScanLogNotifier` (Riverpod, dev-only) that captures per-scan summary: total found, parsed, rejected, per-file errors (path + reason), scan duration ms
- [x] 15.2 Gate `LibraryScanLogNotifier` registration behind the same compile-time flag as 14.2
- [x] 15.3 Implement `LibraryScanLogTab` widget as a new tab in the Phase 1 debug overlay; display the most recent scan log with timestamps; show "scanning…" state during an active scan
- [x] 15.4 Register the new tab in the Phase 1 overlay tab list (dev builds only)
- [x] 15.5 Verify the tab is absent in a release build profile and no scan log data is collected
