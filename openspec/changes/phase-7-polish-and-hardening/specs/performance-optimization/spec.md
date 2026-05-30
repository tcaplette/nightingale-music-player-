## ADDED Requirements

### Requirement: Cold start time does not exceed 2 seconds on target hardware
The time from `main()` invocation to first interactive frame SHALL be ≤ 2 000 ms on a mid-range device (Pixel 6 / iPhone 12 class hardware, release build). Startup profiling SHALL be instrumented with `Timeline.startSync`/`finishSync` markers at: DB open, identity load, router initialization, and first frame render.

#### Scenario: Cold start measured on release build
- **WHEN** the app is launched in release mode on target hardware from a cold start (no background process)
- **THEN** the time from `main()` to first interactive frame SHALL be ≤ 2 000 ms
- **THEN** `Timeline` markers SHALL be present in the DevTools performance trace for each startup stage

#### Scenario: Slow DB open detected
- **WHEN** `Timeline` shows DB open exceeding 500 ms
- **THEN** the startup sequence SHALL be examined for synchronous blocking calls that can be deferred
- **THEN** non-critical initialization SHALL be moved to a post-frame callback or lazy-loaded

### Requirement: Feed and list scrolling maintains ≥ 58 fps on target hardware
All list and grid views (library, social feed, recommendations, followers) SHALL scroll at a sustained frame rate of ≥ 58 fps on target hardware in a release build. `RepaintBoundary` SHALL isolate the mini player and artwork thumbnails. List cells SHALL use fixed-extent layout (`SliverFixedExtentList`) wherever row height is uniform.

#### Scenario: Library scroll frame rate
- **WHEN** the user fast-scrolls through a library of 500 tracks in a release build
- **THEN** the frame render time SHALL not exceed 17 ms (60 fps) for more than 2 consecutive frames
- **THEN** no jank frame SHALL coincide with image loading (images SHALL load asynchronously via `cached_network_image`)

#### Scenario: Social feed scroll with avatars
- **WHEN** the user scrolls through a social feed with 100 items containing remote avatars
- **THEN** avatars SHALL load from cache without causing dropped frames
- **THEN** `RepaintBoundary` on each avatar widget SHALL prevent propagating repaints to the list

### Requirement: App memory usage does not exceed 150 MB during a 30-minute playback session
Steady-state memory during active playback (local or remote), with the social feed open in the background, SHALL not exceed 150 MB RSS on target hardware. Image caches SHALL have a defined maximum capacity. Audio buffers SHALL be bounded by `just_audio` configuration.

#### Scenario: 30-minute playback session memory profile
- **WHEN** the app plays 30 minutes of audio while the user browses the social feed
- **THEN** peak RSS SHALL not exceed 150 MB as measured by Flutter DevTools Memory tab
- **THEN** no unbounded widget lists SHALL accumulate state over the session

#### Scenario: Image cache size is bounded
- **WHEN** the user views 200 artwork thumbnails during a session
- **THEN** the `cached_network_image` disk cache SHALL not exceed 100 MB
- **THEN** the in-memory image cache SHALL not exceed 50 entries (configured via `PaintingBinding.instance.imageCache.maximumSize`)

### Requirement: Background federation battery impact does not exceed 3% per hour
Background ActivityPub inbox polling, library sync, and best-effort serving SHALL consume no more than 3% battery per hour on target hardware when the app is backgrounded. Background polling intervals SHALL be adaptive: shorter when activity is high, longer (up to 15 min) when the app has been idle.

#### Scenario: Idle background battery audit
- **WHEN** the app is backgrounded with no active playback for 60 minutes
- **THEN** battery drain attributable to nightingale SHALL be ≤ 3% as measured by the platform battery stats
- **THEN** the background service SHALL have polled at most 4 times in that window (≥ 15 min interval)

### Requirement: Stream buffer and cache eviction is tuned for degraded networks
The audio stream buffer strategy SHALL target a minimum 30 s pre-buffered window and a maximum 120 s buffer. On a network with sustained throughput below 64 kbps, the buffer target SHALL reduce to 15 s to reduce latency to first audio. Cache eviction SHALL use an LRU policy: the oldest unreferenced cached track bytes are removed first when disk usage exceeds the configured limit (default: 500 MB).

#### Scenario: Buffer fills to 30 s before playback starts
- **WHEN** a remote stream starts loading on a stable connection
- **THEN** the first audio sample SHALL not play until at least 5 s of audio is buffered
- **THEN** the buffer SHALL continue filling to 30 s in the background after playback starts

#### Scenario: LRU eviction on cache full
- **WHEN** the cache reaches 500 MB
- **THEN** the least-recently-used cached track bytes SHALL be evicted first
- **THEN** the current session's tracks SHALL NOT be evicted while they are in the active queue
