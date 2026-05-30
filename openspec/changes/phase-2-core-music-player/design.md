## Context

Phase 1 delivered the project skeleton: Riverpod state management, go_router navigation, a token-based design system, network-state UI primitives, and a compile-time-gated debug overlay. Phase 2 adds the first user-facing product layer — a fully functional local music player — and must do so in a way that does not require structural rework in Phase 4 when remote streaming is introduced. The single most consequential architectural decision is the `AudioSource` abstraction: how local and remote audio are unified behind one interface from day one.

This is a cross-cutting change: new database schema, new repository layer, new Riverpod providers, new go_router routes, new global shell widget, and new debug overlay tabs all interact.

## Goals / Non-Goals

**Goals:**
- Deliver a working local music player (library scanning, playback, full player UI)
- Establish the `AudioSource` abstraction so Phase 4 remote streaming slots in without a rewrite
- Keep the Drift database unencrypted — this is a deliberate, documented decision, not an oversight
- Persist the mini player across all screens via a global shell widget
- Add Phase 2 debug overlay tabs (playback diagnostics, library scan log) using the Phase 1 overlay infrastructure
- Use Phase 1 network-state UI components in the playback UI from day one

**Non-Goals:**
- Remote/federated audio streaming (Phase 4)
- Any form of database encryption (sensitive material is handled in Phases 3 and 6)
- Playlist management beyond queue (Phase 5)
- Recommendations or social features (Phases 5–6)
- Any P2P or ActivityPub work

## Decisions

### Decision 1: Unified `AudioSource` abstraction

**Choice:** Introduce an `AudioSource` sealed class in `lib/core/audio/` with two concrete subtypes — `LocalAudioSource` (wraps a file path) and `RemoteAudioSource` (wraps a URI with best-effort semantics). The `PlaybackEngine` operates exclusively on `AudioSource` and never branches on source type directly.

**Rationale:** Phase 4 must add remote streaming without touching existing playback logic. If Phase 2 is written to accept file paths directly, Phase 4 becomes a refactor rather than an extension. The sealed class costs almost nothing now and eliminates a known future migration.

**Alternative considered:** Just use `just_audio`'s `AudioSource` directly — rejected because `just_audio`'s type hierarchy leaks transport concerns into UI-layer code and makes the remote best-effort semantics (buffering, fallback) harder to model cleanly.

---

### Decision 2: Drift/SQLite — unencrypted, explicitly

**Choice:** The library database uses Drift on top of SQLite with no encryption layer.

**Rationale:** Per the ROADMAP: "The album list is not sensitive; encrypting it adds key-management and performance friction for no security benefit. Sensitive material (the private key, the taste profile) is encrypted specifically and separately." This is a product-level decision, not a technical oversight. Encryption is applied in Phase 3 (private key) and Phase 6 (taste profile).

**Alternative considered:** `sqflite_sqlcipher` — rejected, adds key management complexity and cold-start latency for zero security benefit on a music catalog.

---

### Decision 3: Mini player as global shell widget

**Choice:** Wrap go_router's `Navigator` in a `PlayerShell` widget that renders the mini player as an overlay. The mini player is always in the widget tree; its visibility is controlled by a `PlaybackStateNotifier` provider.

**Rationale:** go_router does not have a native persistent bottom-bar slot that survives route transitions without re-rendering. A shell widget above the navigator is the idiomatic Flutter pattern for persistent UI. This approach keeps the mini player's state entirely in Riverpod and avoids per-route widget duplication.

**Alternative considered:** `ShellRoute` in go_router — viable but couples the mini player's visibility to the route hierarchy rather than to playback state; a track playing on a detail screen would need explicit route-level coordination.

---

### Decision 4: `just_audio` + `just_audio_background` + `audio_session`

**Choice:** `just_audio` for playback, `just_audio_background` for system media session integration (lock screen controls, notification), `audio_session` for audio focus management.

**Rationale:** This is the canonical Flutter audio stack. `just_audio` already exposes an `AudioSource` type hierarchy and supports gapless concatenation natively. `audio_session` handles platform audio focus rules (pause on call, duck on notification) with a declarative API. All three are maintained by the same author and compose cleanly.

**Alternative considered:** `audioplayers` — less capable gapless support; `media_kit` — heavier dependency, better for desktop/TV; overkill for mobile.

---

### Decision 5: Metadata parsing strategy

**Choice:** Use `on_audio_query` for bulk library scanning (device media store queries on Android, `MPMediaQuery` on iOS) with `metadata_god` or `ffmpeg_kit_flutter_audio` as fallback for files not indexed by the OS media scanner.

**Rationale:** OS media store queries are orders of magnitude faster than per-file tag parsing for large libraries. Parsing every file individually at first launch would block the UI. Fall back to direct tag reading only for files the media store missed.

**Alternative considered:** Parse all files with `ffmpeg_kit` — correct but slow; a 5000-track library would take 30–60s to scan. `on_audio_query` first is the right performance trade.

---

### Decision 6: Library change detection

**Choice:** On app resume and after a manual refresh, re-query the OS media store and diff against the stored library. Do not use filesystem watchers.

**Rationale:** Filesystem watchers on mobile are unreliable — iOS restricts them to app sandbox, Android behavior varies across OEMs. Re-querying the media store on resume is both reliable and cheap (indexed query, not filesystem walk). Manual refresh is the escape hatch for cases where the app is not foregrounded.

---

### Decision 7: Debug overlay integration

**Choice:** Register two new tabs into the Phase 1 overlay infrastructure: `PlaybackDiagnosticsTab` and `LibraryScanTab`. Each tab is a Riverpod consumer widget that reads from a `PlaybackDiagnosticsNotifier` and `LibraryScanLogNotifier` respectively. Both providers are only registered in dev builds via a compile-time flag.

**Rationale:** Consistent with the Phase 1 pattern. No new overlay entry points or activation mechanisms — the existing dev-only entry point is used unchanged. Adding providers at the DI layer under a compile-time flag ensures zero overhead in release builds.

## Risks / Trade-offs

**OS media store delays on Android** → Newly downloaded files may not appear in the media store immediately. Mitigation: surface a "Library may be incomplete" state in the UI using the Phase 1 partial-library network-state component; manual refresh is always available.

**`just_audio_background` lock screen controls on iOS** → Requires `UIBackgroundModes: audio` entitlement. If the entitlement is missing, background playback silently stops. Mitigation: verify entitlement in `Runner.entitlements` and add a phase-specific check to the debug overlay.

**Gapless playback on older Android** → `just_audio` gapless concatenation relies on ExoPlayer's `ConcatenatingMediaSource`, which has known issues on Android < 8. Mitigation: accept the regression on Android < 8 (below our minimum supported SDK if we set it to API 26+); document the minimum.

**Drift migration versioning from the start** → Every schema change after ship requires a migration. Mitigation: define the full Phase 2 schema up front, resist adding columns mid-phase without a migration, and establish the migration pattern now.

**`RemoteAudioSource` in Phase 2 is a stub** → `RemoteAudioSource` exists in the type system but is unused by Phase 2 UI. Risk: it gets deleted during "cleanup" before Phase 4. Mitigation: include it in the `AudioSource` sealed class from day one and add a `// Phase 4: remote streaming extends this` comment on the class.

## Open Questions

- **Minimum Android SDK target:** API 26 (Android 8) eliminates the ExoPlayer gapless issue and covers ~96% of active devices. Confirm before locking the `minSdkVersion`.
- **Artwork caching strategy:** Store artwork as file paths in the database (blobs are expensive in SQLite) or use a separate `cached_network_image`-style disk cache? For Phase 2 (local only) file paths are fine; confirm before Phase 4 adds remote artwork.
- **`on_audio_query` vs direct `MediaStore` queries:** `on_audio_query` 3.x changed its API. Confirm the current stable API matches what Phase 2 needs before locking the dependency.
