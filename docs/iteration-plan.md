# Development Iteration Plan

## Working Method

We will develop in small vertical slices.

Each iteration should leave the repository in a runnable state.

### Branching

-   `main` --- stable
-   `develop` --- integration branch if needed
-   `feature/<short-name>` --- feature work
-   `fix/<short-name>` --- fixes

Prefer small pull requests with one coherent objective.

------------------------------------------------------------------------

# Iteration 0 --- Foundation

## Goal

Establish the repository and development standards.

### Deliverables

-   Flutter application scaffold
-   Backend scaffold
-   PostgreSQL configuration
-   Environment configuration
-   Shared API conventions
-   GitHub Actions CI
-   Basic README
-   `vision.md`
-   `iteration-plan.md`
-   Development scripts
-   Test framework

### Architecture

``` text
/
├── app/                 # Flutter client
├── backend/             # NestJS API
├── docs/
├── .github/
└── README.md
```

### Exit criteria

-   Flutter app runs
-   Backend runs
-   Health endpoint works
-   Database connection works
-   CI runs tests/build checks
-   No secrets committed

------------------------------------------------------------------------

# Iteration 1 --- Application Shell + Localization

## Goal

Create the reusable Flutter application foundation.

### Features

-   App theme
-   Navigation
-   Home screen
-   Settings screen
-   Language selector
-   English
-   Hindi
-   Marathi
-   Gujarati
-   Device-language detection
-   English fallback

### Technical

-   Riverpod
-   Flutter localization / ARB
-   Shared components
-   Error/loading/empty states

### Exit criteria

Changing language updates all application UI without reinstalling the
app.

------------------------------------------------------------------------

# Iteration 2 --- Causes and Organisations

## Goal

Make the information model backend-driven.

### Backend entities

-   Language
-   Cause
-   CauseTranslation
-   Organisation
-   OrganisationTranslation
-   OrganisationCause

### API

-   `GET /languages`
-   `GET /causes`
-   `GET /causes/:id`
-   `GET /organisations/:id`

### Flutter

-   Cause list
-   Cause detail
-   Organisation list
-   Organisation detail
-   Localized content
-   Fallback behavior

### Exit criteria

An administrator can add a cause/organisation in the database and the
app can display it without a Flutter release.

------------------------------------------------------------------------

# Iteration 2.5 --- Impact Explorer & Beneficiary Transparency

## Goal

Make the outcome of giving discoverable without complicating the donation flow.

### Features

- Cause-centric donation entry point
- Home hero with Maharaj Ji image and giving message
- Beneficiary cards
- Beneficiary detail / impact story
- Cause, year, name and amount discovery controls
- Affiliated organisation details remain visible for transparency
- Backend `Beneficiary` model and REST API
- Production Prisma migration and seed data
- Flutter and backend regression tests

### Exit criteria

A user can discover beneficiaries, explore an impact story and understand the related cause and organisation without being asked to choose an organisation during donation allocation.

------------------------------------------------------------------------

# Iteration 3 --- Authentication + User Profile

## Goal

Introduce users.

### Features

-   Public browsing remains available without login
-   Firebase Authentication foundation
-   Login/logout entry point
-   Internal User record linked to Firebase UID
-   `USER` / `ADMIN` roles
-   Protected `GET /auth/me`
-   User profile foundation
-   Preferred language
-   Admin access is role-based; no separate admin login

### Exit criteria

Visitors can browse causes, organisations and beneficiary stories without login. A signed-in identity can be resolved by the backend and an administrator role can unlock future admin operations.

------------------------------------------------------------------------

# Iteration 3.5 --- Authorization + Admin Operations Foundation

## Goal

Establish role-based access before production content is managed by administrators.

### Features

- Admin-only route and API foundation
- Role checks based on the internal User record
- Protected `/admin/*` API namespace
- Admin navigation entry for authenticated administrators
- Cause management API: list all, create, edit, activate/deactivate
- Cause translation upsert support for active content languages
- Prepare the first content-management workflow so production content no longer depends on seed data

### Exit criteria

One identity system supports normal users and administrators, while public discovery remains available to guests.

### Initial admin API contract

- `GET /admin/causes`
- `GET /admin/causes/:id`
- `POST /admin/causes`
- `PATCH /admin/causes/:id`
- `PATCH /admin/causes/:id/activate`
- `PATCH /admin/causes/:id/deactivate`

All endpoints require an authenticated internal user with the `ADMIN` role.

------------------------------------------------------------------------

# Iteration 4 --- Admin Content Operations

## Goal

Make real causes, organisations and beneficiary content manageable without changing seed data or releasing a new client.

### Initial capabilities

- Create/edit/activate/deactivate causes
- Manage translations
- Create/edit/activate/deactivate organisations
- Associate organisations with causes
- Create/edit/publish beneficiary impact stories

### Exit criteria

An authorised administrator can change production content through protected operations and public clients reflect backend data.

------------------------------------------------------------------------

# Iteration 5 --- Donation Allocation Engine

## Goal

Build the financial domain before connecting payments.

### Backend

-   Donation
-   DonationAllocation
-   Allocation validation
-   Allocation calculation service

### Supported modes

1.  Equal-share default with donor-controlled percentage overrides (current donation flow)
2.  Equal share (automatic default when selected causes change)
3.  Select all (future convenience option)

### First-release availability

- The donation planning and allocation experience is available for exploration.
- Actual donation submission is intentionally disabled in the first release.
- When a user attempts to donate, the app clearly states that the donation feature is not enabled yet and does not create a backend donation record.

### Rules

-   Donors allocate across causes only; affiliated organisations are not allocation choices
-   Amount must be positive
-   Percentages must total 100%
-   Allocated amount must equal donation amount
-   Monetary values use integer minor units / paise, never
    floating-point money
-   Historical allocations are immutable

### Tests

Create extensive unit tests around: - rounding - equal shares -
percentage allocation - small amounts - remainder distribution - invalid
percentages - unavailable causes

### Exit criteria

Given an amount and allocation configuration, the backend
deterministically produces a valid allocation whose total exactly equals
the donation amount.

------------------------------------------------------------------------

# Iteration 6 --- Donation Planner

## Goal

Allow users to plan future giving without collecting money.

### Features

-   Create planner
-   Daily amount
-   Monthly estimate
-   Custom frequency
-   Allocation preference
-   Activate/deactivate planner
-   Edit future allocation
-   Planner history

Example:

``` text
₹5/day
≈ ₹150/month

Jeev Daya 50%
Education 30%
Medical 20%
```

### Exit criteria

A user can create and manage a donation plan without any payment
integration.

------------------------------------------------------------------------

# Iteration 7 --- Donation History + Receipt Foundation

## Goal

Build the donor record experience.

### Features

-   Donation history
-   Donation detail
-   Allocation breakdown
-   Receipt model
-   Receipt generation abstraction
-   Receipt language captured at generation

### Exit criteria

A test donation can produce a deterministic receipt record and the app
can display the complete donation history.

------------------------------------------------------------------------

# Iteration 12 --- Payment Enablement (last)

## Goal

Add one-time payment.

### Flow

``` text
Create donation
      ↓
Backend creates payment intent/order
      ↓
Flutter starts UPI Intent
      ↓
User selects installed UPI app
      ↓
User pays
      ↓
Returns to Flutter
      ↓
Backend verifies payment
      ↓
Donation becomes successful
      ↓
Receipt generated
```

### Critical rules

-   Flutter callback is not authoritative
-   Payment IDs are idempotent
-   Duplicate callbacks cannot create duplicate donations
-   Failed/cancelled payments remain distinguishable from successful
    donations
-   Allocation is locked before payment

### Exit criteria

A sandbox/test payment can complete end-to-end and produce exactly one
successful donation.

------------------------------------------------------------------------

# Iteration 13 --- Receipt Delivery + Notifications

## Goal

Complete the donor payment experience.

### Features

-   PDF receipt
-   Secure receipt storage
-   Download/view receipt
-   Push notification
-   Donation success notification
-   Donation failure notification

### Exit criteria

Successful donation → receipt → notification works end-to-end.

------------------------------------------------------------------------

# Iteration 14 --- Reconciliation

## Goal

Prepare for real financial operations.

### Features

-   Payment reconciliation records
-   Provider transaction IDs
-   Settlement references
-   Duplicate detection
-   Failed payment handling
-   Refund handling
-   Reconciliation report

### Exit criteria

Every successful donation can be reconciled to a provider transaction.

------------------------------------------------------------------------

# Iteration 15 --- UPI AutoPay

## Goal

Convert donation planners into recurring giving.

### Features

-   Create mandate
-   User approval
-   Mandate status
-   Active/paused/revoked states
-   Monthly debit
-   Failed debit handling
-   Automatic donation creation
-   Receipt generation

### Exit criteria

A test mandate can produce a recurring donation with a complete audit
trail.

------------------------------------------------------------------------

# Iteration 11 --- Production Hardening

## Goal

Prepare for real users.

### Security

-   Rate limiting
-   API authentication hardening
-   Input validation
-   Secure secrets
-   Audit logging
-   Payment idempotency
-   Webhook signature verification
-   Database backups

### Reliability

-   Monitoring
-   Crash reporting
-   Structured logs
-   Alerts
-   Health checks
-   Database backup/restore test

### Product

-   Accessibility review
-   Localization review
-   Error-state review
-   Performance review
-   Android production build
-   iOS production build
-   Web production build

------------------------------------------------------------------------

# Initial Issue Backlog

## P0 --- Start immediately

-   [ ] Create repository structure
-   [ ] Initialize Flutter application
-   [ ] Initialize NestJS backend
-   [ ] Configure PostgreSQL
-   [ ] Add environment configuration
-   [ ] Add CI
-   [ ] Add localization foundation
-   [ ] Add architecture documentation

## P1

-   [ ] Cause model
-   [ ] Organisation model
-   [ ] Translation model
-   [ ] Cause/organisation APIs
-   [ ] Flutter cause screens
-   [ ] Flutter organisation screens
-   [ ] Authentication
-   [ ] User preferences

## P2

-   [ ] Allocation engine
-   [ ] Allocation UI
-   [ ] Planner
-   [ ] Donation history
-   [ ] Receipt foundation

## P3

-   [ ] UPI Intent
-   [ ] Payment verification
-   [ ] Idempotency
-   [ ] Receipts
-   [ ] Notifications

## P4

-   [ ] Admin portal
-   [ ] Reconciliation
-   [ ] UPI AutoPay
-   [ ] Production hardening

------------------------------------------------------------------------

# First Development Milestone

The first milestone is deliberately small:

``` text
Flutter app
   ↓
Localized shell
   ↓
Backend API
   ↓
PostgreSQL
   ↓
Causes
   ↓
Organisations
   ↓
Localized content
```

No payment yet.

Once this works end-to-end, we move into the donation domain.

------------------------------------------------------------------------

# Testing & Coverage Policy

- Measure coverage continuously in CI.
- Target **70% overall line coverage** as a baseline.
- New backend domain/service logic should normally reach **80%+**.
- Critical financial/payment/allocation code should target **90%+** with scenario-based tests.
- Do not chase percentage with trivial tests; important branches and user journeys matter more.

------------------------------------------------------------------------

# Engineering Rule

Do not build screens in isolation.

For each major feature, implement:

``` text
Domain model
    ↓
Backend API/service
    ↓
Tests
    ↓
Flutter state/model
    ↓
Flutter UI
    ↓
Localization
    ↓
Integration test
```

This keeps the application maintainable as it grows from an MVP into a
real donation platform.


### App Shell Consistency

- Shared top-right settings menu exposes language and login/profile actions across public flows.
- Shared bottom navigation remains available on contribution flows and returns users to the existing main tab shell.
- Locale changes remain available outside the home screen through the application shell.
