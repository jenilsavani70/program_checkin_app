# Program Check-in Mini App

A standalone Flutter demo for the technical assignment. It models a production-style slice of a larger app: dashboard, weekly check-in, progress history, local session handling, fake network failures, safe observability, and English/German UI copy.

## Setup

```sh
flutter pub get
```

## Run

```sh
flutter run
```

## Test And Verify

```sh
dart format --set-exit-if-changed .
flutter analyze
flutter test
rg "print\\(|debugPrint\\(|log\\(" lib test
rg -i "secret|token|password|email|phone|authorization" lib test
```

The `rg` privacy review command intentionally matches storage key names, fake fixture token examples, and tests that prove sensitive data is not written to plain preferences or observability records.

## Architecture

The app uses small feature folders under `lib/src`:

- `domain`: immutable program, session, draft, submission, and history models.
- `data`: fake in-memory client plus repositories.
- `core`: clock, result/error types, storage abstractions, formatting, localization, and local observability.
- `features`: Blocs/Cubits for dashboard, check-in, session, and locale state.

Dependencies are injected through `AppScope`; widgets do not read globals for repositories, storage, clock, or observability.

## State Management

`flutter_bloc` models non-trivial state:

- `DashboardBloc`: loading, loaded, empty, error, unauthorized, refresh-with-cache, and stale load protection.
- `CheckInBloc`: editing, validating, support-needed, submitting, submitted, retryable failure, unauthorized, and invalid input.
- `SessionCubit`: authenticated, refreshing, and unauthorized session status.
- `LocaleCubit`: stores only the non-sensitive locale preference.

The check-in draft is held in memory by an app-level `CheckInBloc` so it survives leaving and returning during the same app run. Progress and note fields restore draft values via `TextFormField.initialValue`.

## Routing

`go_router` defines the three required named routes:

- `dashboard` at `/dashboard` (initial route; `/` redirects here)
- `check-in` at `/check-in`
- `history` at `/history`

Typed route arguments live in `lib/src/app/route_args.dart`. `CheckInRouteArgs` controls post-submit navigation (`dashboard` or `history`). Invalid `extra` payloads show a recoverable error screen. Unknown paths use the same recoverable error UI.

## Observability

The app uses a local-only `InMemoryObservability` abstraction. No hosted logging, analytics, tracing, or crash services are used.

Events: `dashboard_loaded`, `checkin_started`, `checkin_validated`, `checkin_submit_attempted`, `checkin_submitted`, `checkin_failed`, `session_refresh_failed`.

Spans: `dashboard.load`, `checkin.flow`, `checkin.submit`, `repository.submit_checkin`, `history.refresh`.

Metrics: `checkin.submit_attempts`, `checkin.submit_failures`, `checkin.validation_failures`, `checkin.retry_count`, `checkin.submit_duration_ms`.

Correlation IDs are generated per check-in flow and attached to breadcrumbs, logs, spans, metrics-related records, and sanitized error records.

All attributes pass through one allowlist (`allowSafeAttributes`). Safe attributes include route name, status class, safe error code, region, adherence, wellbeing, retryable flag, boolean note presence, duration, and correlation ID.

Production mapping:

- Structured logs → centralized logging (e.g. Cloud Logging, Datadog logs)
- Spans → distributed tracing (e.g. OpenTelemetry, Jaeger)
- Metrics → counters/histograms (e.g. Prometheus)
- Breadcrumbs → session replay / support tooling
- Crash-flagged error records → crash reporting (e.g. Sentry, Crashlytics)

## Security And Privacy

**Secure storage only:** access token, refresh token, token expiry.

**Plain preferences:** locale only.

**Memory only:** check-in draft, optional note, progress value, loaded user/program data, and observability records.

**Nowhere:** real credentials, real domains, real personal data, authorization headers, raw request/response bodies, file paths, or URL query values.

A fake 401 on load, submit, or session refresh clears secure session state and returns the user to a signed-out dashboard state. Expected repository failures are recorded as sanitized failure events/metrics, not crashes. Unexpected exceptions are captured once by the local crash boundary.

The dashboard app bar includes a session refresh action. Tokens are modeled in secure storage but never shown in the UI.

### Offline assumptions

Connectivity status is not used. Retryable failures (timeout, offline, rate-limited) preserve the in-memory check-in draft and expose an explicit retry action. The fake client does not auto-retry non-idempotent submits; idempotency keys prevent duplicate saves on double-tap.

### Real backend changes

Replace `FakeProgramClient` with an HTTP client using `example.invalid` hosts, move fixture bootstrap to a one-time seed endpoint, use platform secure storage (Keychain/EncryptedSharedPreferences) for tokens, add certificate pinning and real refresh-token rotation, and forward observability records to hosted collectors with the same allowlist redaction applied server-side.

## Assumptions And Trade-offs

The app intentionally uses in-memory repositories and stores to keep the demo self-contained. The fake client models success, timeout, offline, malformed JSON, unauthorized, and rate-limited results with explicit error types instead of expected exceptions.

German copy uses ASCII umlauts (`Zurueck`, `Faellig`) to avoid extra localization tooling in the timebox. The support interstitial replaces the optional note step when wellbeing is "Needs support".

With another day, I would add screenshot assets under `docs/screenshots/`, an in-app debug observability panel, and broader widget coverage across every check-in step.


## Local Verification

```text
$ dart format --set-exit-if-changed .
Formatted 46 files (0 changed) in 1.3s

$ flutter analyze
Analyzing program_checkin_app...
No issues found!

$ flutter test
00:06 +25: All tests passed!

$ rg "print\\(|debugPrint\\(|log\\(" lib test
(no matches)

$ rg -i "secret|token|password|email|phone|authorization" lib test
Matches only in session models, secure-store keys, fake fixture values, and privacy tests.
```

## Screenshots

See `docs/screenshots/README.md` for capture instructions.
