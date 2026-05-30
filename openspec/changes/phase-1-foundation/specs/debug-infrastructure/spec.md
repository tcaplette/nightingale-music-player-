## ADDED Requirements

### Requirement: AppLogger wraps dart:developer with typed, structured log events
`lib/core/logging/app_logger.dart` SHALL provide an `AppLogger` class (or top-level functions) with severity levels: `verbose`, `debug`, `info`, `warning`, `error`, `fatal`. Every log call SHALL accept a `tag` (String, identifying the subsystem) and a `message`. Error-level calls SHALL also accept an optional `error` object and `stackTrace`. No production code SHALL call `print()` or `debugPrint()` directly; all logging SHALL go through `AppLogger`.

#### Scenario: Feature logs an info event
- **WHEN** a feature calls `AppLogger.info(tag: 'router', message: 'Navigated to home')`
- **THEN** in debug builds, the event SHALL appear in the debug overlay's log stream
- **THEN** in debug builds, the event SHALL also appear in `dart:developer`'s log (visible in Flutter DevTools)
- **THEN** in release builds, the call SHALL be a no-op with no console output

#### Scenario: Error logged with stack trace
- **WHEN** a catch block calls `AppLogger.error(tag: 'network', message: 'Request failed', error: e, stackTrace: st)`
- **THEN** in debug builds, the event SHALL appear in the overlay log stream with full stack trace
- **THEN** in release builds, the event SHALL be forwarded to the crash-reporting stub

### Requirement: Structured log events emitted to an in-app stream in debug builds
In debug builds, `AppLogger` SHALL emit typed `LogEvent` objects to a `StreamController<LogEvent>` accessible from `lib/core/logging/`. The debug overlay SHALL consume this stream to display a live log feed. The stream SHALL be `broadcast` type. In release builds, the `StreamController` SHALL NOT exist.

#### Scenario: Debug overlay subscribes to log stream
- **WHEN** the debug overlay is opened in a debug build
- **THEN** it SHALL subscribe to `AppLogger.logStream` and display incoming events in real time
- **THEN** closing the overlay SHALL cancel the subscription (no memory leak)

### Requirement: In-app debug overlay exists only in debug builds and is compile-time gated
The debug overlay widget and all of its dependencies SHALL be wrapped in `kDebugMode` checks or placed in files imported only under debug conditions. The release build SHALL contain no overlay code, no log stream, and no activation mechanism. Flutter's tree-shaking of `kDebugMode` false branches SHALL be relied upon, verified by examining the release APK/IPA.

#### Scenario: Release build contains no overlay
- **WHEN** the app is built in release mode (`flutter build apk --release`)
- **THEN** the resulting binary SHALL contain no overlay widget code
- **THEN** the app SHALL not display any debug UI under any interaction sequence

### Requirement: Debug overlay activated via tap sequence, never shake gesture
In debug builds, the debug overlay SHALL be activatable by tapping the app version label in the Settings screen 7 times in succession (or via a prominently visible debug-build-only floating action button on the home screen — one method SHALL be chosen and documented). The shake gesture SHALL NOT be used as an activation mechanism.

#### Scenario: Tap sequence activates overlay
- **WHEN** a developer taps the version label 7 times on the Settings screen in a debug build
- **THEN** the debug overlay SHALL appear as a `Stack` layer above all other content
- **THEN** the overlay SHALL be dismissible by tapping an "X" or swiping it down

#### Scenario: Shake does not activate overlay
- **WHEN** a developer shakes the device in a debug build
- **THEN** no debug overlay SHALL appear
- **THEN** the shake event SHALL not be intercepted or consumed by the overlay logic

### Requirement: Debug overlay has two tabs in Phase 1: Logs and Info
The overlay SHALL display two tabs: **Logs** (live log stream, filterable by severity level and tag) and **Info** (app version, build number, environment name, current route). The overlay SHALL be non-blocking: it SHALL NOT intercept navigation, pointer events outside its own bounds, or widget tests.

#### Scenario: Logs tab filters by severity
- **WHEN** the overlay is open on the Logs tab and the user selects "warning and above"
- **THEN** only log events with severity `warning`, `error`, or `fatal` SHALL be displayed
- **THEN** `verbose`, `debug`, and `info` events SHALL be hidden without clearing the stream

#### Scenario: Info tab shows build information
- **WHEN** the overlay is open on the Info tab
- **THEN** the app version string, build number, environment name (`dev`/`staging`/`prod`), and current route path SHALL be visible

### Requirement: Error boundary widgets catch Flutter errors gracefully in dev
`lib/shared/components/error_boundary.dart` SHALL provide an `ErrorBoundaryWidget` that wraps its child in a Flutter error handler. In debug builds, when the child throws a rendering error, the boundary SHALL display the error message and stack trace in a styled, readable format. In release builds, the boundary SHALL display a generic, user-facing error message and forward the error to the crash-reporting stub.

#### Scenario: Widget rendering error caught in debug
- **WHEN** a child widget throws an exception during `build()` in a debug build
- **THEN** `ErrorBoundaryWidget` SHALL catch the error via `ErrorWidget.builder`
- **THEN** the boundary SHALL render a panel showing the exception type, message, and stack trace
- **THEN** the rest of the app outside the boundary SHALL remain functional

#### Scenario: Widget rendering error in release
- **WHEN** a child widget throws an exception during `build()` in a release build
- **THEN** the boundary SHALL render a generic "Something went wrong" message
- **THEN** the error SHALL be forwarded to the crash-reporting stub (not shown to the user)

### Requirement: Crash reporting stub is wired but inert in Phase 1
`lib/core/crash_reporting/crash_reporter.dart` SHALL define a `CrashReporter` abstract interface with a `recordError(error, stackTrace)` method and a `NullCrashReporter` no-op implementation. The app SHALL register `NullCrashReporter` in dev and prod until a real provider is chosen. All crash reporting call sites (`AppLogger` error/fatal level, `ErrorBoundaryWidget`) SHALL route through this interface so that wiring a real provider in a future phase requires only a registration change.

#### Scenario: Error reported in Phase 1
- **WHEN** a fatal error is logged via `AppLogger.fatal(...)` in Phase 1
- **THEN** `CrashReporter.recordError(...)` SHALL be called
- **THEN** the `NullCrashReporter` SHALL silently discard the call
- **THEN** no crash reporting SDK SHALL be initialized or networked

### Requirement: Network request inspector exists in dev builds as a debug overlay tab stub
A **Network** tab SHALL be present in the Phase 1 debug overlay as a stub (empty state with a "No requests recorded yet" message). The underlying `NetworkInspector` service SHALL be wired into the HTTP client layer so that Phase 3, when it adds real HTTP calls, can populate the inspector without structural changes to the overlay.

#### Scenario: Network tab shown in Phase 1
- **WHEN** the debug overlay is open and the user taps the Network tab
- **THEN** the tab SHALL display an empty state message ("No requests recorded yet")
- **THEN** no exception SHALL be thrown accessing the empty inspector

#### Scenario: Inspector is ready for Phase 3 wiring
- **WHEN** Phase 3 makes HTTP requests through the app's HTTP client
- **THEN** those requests SHALL be capturable by `NetworkInspector` without modifying the overlay widget code
