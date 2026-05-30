## ADDED Requirements

### Requirement: A Performance tab is added to the debug overlay
The Phase 1 debug overlay SHALL gain a new **Performance** tab (compile-time gated, debug builds only). The tab SHALL display: current and average frame render time (ms), peak frame time in the last 60 s, current RSS memory (MB), active network connections and bytes transferred in the current session, active remote stream count and per-stream latency (ms), and cache hit rate for both the audio cache and the image cache.

#### Scenario: Performance tab shows frame render times
- **WHEN** the debug overlay is open on the Performance tab in a debug build
- **THEN** the current frame render time SHALL update every frame (via `SchedulerBinding.instance.addTimingsCallback`)
- **THEN** peak frame time over the last 60 s SHALL be displayed

#### Scenario: Performance tab shows memory usage
- **WHEN** the debug overlay is open on the Performance tab
- **THEN** the current RSS memory in MB SHALL be visible
- **THEN** the value SHALL refresh at least every 5 s

#### Scenario: Performance tab shows cache hit rate
- **WHEN** the debug overlay is open on the Performance tab after a session with remote streams
- **THEN** the audio cache hit rate (hits / total requests) SHALL be displayed as a percentage
- **THEN** the image cache hit rate SHALL also be displayed

#### Scenario: Performance tab is absent in release build
- **WHEN** the app is built in release mode
- **THEN** the Performance tab SHALL NOT be present in any UI
- **THEN** `SchedulerBinding.addTimingsCallback` SHALL NOT be registered

### Requirement: Production error reporting is wired in release builds only
In release builds, `CrashReporter` SHALL be backed by a real Sentry client initialized with a DSN from the build-time environment variable `SENTRY_DSN`. `PlatformDispatcher.instance.onError` and `FlutterError.onError` SHALL both route to `CrashReporter.recordError`. A `beforeSend` allowlist SHALL ensure only safe fields (exception type, anonymized stack trace, app version, platform) are transmitted; any field that could identify a user (node URL, username, file path) SHALL be stripped.

#### Scenario: Unhandled exception reported in release build
- **WHEN** an unhandled exception occurs in a release build with `SENTRY_DSN` set
- **THEN** `CrashReporter.recordError` SHALL be called with the exception and stack trace
- **THEN** Sentry SHALL receive an event containing the exception type, app version, and platform
- **THEN** the event SHALL NOT contain any node URL, username, or file path

#### Scenario: Missing DSN disables reporting silently
- **WHEN** the app is built in release mode without `SENTRY_DSN` set
- **THEN** `CrashReporter` SHALL fall back to `NullCrashReporter` silently
- **THEN** no exception or startup warning SHALL occur

#### Scenario: Error reporting absent in debug build
- **WHEN** the app runs in a debug build
- **THEN** `CrashReporter` SHALL use `NullCrashReporter` regardless of whether `SENTRY_DSN` is set
- **THEN** no network call to Sentry SHALL be made

### Requirement: All diagnostic code is stripped from release builds via compile-time flags
The single compile-time constant `kDiagnosticsEnabled = !kReleaseMode` SHALL gate the entire debug overlay, all `Timeline` marker calls, the `AppLogger` log stream, and the `NetworkInspector`. Flutter's tree-shaker SHALL eliminate all branches where `kDiagnosticsEnabled` is `false`. A release build verification step SHALL confirm no overlay widget symbols appear in the release binary.

#### Scenario: Release build strips overlay symbols
- **WHEN** the app is built with `flutter build apk --release`
- **THEN** `strings` or `grep` on the output binary SHALL NOT find `DebugOverlay`, `PerformanceOverlayTab`, or `NetworkInspector` symbol names
- **THEN** the APK size for the release build SHALL be measurably smaller than the debug build
