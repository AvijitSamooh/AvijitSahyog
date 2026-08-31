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

-   Firebase Authentication
-   Login/logout
-   User profile
-   Preferred language
-   Basic account settings

### Exit criteria

A user can sign in, select a language, close/reopen the app, and retain
the preference.

------------------------------------------------------------------------

# Iteration 4 --- Donation Allocation Engine

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

# Iteration 5 --- Donation Planner

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

# Iteration 6 --- Donation History + Receipt Foundation

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

# Iteration 7 --- UPI Intent

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

# Iteration 8 --- Receipt Delivery + Notifications

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

# Iteration 9 --- Admin Portal / Content Management

## Goal

Make the platform operational without developer intervention.

### Admin capabilities

-   Manage causes
-   Manage translations
-   Manage organisations
-   Associate organisations with causes
-   Activate/deactivate organisations
-   View donations
-   View payment status
-   View audit log

### Exit criteria

Normal content changes do not require an app release.

------------------------------------------------------------------------

# Iteration 10 --- Reconciliation

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

# Iteration 11 --- UPI AutoPay

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

# Iteration 12 --- Production Hardening

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
