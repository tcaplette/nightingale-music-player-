## 1. Project Initialization

- [x] 1.1 Create Flutter project with `flutter create nightingale --platforms=ios,android` and pin minimum SDK to latest stable in `pubspec.yaml`
- [x] 1.2 Create folder structure: `lib/core/`, `lib/features/`, `lib/shared/components/`, `lib/shared/theme/`, `lib/shared/utils/`
- [x] 1.3 Add `analysis_options.yaml` extending `flutter_lints` with project-specific rule overrides (prefer_const_constructors, avoid_print, etc.)
- [x] 1.4 Verify `dart analyze` passes clean and `dart format --set-exit-if-changed .` exits 0 on the initial project
- [x] 1.5 Create environment config scaffold: `lib/core/config/env_config.dart` with `Environment` enum (`dev`, `staging`, `prod`) and `AppConfig` class driven by `--dart-define=ENV=dev`
- [x] 1.6 Create `main_dev.dart`, `main_staging.dart`, `main_prod.dart` entry points each passing the appropriate `Environment` to `AppConfig`

## 2. Dependencies

- [x] 2.1 Add to `pubspec.yaml`: `flutter_riverpod`, `riverpod_annotation`, `go_router`, `get_it`, `cached_network_image`
- [x] 2.2 Add dev dependencies: `riverpod_generator`, `build_runner`, `custom_lint`, `riverpod_lint`
- [x] 2.3 Run `flutter pub get` and confirm no version conflicts
- [x] 2.4 Configure `build_runner` in `pubspec.yaml` (or `build.yaml`) and run first codegen pass: `dart run build_runner build`

## 3. Dependency Injection & Repository Pattern

- [x] 3.1 Create `lib/core/di/service_locator.dart` with a `setupServiceLocator()` function using `get_it`; call it in all `main_*.dart` before `runApp()`
- [x] 3.2 Create `lib/core/repositories/base_repository.dart` with an abstract `Repository` interface (or marker class) and a README comment establishing the convention: all data source access goes through a repository interface
- [x] 3.3 Add a stub `AppInfoRepository` (returns app version, build number, environment) as the first concrete repository; register it in `service_locator.dart`

## 4. Navigation

- [x] 4.1 Create `lib/core/router/app_router.dart` with a `GoRouter` instance and a root `/` route pointing to a placeholder `HomeScreen`
- [x] 4.2 Define typed route classes using `@TypedGoRoute` annotation for the root route; run codegen to generate `.g.dart` file
- [x] 4.3 Create placeholder `HomeScreen` widget in `lib/features/home/home_screen.dart` (a scaffold with an app bar and centered text)
- [x] 4.4 Wire `AppRouter.router` into `MaterialApp.router` in the app root widget

## 5. Design Tokens

- [x] 5.1 Create `lib/shared/theme/app_colors.dart`: define neutral palette constants and semantic aliases (`onSurface`, `background`, `surfaceVariant`, `error`, `accent`) for both light and dark modes
- [x] 5.2 Create `lib/shared/theme/app_typography.dart`: define `TextTheme` with 6 named styles (displayLarge, titleMedium, bodyLarge, bodyMedium, labelMedium, labelSmall) using a system font stack
- [x] 5.3 Create `lib/shared/theme/app_spacing.dart`: define `xs=4`, `sm=8`, `md=16`, `lg=24`, `xl=32`, `xxl=48` as `const double` constants
- [x] 5.4 Create `lib/shared/theme/app_radius.dart`: define `sm=4`, `md=8`, `lg=16`, `full=9999` as `const double` constants
- [x] 5.5 Create `lib/shared/theme/app_motion.dart`: define `Duration` constants (`micro=150ms`, `standard=300ms`, `emphasis=500ms`) and `Curve` constants for each
- [x] 5.6 Create `lib/shared/theme/app_theme.dart`: build `ThemeData lightTheme` and `ThemeData darkTheme` from the tokens; configure `MaterialApp` with both
- [x] 5.7 Confirm the app boots and renders `HomeScreen` in both light and dark mode (toggle via system settings or `ThemeMode.dark` override in `main_dev.dart`)

## 6. Base Component Library

- [x] 6.1 Create `lib/shared/components/buttons/app_button.dart`: primary and secondary variants, uses `AppColors` and `AppMotion`, supports disabled state
- [x] 6.2 Create `lib/shared/components/inputs/app_text_input.dart`: labeled text field, uses `AppColors`, `AppTypography`, `AppSpacing`; no business logic
- [x] 6.3 Create `lib/shared/components/cards/app_card.dart`: container with `AppRadius.md`, `AppSpacing.md` padding, surface color from theme
- [x] 6.4 Create `lib/shared/components/sheets/app_bottom_sheet.dart`: wrapper function `showAppBottomSheet(context, child)` with consistent drag handle and padding
- [x] 6.5 Create `lib/shared/components/modals/app_modal.dart`: wrapper function `showAppModal(context, child)` with consistent title bar, close button, and padding
- [x] 6.6 Add `HomeScreen` component gallery: a scrollable list of each component in all states, used as a visual regression reference during development

## 7. Network-State Primitives

- [x] 7.1 Create `lib/shared/components/network_state/buffering_widget.dart` with `statusLabel` parameter; spinner + label, fully styled with design tokens
- [x] 7.2 Create `lib/shared/components/network_state/host_offline_widget.dart` with `displayName` and `lastSeenAt` (nullable DateTime) parameters; styled offline indicator
- [x] 7.3 Create `lib/shared/components/network_state/stream_failed_playing_local_widget.dart`: non-intrusive banner, design-token styled
- [x] 7.4 Create `lib/shared/components/network_state/partial_library_widget.dart`: subtle indicator widget with design-token styling
- [x] 7.5 Add all four network-state widgets to the `HomeScreen` component gallery
- [x] 7.6 Write widget tests in `test/shared/components/network_state/` for all four widgets: verify they render without exception and display key content

## 8. Identity Presentation Primitive

- [x] 8.1 Create `lib/shared/components/identity/person_display.dart`: `PersonDisplay` widget with `displayName` (required), `avatarUrl` (nullable), `handle` (nullable), `showHandle` (bool, default false)
- [x] 8.2 Implement initials-monogram fallback: derive 1–2 initials from `displayName`, render in a styled `CircleAvatar` using `AppColors` and `AppSpacing`
- [x] 8.3 Implement image-load-error fallback: use `CachedNetworkImage`'s `errorWidget` to fall back to the monogram when the URL fails to load
- [x] 8.4 Implement `showHandle: true` rendering: display handle as subdued `labelSmall` text below the display name
- [x] 8.5 Add `PersonDisplay` to the `HomeScreen` component gallery in multiple states (with avatar, without avatar, with handle shown, with handle hidden)
- [x] 8.6 Write widget tests in `test/shared/components/identity/person_display_test.dart` for: default rendering (name visible, handle hidden), `showHandle: true`, null avatar, and image-load failure

## 9. Logging Infrastructure

- [x] 9.1 Create `lib/core/logging/log_event.dart`: define `LogEvent` data class with `level` (enum), `tag`, `message`, `error` (nullable), `stackTrace` (nullable), `timestamp`
- [x] 9.2 Create `lib/core/logging/app_logger.dart`: static methods `verbose`, `debug`, `info`, `warning`, `error`, `fatal`; in debug builds, emit `LogEvent` to a broadcast `StreamController` and call `dart:developer`'s `log()`; in release builds, no-op for all levels except error/fatal (forwarded to crash reporter)
- [x] 9.3 Add `AppLogger.logStream` getter (returns `Stream<LogEvent>`, available in debug builds only via `kDebugMode` guard)
- [x] 9.4 Register `AppLogger` initialization in the app startup sequence (before `runApp()`)
- [x] 9.5 Replace all `print()` and `debugPrint()` calls (if any exist in the scaffolded project) with `AppLogger` equivalents

## 10. Crash Reporting Stub

- [x] 10.1 Create `lib/core/crash_reporting/crash_reporter.dart`: abstract `CrashReporter` interface with `recordError(Object error, StackTrace? stackTrace)` method
- [x] 10.2 Create `NullCrashReporter` implementing `CrashReporter` as a no-op
- [x] 10.3 Register `NullCrashReporter` as the `CrashReporter` singleton in `service_locator.dart` for all environments
- [x] 10.4 Wire `AppLogger` error/fatal level to call `CrashReporter.recordError()`

## 11. Debug Overlay

- [x] 11.1 Create `lib/core/debug/debug_overlay.dart`: an `OverlayEntry` or `Stack` widget with two tabs — **Logs** and **Info** — wrapped entirely in `if (kDebugMode)` guards
- [x] 11.2 Implement **Logs tab**: subscribes to `AppLogger.logStream`, displays events in a `ListView.builder` with severity color coding; includes severity filter chips
- [x] 11.3 Implement **Info tab**: reads from `AppInfoRepository` (version, build, env) and from `GoRouter`'s current location; displays as a simple key-value list
- [x] 11.4 Implement **Network tab stub**: empty state widget ("No requests recorded yet"); create `lib/core/debug/network_inspector.dart` as a stub service registered in `service_locator.dart`
- [x] 11.5 Create tap-sequence activation: in `HomeScreen` (dev build), add a `GestureDetector` counter that opens the overlay after 7 taps on the version label; OR add a visible debug FAB (choose one, document the decision in `design.md` if changed from the above)
- [x] 11.6 Wire overlay into the root app widget via an `Overlay` or `Stack` above the `MaterialApp`'s navigator; ensure `IgnorePointer` wraps collapsed overlay so it intercepts no touches
- [x] 11.7 Confirm overlay opens and closes correctly in a debug build; confirm it is absent in a release build (verify by running `flutter build apk --release` and checking no overlay-related symbols appear with `strings`)

## 12. Error Boundaries

- [x] 12.1 Create `lib/shared/components/error_boundary.dart`: an `ErrorBoundaryWidget` that uses `ErrorWidget.builder` to intercept Flutter rendering errors
- [x] 12.2 In debug builds, render a styled error panel showing exception type, message, and stack trace when a child throws
- [x] 12.3 In release builds, render a generic "Something went wrong" message and call `CrashReporter.recordError()`
- [x] 12.4 Wrap the root `HomeScreen` in `ErrorBoundaryWidget` as a demonstration; document the wrapping convention for future feature screens

## 13. Final Verification

- [x] 13.1 Run `dart analyze` — zero issues
- [x] 13.2 Run `dart format --set-exit-if-changed .` — exits 0
- [x] 13.3 Run `flutter test` — all widget tests pass (network-state and identity-presentation tests from tasks 7.6 and 8.6)
- [ ] 13.4 Boot app in debug mode on a device or simulator: confirm HomeScreen loads, component gallery renders, debug overlay opens via tap sequence, Logs tab shows `AppLogger` output, Info tab shows correct version/env/route
- [ ] 13.5 Boot app in release mode: confirm no debug overlay, no verbose console output, app starts without crash
- [ ] 13.6 Toggle device dark mode: confirm all components render correctly without hardcoded colors breaking
