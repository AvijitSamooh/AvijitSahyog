# AvijitSahyog# Avijit Sahyog

A multilingual, platform-independent donation platform designed to make
giving simple, transparent, and repeatable.

## Vision

Avijit Sahyog is being built as a donation platform rather than simply
a donation app.

The platform will allow users to:

- Discover causes and affiliated organisations
- Explore beneficiaries and impact stories
- Distribute donations across multiple causes
- Donate using UPI
- View donation history and receipts
- Create recurring donation plans
- Eventually use UPI AutoPay for monthly donations
- Use the platform in multiple Indian languages

See [docs/vision.md](docs/vision.md) for the complete product vision.

## Development Plan

Development is divided into incremental iterations, starting with the
information platform and gradually introducing the donation and payment
systems.

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

The current focus is establishing the project foundation before implementing
the donation domain.

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
- Start with a modular monolith; introduce additional infrastructure only
  when scale requires it.

## Deployment Environments

The application is environment-configured so the same codebase can run locally,
on the web, and on Android.

### Flutter API configuration

The API URL is supplied at build/run time using Dart defines:

```bash
# Local development
flutter run --dart-define=API_BASE_URL=http://localhost:3000

# Production
flutter build web --dart-define=API_BASE_URL=https://YOUR_RENDER_API_URL
```

The production API URL will be configured in Vercel and the Android release
pipeline; it is intentionally not hard-coded in source.

### Backend environment variables

The NestJS service expects:

- `DATABASE_URL` — PostgreSQL connection string supplied by Neon
- `PORT` — HTTP port supplied by the hosting platform (defaults to 3000 locally)
- `CORS_ORIGINS` — comma-separated list of allowed frontend origins

Production database migrations use:

```bash
npm run prisma:deploy
```

The health endpoint is available at `GET /health` and verifies both API and
database connectivity.

> Never commit production secrets or connection strings to Git.
