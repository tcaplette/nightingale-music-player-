## ADDED Requirements

### Requirement: Riverpod is the exclusive state management layer
The app SHALL use `flutter_riverpod` with code generation (`riverpod_annotation`, `riverpod_generator`) as the sole state management mechanism. All providers SHALL use `@riverpod` annotations and generated code. No widget SHALL call `setState` for state that is shared across more than one widget. No other state management library (Bloc, Provider v1, GetX, ChangeNotifier with direct listeners) SHALL be introduced.

#### Scenario: A feature needs async state
- **WHEN** a feature requires async data (e.g., loading a list)
- **THEN** a `@riverpod` async provider SHALL be created in the feature's folder
- **THEN** the widget SHALL use `ref.watch()` to consume the provider's `AsyncValue`
- **THEN** loading, data, and error states SHALL each be handled in the widget

#### Scenario: Generated code is committed
- **WHEN** a developer runs `build_runner build`
- **THEN** generated `.g.dart` files SHALL be produced alongside annotated files
- **THEN** those generated files SHALL be committed to version control (not gitignored)

### Requirement: go_router provides all navigation with typed routes
The app SHALL use `go_router` for all navigation. All routes SHALL be declared as classes annotated with `@TypedGoRoute`. No widget SHALL navigate using `Navigator.push` or string-based `context.go('/raw/string')`. A single `AppRouter` class in `lib/core/router/` SHALL own the router instance. Shell routes SHALL be used for persistent UI elements (e.g., mini-player scaffold in Phase 2).

#### Scenario: Navigating to a named route
- **WHEN** a widget navigates to a route
- **THEN** it SHALL call the typed route's `.go(context)` method
- **THEN** the URL SHALL update to reflect the route, supporting deep linking

#### Scenario: Unknown route handled
- **WHEN** the app receives a URI that matches no declared route
- **THEN** the router SHALL redirect to a defined 404/not-found screen
- **THEN** no unhandled exception SHALL be thrown

### Requirement: All services registered via get_it service locator
The app SHALL register all repositories, services, and infrastructure singletons in `lib/core/di/service_locator.dart` using `get_it`. Registration SHALL complete before `runApp()` is called. Riverpod providers SHALL access services via `get_it` reads; widgets SHALL NOT call `GetIt.I` directly.

#### Scenario: Service accessed through a provider
- **WHEN** a Riverpod provider needs a repository
- **THEN** the provider SHALL read the repository from `GetIt.I<RepositoryType>()`
- **THEN** no widget SHALL import `service_locator.dart` directly

#### Scenario: Overriding a service in tests
- **WHEN** a unit test needs a mock repository
- **THEN** the test SHALL call `GetIt.I.registerSingleton<RepositoryType>(mockRepo)` before building the provider
- **THEN** the provider under test SHALL receive the mock without code changes

### Requirement: Repository pattern defined for all data sources
Every data source in the app SHALL be accessed through a repository interface defined in `lib/core/repositories/`. Concrete implementations SHALL be in feature-specific or infrastructure subfolders. No widget or provider SHALL access a data source (database, file system, network) except through a repository interface. All repository interfaces SHALL be pure Dart abstract classes with no Flutter dependency.

#### Scenario: A provider fetches data
- **WHEN** a Riverpod provider needs to read from a data source
- **THEN** it SHALL call a method on a repository interface
- **THEN** it SHALL NOT import `dart:io`, database packages, or HTTP packages directly

#### Scenario: Repository is testable in isolation
- **WHEN** a developer writes a unit test for a repository implementation
- **THEN** the test SHALL not require a Flutter widget tree or `BuildContext`
- **THEN** the test SHALL be runnable with `dart test` without the Flutter test runner
