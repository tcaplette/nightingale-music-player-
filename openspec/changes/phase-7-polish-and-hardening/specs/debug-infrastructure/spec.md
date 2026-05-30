## MODIFIED Requirements

### Requirement: Crash reporting stub is wired but inert in Phase 1
`lib/core/crash_reporting/crash_reporter.dart` SHALL define a `CrashReporter` abstract interface with a `recordError(error, stackTrace)` method. In Phase 7, the app SHALL register a real `SentryCrashReporter` implementation in release builds (initialized with a `SENTRY_DSN` build-time environment variable) and retain `NullCrashReporter` for debug and staging builds. The `SentryCrashReporter` SHALL implement a `beforeSend` allowlist that permits only: exception type, anonymized stack trace, app version string, and OS platform. All call sites (`AppLogger` error/fatal level, `ErrorBoundaryWidget`) remain unchanged — the switch is purely a registration change at app startup.

#### Scenario: Error reported in Phase 7 release build
- **WHEN** a fatal error is logged via `AppLogger.fatal(...)` in a release build with `SENTRY_DSN` set
- **THEN** `CrashReporter.recordError(...)` SHALL be called
- **THEN** `SentryCrashReporter` SHALL transmit the event to Sentry with only the allowlisted fields
- **THEN** no username, node URL, or file path SHALL be present in the transmitted event

#### Scenario: Missing DSN falls back to NullCrashReporter
- **WHEN** the app is built in release mode without `SENTRY_DSN` set
- **THEN** `NullCrashReporter` SHALL be registered silently
- **THEN** no Sentry SDK SHALL be initialized and no network call SHALL be made

#### Scenario: Debug build always uses NullCrashReporter
- **WHEN** the app runs in a debug build regardless of environment variables
- **THEN** `NullCrashReporter` SHALL be registered
- **THEN** `SentryCrashReporter` SHALL NOT be instantiated

## ADDED Requirements

### Requirement: All diagnostic code is stripped from release builds via a single compile-time constant
`lib/core/debug/diagnostics.dart` SHALL export `const bool kDiagnosticsEnabled = !kReleaseMode`. Every debug overlay widget, `Timeline` marker call, `AppLogger` log stream instantiation, and `NetworkInspector` registration SHALL be gated behind `if (kDiagnosticsEnabled)` or equivalent tree-shakeable guards. Flutter's release-mode tree-shaker SHALL eliminate all `kDiagnosticsEnabled == false` branches. No debug-only symbol SHALL appear in a release binary.

#### Scenario: Release build strips diagnostic code
- **WHEN** the app is built with `flutter build apk --release`
- **THEN** the release binary SHALL NOT contain the symbol `DebugOverlay`
- **THEN** the release binary SHALL NOT contain `NetworkInspector`
- **THEN** no `Timeline.startSync` call outside of startup profiling markers SHALL execute in production

#### Scenario: Debug build retains full overlay
- **WHEN** the app is run in debug mode
- **THEN** `kDiagnosticsEnabled` SHALL be `true`
- **THEN** all overlay tabs SHALL be available including the Phase 7 Performance tab
- **THEN** the activation sequence (7-tap on version label) SHALL work as specified in Phase 1
