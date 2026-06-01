## Context

`mastodonAccountProvider` (a `FutureProvider<String?>`) already reads the stored Mastodon handle from `SecureStorageService` and is available to any Riverpod consumer. Both `MastodonImportScreen` and `SettingsScreen` are `ConsumerWidget`/`ConsumerStatefulWidget` contexts (or can trivially be converted), so the data layer requires zero changes. The work is purely UI: consume the provider in two places and render appropriate widgets.

## Goals / Non-Goals

**Goals:**
- Show a persistent "Connected as @handle" banner on `MastodonImportScreen` when a handle is stored
- Show the handle (or "Not connected") on a tile in `SettingsScreen` under Federation & Discovery
- Tile navigates to `MastodonImportScreen` so the user can connect or change their account

**Non-Goals:**
- Verifying that the stored handle is still reachable / valid on the Mastodon server
- Adding a "disconnect" or "remove account" action (the import screen already allows re-entry)
- Changing the storage layer or provider contract

## Decisions

### D1: Read `mastodonAccountProvider` directly in both screens — no new providers

The handle is already available via `mastodonAccountProvider`. Wrapping it in a new intermediate provider would add indirection with no benefit. Both screens simply watch the provider and render based on its `AsyncValue`.

**Alternative considered:** A dedicated `isMastodonConnectedProvider` (bool). Rejected — it loses the handle string needed to display "@handle" in the UI, and is just a thin map over the existing provider.

### D2: Banner position — above the search input, not below results

Placing the connection badge above the `TextField` gives it a fixed, predictable position regardless of whether results are showing. Users can always glance at the top of the screen to confirm their account without scrolling. Below results would bury it once a long result list loads.

### D3: Settings tile placement — inline in the existing "Federation & Discovery" section

Adding a dedicated "Connected Accounts" section would be premature — Mastodon is currently the only external account. A single tile under the existing Federation & Discovery section is the right scope; it can be promoted to its own section if more integrations are added later.

### D4: `MastodonImportScreen` converted to `ConsumerStatefulWidget`

It is already a `ConsumerStatefulWidget`, so watching `mastodonAccountProvider` is a one-line `ref.watch` addition with no structural refactor.

`SettingsScreen` is currently a `ConsumerWidget` — it stays that way; `ref.watch(mastodonAccountProvider)` is added alongside its existing `ref` usage.

## Risks / Trade-offs

- **AsyncValue loading flash**: `mastodonAccountProvider` is async (reads from secure storage). On screen entry there's a brief `loading` state before the handle resolves. → Mitigation: render nothing (or a neutral placeholder) during loading; the tile/banner appears as soon as the value resolves. This is sub-100ms on device and not noticeable in practice.
- **Stale value after handle change**: If the user updates their handle in `MastodonImportScreen`, `mastodonAccountProvider` must be invalidated so the Settings tile refreshes. The existing pattern (`ref.invalidate(mastodonAccountProvider)`) is already used elsewhere; just ensure it is called after `setMastodonHandle`.
