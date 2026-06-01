## Why

After a user connects their Mastodon account — either during onboarding or later — there is no visual confirmation that the connection was successful, leaving users uncertain whether anything actually happened. This creates a trust gap that undermines confidence in the feature.

## What Changes

- **MastodonImportScreen** gains a persistent connection badge showing "Connected as @handle@instance.social" (with a checkmark icon) once a handle has been validated and stored. The badge appears above the search results and persists across screen visits so users can always see which account is linked.
- **SettingsScreen** gains a **Mastodon account** tile under the existing "Federation & Discovery" section. When a handle is stored it shows the handle as the subtitle; when no handle is stored it shows "Not connected". Tapping the tile navigates to `MastodonImportScreen`.

## Capabilities

### New Capabilities

- `mastodon-connection-banner`: In-screen connection status indicator on `MastodonImportScreen` that surfaces the stored Mastodon handle (or a "not connected" prompt) so users always know which account is linked.
- `mastodon-settings-tile`: Settings entry point under Federation & Discovery that displays the connected Mastodon handle and allows the user to connect or change their account from the settings hub.

### Modified Capabilities

<!-- none — the underlying mastodon-account provider and storage requirements are unchanged -->

## Impact

- `lib/features/federation/screens/mastodon_import_screen.dart` — consume `mastodonAccountProvider` to render the connection banner
- `lib/features/settings/screens/settings_screen.dart` — add Mastodon account tile under Federation & Discovery section, consuming `mastodonAccountProvider`
- `lib/features/onboarding/mastodon_account_provider.dart` — no changes; already provides the data needed
- No new dependencies, no database changes, no API changes
