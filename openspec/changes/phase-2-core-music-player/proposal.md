## Why

Phase 1 established the project skeleton, design system, and debugging infrastructure. Phase 2 builds the first shippable layer of the product: a fully functional local music player. This phase proves the playback engine, establishes the UI language for the entire player experience, and lays the unified audio abstraction that Phase 4 (federated streaming) will extend without requiring a rewrite.

## What Changes

- **New:** device library scanner — discovers audio files on local storage and parses ID3/metadata tags (title, artist, album, artwork, duration, genre)
- **New:** local database — Drift/SQLite, unencrypted by deliberate design decision (album list is not sensitive data; encryption deferred to genuinely sensitive material in Phases 3 and 6)
- **New:** library views — All Songs, Albums, Artists, Genres; manual refresh and filesystem change detection
- **New:** playback engine — `just_audio`-backed engine with a unified `AudioSource` abstraction covering local files and remote streams through the same interface; queue management (play, pause, skip, seek, shuffle, repeat off/one/all); background playback with system media session; gapless playback; audio focus (pause on call, duck on notification)
- **New:** player UI — Now Playing screen, persistent mini player (global shell, not per-screen), queue view with reorder/remove, album and artist detail screens, local library search
- **New:** Phase 2 debug overlay additions — playback diagnostics tab and library scan log tab (compile-time gated, dev-only, activated via existing dev entry point — no shake gesture)

## Capabilities

### New Capabilities

- `library-management`: Scan device storage for audio files; parse and store ID3/metadata; maintain an unencrypted Drift/SQLite library database; expose library views (All Songs, Albums, Artists, Genres); support manual refresh and automatic change detection
- `playback-engine`: Drive audio playback via `just_audio` through a unified `AudioSource` abstraction that handles both local files and remote streams (best-effort); manage playback queue and transport controls; handle background playback, system media session, gapless playback, and audio focus
- `player-ui`: Deliver the full player UI surface — Now Playing screen, persistent mini player (global shell widget), queue management view, album/artist detail screens, and local library search — using the Phase 1 design system and network-state primitives
- `playback-diagnostics`: Add Phase 2 debug overlay tabs — playback diagnostics panel (queue state, buffer status, audio session, stream source) and library scan log (files found/rejected, parse errors, scan duration); compile-time gated, never in release builds

### Modified Capabilities

## Impact

- **Dependencies added:** `just_audio`, `just_audio_background`, `audio_session`, `drift`, `drift_flutter`, `on_audio_query` (or equivalent metadata parser), `build_runner`
- **Platform permissions:** `READ_EXTERNAL_STORAGE` / `READ_MEDIA_AUDIO` (Android); `NSAppleMusicUsageDescription` / media library access (iOS)
- **Architecture:** introduces `AudioSource` abstraction in `lib/core/audio/`; `LibraryRepository` and `PlaybackRepository` in `lib/features/library/` and `lib/features/playback/`; Drift database schema in `lib/core/database/`; global shell widget wrapping go_router's navigator for the persistent mini player
- **Debug overlay:** two new tabs registered into the existing Phase 1 overlay infrastructure
- **No breaking changes** to Phase 1 scaffolding
