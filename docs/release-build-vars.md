# Release Build Variables

Build-time environment variables supplied via `--dart-define` when building a release artifact.

## SENTRY_DSN

| Key | `SENTRY_DSN` |
|---|---|
| Required for | Production error reporting |
| Used in | `lib/main_prod.dart` |
| Default | `""` (reporting silently disabled if absent) |

Sentry DSN for the release build. When set, unhandled exceptions and Flutter framework errors are reported to Sentry with non-PII fields only (exception type, anonymized stack trace, app version, platform).

**Never commit** the real DSN to the repository. Store it in CI secret variables.

### Example build command

```sh
flutter build apk --release \
  --dart-define=SENTRY_DSN=https://xxxxxx@oxxxxxxx.ingest.sentry.io/yyyyyyy \
  --dart-define=NODE_BASE_URL=https://your-node.example
```

### Allowlist

Only these fields are transmitted to Sentry (enforced via `beforeSend`):

- Exception type
- Anonymized stack trace (no local file paths)
- App version string
- OS platform

No username, node URL, music library data, or taste profile data is ever sent.
