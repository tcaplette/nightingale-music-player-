## ADDED Requirements

### Requirement: Bottom navigation bar with three primary tabs
The app SHALL provide a persistent bottom navigation bar with three tabs: Library, Feed, and Discover. The bottom nav SHALL be visible on all three tab root screens and SHALL be hidden when a detail route (album, artist, now-playing, queue, profile, etc.) is pushed.

#### Scenario: User navigates between tabs
- **WHEN** the user taps the Feed tab in the bottom navigation bar
- **THEN** the Feed screen is shown and the Feed tab indicator is active

#### Scenario: Tab state is preserved on switch
- **WHEN** the user scrolls down in the Library tab, switches to Feed, then switches back to Library
- **THEN** the Library scroll position and selected sub-tab are restored to where they were before switching

#### Scenario: Mini-player persists across tabs
- **WHEN** a track is playing and the user switches between Library, Feed, and Discover tabs
- **THEN** the mini-player remains visible above the bottom navigation bar on all three tabs

### Requirement: Library AppBar contains only the Search action
The Library screen's AppBar SHALL contain exactly one action button: Search. Feed and Discover SHALL NOT appear as AppBar icons on the Library screen.

#### Scenario: Library AppBar has one action
- **WHEN** the Library screen is displayed
- **THEN** the AppBar shows a single Search icon action button and no Feed, Discover, or Refresh icon buttons

### Requirement: Library refresh via pull-to-refresh gesture
The Library screen SHALL support pull-to-refresh to trigger a library scan. A `RefreshIndicator` SHALL be present in each of the four library tab views (Songs, Albums, Artists, Genres).

#### Scenario: User pulls to refresh in Songs tab
- **WHEN** the user pulls down past the overscroll threshold in the Songs tab
- **THEN** a refresh indicator is shown and a library scan is triggered

#### Scenario: Scan progress shown inline
- **WHEN** a library scan is in progress
- **THEN** a `LinearProgressIndicator` is shown below the tab bar and the AppBar refresh icon button is NOT shown

### Requirement: Notifications accessible from Feed tab AppBar
The Notifications icon button and unread badge SHALL be present in the Feed screen's AppBar (not the Library AppBar).

#### Scenario: Unread badge visible on Feed AppBar
- **WHEN** there are unread notifications and the Feed screen is visible
- **THEN** the notifications icon in the Feed AppBar shows the unread count badge
