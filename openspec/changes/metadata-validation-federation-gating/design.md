## Context

Nightingale is a Flutter music player and ActivityPub federation node. Tracks in the local library are scanned via `on_audio_query`, stored in a Drift/SQLite database, and optionally published as ActivityPub `Audio` objects to the network. Phase 4 shipped library publishing, streaming, and acoustic fingerprint deduplication. No metadata completeness check currently exists — any track, regardless of how sparsely tagged, can be included in the published Collection.

The `metadata_god` package (`^0.3.0+1`) is already declared in `pubspec.yaml` but is unused. It supports both reading and writing ID3v2 (MP3) and Vorbis Comments (FLAC/OGG) tags. This is the write path for the editor.

ISRC codes are stored in `TSRC` frames (ID3v2) and `ISRC=` keys (Vorbis Comments). They are present in a meaningful subset of well-sourced libraries (purchased downloads, quality CD rips) and are cheaper to compare than acoustic fingerprints.

## Goals / Non-Goals

**Goals:**
- Define a typed, centralized completeness contract for the 7 required fields
- Surface completeness status visually on track tiles (badge) scoped to the user's published library
- Let users repair incomplete tags without leaving the app (bottom sheet editor + file write-back)
- Block all federation paths from emitting tracks that fail validation
- Use ISRC as a cheaper first-pass signal before Chromaprint comparison

**Non-Goals:**
- Requiring ISRC or MBID from users — these are read-only from files
- Validating or editing local-only tracks (gate and badge are sharing-scoped)
- Auto-fetching metadata from MusicBrainz, Discogs, or any remote service (out of scope for this change)
- Bulk-editing multiple tracks at once
- Validating remote/federated tracks received from other nodes

## Decisions

### 1. Validator as a pure service, not a database column

**Decision:** `MetadataValidator` is a stateless service that computes completeness on the fly from a `TrackModel`. Completeness is NOT stored as a column.

**Rationale:** Completeness is a derived property — it changes whenever any of the 7 fields changes. Storing it would require invalidation logic on every metadata write. A pure function over the model is simpler, always consistent, and cheap to compute (just null/empty checks).

**Alternative considered:** A `isMetadataComplete` boolean column in the database. Rejected because it introduces a cache that can drift out of sync and adds migration complexity without meaningful performance gain.

---

### 2. Badge visibility gated on sharing membership

**Decision:** The red/green badge renders only on tracks that are members of the user's published library (i.e. sharing is enabled and the track is in scope). Tracks outside the published library render no badge.

**Rationale:** Badging every track in a large library with incomplete tags (common for personal rips) would produce a wall of red dots — visually overwhelming and not actionable for tracks the user has no intention of sharing. The badge is a signal for tracks that *need* action, not a global metadata audit report.

**Alternative considered:** Show badges on all tracks, with a toggle in settings to hide them. Rejected — adds settings surface area for marginal gain.

---

### 3. ISRC as first-pass deduplication signal

**Decision:** `AcousticFingerprintService.findDuplicates()` checks ISRC equality first. If both tracks have a non-null, non-empty ISRC and they match, they are treated as the same recording without computing Chromaprint similarity.

**Rationale:** Chromaprint fingerprinting requires reading audio data — it is I/O and CPU intensive. ISRC comparison is a string equality check. For well-sourced libraries where ISRC is present, this is a free win. If either track lacks an ISRC, the existing Chromaprint path runs unchanged.

**Alternative considered:** Always run Chromaprint and treat ISRC as a secondary signal. Rejected — no benefit and burns resources unnecessarily on files where ISRC is definitive.

---

### 4. `metadata_god` for tag write-back (not shell or FFI)

**Decision:** The metadata editor writes values to the physical file using `metadata_god`'s Dart-native API. No shell commands, no FFI wrappers.

**Rationale:** `metadata_god` is already in pubspec. It supports the two primary formats in scope (MP3 ID3v2, FLAC Vorbis Comments) and provides a consistent write API from Dart. Using it keeps the dependency surface stable.

**Risk:** `metadata_god` does not support all container formats (e.g. AAC/M4A atoms have inconsistent support). On an unsupported format, the write fails gracefully — the editor reports an error and the DB is not updated.

---

### 5. DB update only after confirmed file write

**Decision:** The Drift/SQLite record is only updated after `metadata_god` confirms the file write succeeded. If the write fails, the DB remains unchanged.

**Rationale:** The file is the source of truth. If the DB were updated optimistically and the file write failed (permissions, read-only storage, unsupported format), the DB and file would be out of sync — a library rescan would immediately revert the DB change, confusing the user.

---

### 6. Federation gate as a cross-cutting guard

**Decision:** A `MetadataGate` class wraps all outbound federation paths: `LibraryPublisher.publishTrack()`, `ActivityService.announce()`, and the library Collection endpoint. It runs `MetadataValidator.validate()` and throws a typed `MetadataIncompleteException` (carrying the list of missing fields) if validation fails. Callers catch this exception and present the editor.

**Rationale:** Centralizing the gate in one class ensures no federation path can accidentally bypass validation. Distributing checks inline across multiple services creates an audit problem as new sharing paths are added.

## Risks / Trade-offs

**Read-only storage / permissions** → `metadata_god` writes require write permission to the file. On Android, files in app-private storage are writable; files on external SD cards or certain shared-storage paths may not be. Mitigation: catch `FileSystemException` on write, surface a clear "cannot edit this file's tags — check storage permissions" message. The track remains flagged.

**Partial-metadata files from poor rippers** → Many tracks in personal libraries are missing genre or release year because the ripper didn't populate them. These tracks will be permanently red-dotted (if in the published set) until the user edits them. Mitigation: the editor bottom sheet surfaces only the missing fields, minimising friction. No mitigation for bulk cases — auto-fetch from external services is out of scope.

**ISRC collisions** → ISRC codes are theoretically unique per recording but re-use does occur with bootleg files and some ripping tools copy the wrong code. Mitigation: ISRC match is a dedup *signal*, not a merge — the full dedup flow (provenance, reversibility) still applies; false positives can be undone.

**`metadata_god` format coverage** → The library handles MP3 (ID3v2) and FLAC (Vorbis Comments) well; AAC/M4A support is inconsistent. Mitigation: detect write failure and inform the user. The track stays flagged; they can still share it if they fix tags via an external tool.

## Migration Plan

1. Add `isrc TEXT` column to `TracksTable` with a Drift schema migration (nullable, no default required — existing rows get `NULL`).
2. On the next library scan after migration, ISRC is populated for files that have it; NULL for files that don't. No full rescan required — ISRC is read opportunistically on the next scan pass.
3. `MetadataValidator` is a new service with no breaking interface; existing code has no dependency on it.
4. The federation gate wraps existing publishers — existing call sites get a compile error if they skip the gate, which is the desired outcome (forces audit of all publishing paths).
5. No rollback needed — the `isrc` column is nullable and additive. If the gate is reverted, publishing returns to its previous ungated behaviour.

## Open Questions

- **Artwork write-back scope:** `metadata_god` can write embedded artwork. Should the editor support replacing artwork (upload from gallery), or is artwork editing out of scope for this change? (Recommend: out of scope — add in a follow-on.)
- **Badge in mini-player and Now Playing screen:** Should the badge appear outside of library list views? (Recommend: library tile only for now.)
