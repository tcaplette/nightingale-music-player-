## 1. Database Schema & Migration

- [x] 1.1 Create `remote_libraries` table (actorUrl, collectionJson, fetchedAt, etag)
- [x] 1.2 Create `audio_cache` table (trackId, sourceActorUrl, localPath, fetchedAt, lastAccessed, sizeBytes, isPinned)
- [x] 1.3 Create `listen_activities` table (actorUrl, trackId, trackTitle, trackArtist, listenedAt, durationMs)
- [x] 1.4 Create `fingerprints` table (trackId, chromaprintHash, durationMs, computedAt)
- [x] 1.5 Create `merge_provenance` table (fingerprintA, fingerprintB, similarityScore, mergedAt, undoneAt, reason)
- [x] 1.6 Add migration in `app_database.dart` (schemaVersion 3)
- [x] 1.7 Regenerate Drift code with `build_runner`

## 2. Library Publishing

- [x] 2.1 Create `LibraryPublisher` service that builds ActivityPub `OrderedCollection` from local library
- [x] 2.2 Add `GET /users/<username>/library` endpoint to federation router
- [x] 2.3 Implement privacy filtering (public / followers-only / private) in the endpoint handler
- [ ] 2.4 Add sharing settings UI (screen or bottom sheet with radio options)
- [ ] 2.5 Persist sharing setting to local preferences
- [ ] 2.6 Add library publishing debug panel (dev overlay)

## 3. Audio Streaming

- [ ] 3.1 Create `StreamResolver` service that resolves federated track refs to stream URLs
- [ ] 3.2 Extend `PlaybackEngine._resolveSource()` to handle `RemoteAudioSource` with reachability check
- [ ] 3.3 Implement `AudioCacheManager` with LRU eviction and pin-in-use logic
- [x] 3.4 Add `GET /stream/<track-id>` endpoint with range request support
- [ ] 3.5 Implement adaptive buffering configuration in `PlaybackEngine`
- [ ] 3.6 Add stream status indicators to Now Playing screen (buffering, host offline, cached)
- [ ] 3.7 Add stream inspector debug panel (dev overlay)

## 4. Social Subscribing

- [ ] 4.1 Create `RemoteLibraryRepository` for fetching and caching remote Collections
- [ ] 4.2 Add "Follow" action to actor profiles / search results
- [ ] 4.3 Implement `Follow` / `Undo(Follow)` activity delivery via existing outbox
- [ ] 4.4 Create "Network" tab in library screen for browsing followed actors' libraries
- [ ] 4.5 Implement background refresh of cached remote libraries on app foreground
- [ ] 4.6 Add pull-to-refresh on remote library views
- [ ] 4.7 Add unified track display with reachability indicator

## 5. Listening Activities

- [ ] 5.1 Create `ListenActivityPublisher` that observes playback state and queues `Listen` activities
- [ ] 5.2 Extend outbox to include `Listen` activities in the activity stream
- [ ] 5.3 Implement `Listen` activity ingestion in inbox handler
- [ ] 5.4 Add "Share listening activity" toggle in settings (opt-in, default off)
- [ ] 5.5 Add incoming listen feed viewer (social feed screen)

## 6. Acoustic Deduplication

- [ ] 6.1 Integrate Chromaprint C library via FFI (`dart:ffi` or `flutter_rust_bridge`)
- [ ] 6.2 Create `FingerprintService` that computes fingerprints asynchronously post-scan
- [ ] 6.3 Add fingerprint computation progress UI in library scan flow
- [ ] 6.4 Implement similarity comparison using Chromaprint bit-error rate
- [ ] 6.5 Create `DeduplicationEngine` that applies/reverses merges with provenance
- [ ] 6.6 Add deduplication trace debug panel (dev overlay)

## 7. Stream Authentication

- [ ] 7.1 Extend `HttpSignatureService` to sign outgoing stream requests
- [ ] 7.2 Add signature verification middleware to `/stream` endpoint
- [ ] 7.3 Implement followers-only check against followers collection
- [ ] 7.4 Add authentication failure logging for moderation/debug

## 8. Relay Streaming Fallback

- [ ] 8.1 Extend `RelayClient` to support stream forwarding requests
- [ ] 8.2 Implement relay stream request format (`target_actor`, `track_id`)
- [ ] 8.3 Add relay fallback logic in `StreamResolver` (direct → relay → cache → skip)
- [ ] 8.4 Ensure HTTP Signature headers are forwarded through relay
- [ ] 8.5 Add relay path indicator to stream inspector debug panel

## 9. Debug Overlay — Phase 4

- [ ] 9.1 Create `LibrarySyncInspectorTab` showing published collections, fetch status, privacy settings
- [ ] 9.2 Create `StreamInspectorTab` showing active streams, host reachability, bytes received, cache hits, buffer health, relay vs direct
- [ ] 9.3 Create `IncomingLibraryFeedTab` showing raw activity stream from followed nodes
- [ ] 9.4 Create `DeduplicationTraceTab` showing fingerprint comparisons, merge decisions, provenance, undo handles
- [ ] 9.5 Register all Phase 4 tabs in `debug_overlay_setup.dart`

## 10. Testing & Integration

- [ ] 10.1 Unit tests: `LibraryPublisher` collection generation, privacy filtering
- [ ] 10.2 Unit tests: `AudioCacheManager` LRU eviction, pin logic
- [ ] 10.3 Unit tests: `StreamResolver` fallback chain (direct → relay → cache)
- [ ] 10.4 Unit tests: `DeduplicationEngine` merge/undo with provenance
- [ ] 10.5 Integration test: full round-trip (publish library → follow → fetch → stream → cache)
- [ ] 10.6 Widget tests: sharing settings UI, network tab, stream status indicators
- [ ] 10.7 Verify HTTP Signature authentication on stream endpoint
- [ ] 10.8 Verify followers-only enforcement on stream endpoint

## 11. Documentation

- [ ] 11.1 Update `ROADMAP.md` to mark Phase 4 as complete
- [ ] 11.2 Document new API endpoints (`/library`, `/stream`) for other implementers
- [ ] 11.3 Document Chromaprint integration and FFI build steps
- [ ] 11.4 Update debug overlay documentation with Phase 4 tabs
