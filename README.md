# Avijit Sahyog

A multilingual, independent donation platform designed to make giving simple, transparent, and repeatable.

## Product Role

Avijit Sahyog is a **standalone giving platform being built specifically for Maharaj Ji and the associated Sangh/community**.

It is independent of the Jain Community Platform ecosystem and of other applications. Its product vision, data, architecture, deployment and roadmap are owned by this project.

## Vision

Avijit Sahyog is being built as a donation platform rather than simply a donation app.

The platform will allow users to:

- Discover causes and affiliated organisations
- Explore beneficiaries and impact stories
- Distribute donations across multiple causes
- Donate using UPI
- View donation history and receipts
- Create recurring donation plans
- Eventually use UPI AutoPay for monthly donations
- Use the platform in multiple Indian languages
- Understand usage and giving activity through privacy-conscious analytics

See [docs/vision.md](docs/vision.md) for the complete product vision and independence boundary.

## Development Plan

Development is divided into incremental iterations, starting with the information platform and gradually introducing the donation and payment systems.

See [docs/iteration-plan.md](docs/iteration-plan.md).

## Technology

### Client
- Flutter
- Dart
- Riverpod
- Flutter localization

### Backend
- Node.js
- TypeScript
- NestJS
- REST API

### Database
- PostgreSQL

### Infrastructure
- Vercel (Flutter Web)
- Render (NestJS API)
- Neon (PostgreSQL)
- GitHub Actions (CI)

### Payments
- UPI Intent for initial one-time donations
- UPI AutoPay for recurring donations

## Current Status

🚧 Active development — public discovery and impact exploration are implemented, along with authenticated admin management for causes, organisations and beneficiaries, with an operational dashboard summary; payment functionality remains intentionally disabled for now.

The current focus is establishing the project foundation before implementing the donation domain.

## Quality Targets

- 70% overall line coverage target as the codebase matures
- 80%+ for new domain/service logic
- 90%+ for critical financial/payment/allocation logic
- CI validates Prisma schema, builds, analyzes and runs automated tests

## Development Principles

- Backend is the source of truth for financial data.
- Historical donations and allocations are immutable.
- Financial amounts are never represented using floating-point values.
- Payment callbacks are never trusted without server-side verification.
- Multilingual support is designed into the platform from the beginning.
- Causes and organisations are data-driven rather than hard-coded.
- Start with a modular monolith; introduce additional infrastructure only when scale requires it.
- Keep Avijit Sahyog independently deployable and operable.
- Do not introduce dependencies on unrelated application ecosystems.
- Keep usage analytics separate from financial truth.

## Deployment Environments

The application is environment-configured so the same codebase can run locally, on the web, and on Android.

### Flutter API configuration

The API URL is supplied at build/run time using Dart defines:

```bash
# Local development
flutter run --dart-define=API_BASE_URL=http://localhost:3000

# Production
flutter build web --dart-define=API_BASE_URL=https://YOUR_RENDER_API_URL
```

The production API URL will be configured in Vercel and the Android release pipeline; it is intentionally not hard-coded in source.

### Configurable backend service window

The Flutter client supports an environment-configured nightly backend service window. The default is **9:00 PM to 8:00 AM local device time**.

During the window:

- already available/static content remains visible;
- taps are intercepted with a localized service-unavailable message;
- NestJS API requests are blocked before an HTTP request is sent;
- authentication backend resolution, analytics mirroring and client health telemetry are also suppressed;
- the window can be disabled without changing application code.

The build-time variables are:

- `BACKEND_SERVICE_WINDOW_ENABLED` — `true` or `false`; defaults to `true`
- `BACKEND_SERVICE_OFFLINE_START` — `HH:mm`; defaults to `21:00`
- `BACKEND_SERVICE_OFFLINE_END` — `HH:mm`; defaults to `08:00`

The Android release workflow maps these explicitly to the Flutter `BACKEND_SERVICE_WINDOW_START/END` defines. The `OFFLINE_*` names make it clear that the configured interval is the **unavailable** window, not the available window. If these repository variables are absent, the build defaults to 9:00 PM–8:00 AM.

For clarity, do not configure the offline window as `08:00` → `21:00`; that would intentionally describe the daytime interval. The expected nightly values are `21:00` → `08:00`. GitHub configuration variables are intended for non-secret build configuration and are exposed through the `vars` context.

To disable the nightly restriction for an environment, set:

```text
BACKEND_SERVICE_WINDOW_ENABLED=false
```

Changing these values affects the next build/deployment; an already-installed compiled Flutter app keeps the values that were embedded into that build.

For a web deployment, pass the same values as `--dart-define` arguments in the Vercel Flutter build command.

### Android Firebase and Google Sign-In

Android release builds use the `GOOGLE_SERVICES_JSON` GitHub Actions variable as the single source of truth for native Firebase and Google OAuth configuration. The release workflow validates that the configuration targets project `avijitsahyog-firebase` and package `com.avijitsamooh.avijitsahyog`, then derives the Web OAuth client ID (`client_type: 3`) directly from that same file and passes it as the `GOOGLE_SIGN_IN_SERVER_CLIENT_ID` Dart define to the Android build. This prevents Firebase and Google Sign-In credentials from drifting between independently configured CI variables.

On Android, Firebase is initialized from the native `google-services.json` configuration. The generated Dart Firebase options remain the source of truth for web initialization.

### Backend environment variables

The NestJS service expects:

- `DATABASE_URL` — PostgreSQL connection string supplied by Neon
- `PORT` — HTTP port supplied by the hosting platform (defaults to 3000 locally)
- `CORS_ORIGINS` — comma-separated list of allowed frontend origins

Production database migrations use:

```bash
npm run prisma:deploy
```

The health endpoint is available at `GET /health` and verifies both API and database connectivity.

> Never commit production secrets or connection strings to Git.

## Local Validation

Run the repository validation script from the repository root before pushing code:

```powershell
# Validate Flutter UI and backend (default)
.\scripts\validate.ps1

# Validate only Flutter UI
.\scripts\validate.ps1 -Target ui

# Validate only backend
.\scripts\validate.ps1 -Target backend
```

The script runs dependency setup, code generation, static checks, tests and production builds for the selected targets. It stops on the first failure so CI remains a final confirmation gate rather than the primary debugging environment.
