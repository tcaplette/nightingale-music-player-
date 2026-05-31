## ADDED Requirements

### Requirement: User can toggle new-follower notifications
The app SHALL provide a **New Followers** toggle in Notification settings. When disabled, new-follower entries SHALL NOT appear in the in-app notification centre (`NotificationsScreen`). The default SHALL be enabled.

#### Scenario: New-follower notifications are on by default
- **WHEN** the user opens Notification settings for the first time
- **THEN** the New Followers toggle is on

#### Scenario: Disabling hides new-follower entries from the notification centre
- **WHEN** the user disables New Followers and a follow event arrives
- **THEN** no new-follower notification appears in NotificationsScreen

#### Scenario: Re-enabling restores new-follower entries
- **WHEN** the user re-enables New Followers
- **THEN** subsequent follow events produce entries in NotificationsScreen

---

### Requirement: User can toggle activity-feed notifications
The app SHALL provide an **Activity from People I Follow** toggle. When disabled, activity-feed entries (likes, listens, shares from followed accounts) SHALL NOT appear in `NotificationsScreen`. The default SHALL be enabled.

#### Scenario: Activity notifications are on by default
- **WHEN** the user opens Notification settings for the first time
- **THEN** the Activity toggle is on

#### Scenario: Disabling suppresses activity entries
- **WHEN** the user disables the Activity toggle and a followed account publishes a Listen
- **THEN** no notification entry is created in NotificationsScreen

---

### Requirement: User can configure automatic notification cleanup
The app SHALL provide an **Auto-Clear Read Notifications** setting with options: **7 days**, **30 days**, **Never** (default). Read notifications older than the selected threshold SHALL be automatically removed from the notification centre.

#### Scenario: Default auto-clear is Never
- **WHEN** the user opens Notification settings for the first time
- **THEN** Auto-Clear shows Never

#### Scenario: 7-day cleanup removes old read notifications
- **WHEN** the user selects 7 days and a read notification is older than 7 days
- **THEN** that notification is absent from NotificationsScreen on next open

#### Scenario: Changing from Never to 30 days cleans up immediately on next open
- **WHEN** the user changes Auto-Clear from Never to 30 days
- **THEN** on next open of NotificationsScreen, read notifications older than 30 days are gone

#### Scenario: Never retains all read notifications indefinitely
- **WHEN** the user selects Never
- **THEN** read notifications are never automatically removed regardless of age
