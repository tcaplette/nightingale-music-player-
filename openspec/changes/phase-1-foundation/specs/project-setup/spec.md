## ADDED Requirements

### Requirement: Flutter project initialized with defined minimum SDK
The project SHALL target a minimum Flutter SDK version pinned in `pubspec.yaml`. The version SHALL be the latest stable release at the time of project creation. The SDK constraint SHALL be written as a range (`>=X.Y.Z <Z.0.0`) to allow patch upgrades without manual edits.

#### Scenario: SDK version is enforced
- **WHEN** a developer runs `flutter pub get` on a Flutter installation below the minimum version
- **THEN** the tool SHALL refuse with a clear version mismatch error

### Requirement: Monorepo-friendly folder structure enforced
The project SHALL use the folder layout `lib/core/`, `lib/features/`, and `lib/shared/`. No Dart source files SHALL exist directly under `lib/` except `main.dart` and environment entry points. The `lib/core/` folder SHALL contain only app-wide infrastructure with no feature-specific code. The `lib/features/` folder SHALL contain one subfolder per product feature. The `lib/shared/` folder SHALL contain only code reused across two or more features.

#### Scenario: Developer adds a new feature
- **WHEN** a developer creates a new product feature
- **THEN** all feature-specific Dart files SHALL be placed under `lib/features/<feature-name>/`
- **THEN** code shared with other features SHALL be moved to `lib/shared/`
- **THEN** infrastructure code (DI, routing, logging) SHALL be placed under `lib/core/`

#### Scenario: Core infrastructure is isolated
- **WHEN** a widget in `lib/features/` needs infrastructure (e.g., the router or logger)
- **THEN** it SHALL import from `lib/core/` and NOT from another feature's folder

### Requirement: Environment configuration supports dev, staging, and prod
The app SHALL support three named environments: `dev`, `staging`, and `prod`. Each environment SHALL be represented as a Dart configuration file (e.g., `lib/core/config/env_config.dart`) with a corresponding Flutter flavor or `--dart-define` entry point. Sensitive environment values SHALL NOT be hard-coded in source files committed to version control.

#### Scenario: App launches in dev environment
- **WHEN** the app is run with the `dev` configuration
- **THEN** `AppConfig.environment` SHALL return `Environment.dev`
- **THEN** debug-only features (overlay, verbose logging) SHALL be enabled

#### Scenario: App launches in prod environment
- **WHEN** the app is built with the `prod` configuration
- **THEN** `AppConfig.environment` SHALL return `Environment.prod`
- **THEN** all debug-only code paths SHALL be inert or compile-time removed

### Requirement: Linting and formatting enforced via CI-compatible tooling
The project SHALL include an `analysis_options.yaml` extending `flutter_lints` with project-specific rule overrides. All source files SHALL be formatted with `dart format`. The CI pipeline SHALL fail if `dart analyze` reports any issues or if `dart format --set-exit-if-changed` detects unformatted files.

#### Scenario: Linting catches a violation
- **WHEN** a developer writes code that violates a configured lint rule
- **THEN** `dart analyze` SHALL report the violation with file and line number
- **THEN** the violation SHALL be surfaced in the IDE via the language server

#### Scenario: Formatting is checked in CI
- **WHEN** a pull request is submitted with unformatted Dart files
- **THEN** the `dart format --set-exit-if-changed .` command SHALL exit with a non-zero code
- **THEN** CI SHALL fail and report which files are incorrectly formatted
