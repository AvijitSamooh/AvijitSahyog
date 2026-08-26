# Donation Platform --- Vision

## 1. Product Vision

Build a trusted, multilingual donation platform that makes it simple for
people to discover causes, understand where their money can be used,
distribute a donation across causes, make payments through familiar UPI
apps, and maintain a transparent history of their giving.

The long-term product is a **donation platform**, not merely a donation
app.

It should support: - Multiple causes / donation buckets - Multiple
affiliated organisations under each cause - Flexible donation
allocation - One-time UPI donations - Donation history and receipts -
Personal donation planning - Monthly UPI AutoPay / recurring donations -
Multilingual content and UI - Transparent administration and
reconciliation - Expansion to additional organisations and causes
without an app release

------------------------------------------------------------------------

## 2. Product Principles

### Trust first

Every financial transaction must be traceable from donor → payment →
donation → allocation → receipt → settlement/reconciliation.

### Backend is the source of truth

The client must never be trusted for payment success, donation status,
allocation totals, or financial state.

### Configurable, not hard-coded

Causes, organisations, translations, display content, and allocation
configuration should be backend-driven wherever practical.

### Multilingual from day one

English is the fallback language. Initial target languages: - English -
Hindi - Marathi - Gujarati

Adding another language should not require a database redesign.

### Start simple

The MVP should avoid unnecessary infrastructure and complexity. Use a
modular monolith before considering microservices.

### Platform-independent

The primary client should be Flutter so the same product architecture
can support Android, iOS, and web.

### Payment-provider abstraction

Payment logic must be isolated behind a backend payment interface so the
provider can be changed without rewriting the donation domain.

------------------------------------------------------------------------

## 3. Target User Experience

A donor should be able to:

1.  Open the app.
2.  Understand the platform and supported causes.
3.  Explore causes such as Jeev Daya.
4.  See affiliated organisations under a cause.
5.  Choose a donation amount.
6.  Distribute the amount:
    -   by percentage
    -   by equal share
    -   by selecting all available causes
7.  Review the exact allocation.
8.  Start a UPI payment.
9.  Choose an installed UPI app such as Google Pay, PhonePe, BHIM, etc.
10. Complete the payment and return to the app.
11. See the verified donation status.
12. Receive/download a receipt.
13. View past donations.
14. Create a planner such as ₹2/day or ₹5/day.
15. Later convert the planner into a monthly UPI AutoPay mandate.

------------------------------------------------------------------------

## 4. Core Domain Model

The initial domain should be designed around these entities:

-   User
-   Language
-   Cause / Donation Bucket
-   Cause Translation
-   Organisation
-   Organisation Translation
-   Organisation-Cause relationship
-   Donation
-   Donation Allocation
-   Payment
-   Receipt
-   Donation Planner
-   Mandate
-   Audit Log

### Important financial invariant

For every successful donation:

`sum(allocation amounts) == donation amount`

Successful donation allocations are immutable.

Changing a user's future allocation preference must never modify
historical donations.

------------------------------------------------------------------------

## 5. Allocation Model

The platform supports:

### Percentage allocation

Example:

-   Jeev Daya: 50%
-   Education: 30%
-   Medical: 20%

### Equal-share allocation

Example:

Three selected causes → each receives one third.

### Select-all

Selecting all active eligible causes results in an equal-share or
explicitly configured allocation according to the product rule.

The allocation engine belongs to the backend.

The Flutter app may provide the UI, but the backend validates and
persists the final allocation.

------------------------------------------------------------------------

## 6. Payment Architecture

### One-time donation

Initial preferred flow:

Flutter → Backend → UPI Intent → Installed UPI app → Return to Flutter →
Backend verification/reconciliation.

The Flutter callback is not the final source of truth.

The backend must verify payment status through the appropriate
payment/banking mechanism before marking the donation successful.

### Recurring donation

Later phase:

Flutter → Backend → UPI AutoPay mandate registration → User approval →
Mandate active → Scheduled debit → Provider callback/webhook → Donation
creation → Receipt.

Recurring payments should not be implemented as a custom payment
mechanism.

------------------------------------------------------------------------

## 7. Multilingual Architecture

Flutter UI strings use Flutter localization resources.

Backend-managed content uses translation records.

Conceptually:

`Cause → CauseTranslation(language_code, name, description)`

`Organisation → OrganisationTranslation(language_code, name, description)`

English is the mandatory fallback.

Translations should be human-reviewed rather than dynamically translated
on every request.

------------------------------------------------------------------------

## 8. Technology Direction

### Client

-   Flutter
-   Dart
-   Riverpod
-   Flutter localization / ARB

### Backend

-   Node.js
-   TypeScript
-   NestJS
-   REST API

### Database

-   PostgreSQL

### Supporting services

-   Firebase Authentication
-   Firebase Cloud Messaging
-   Firebase Crashlytics
-   Cloud Storage

### Hosting

-   Google Cloud Run

### Payments

-   Native UPI Intent for the initial one-time payment experience where
    appropriate
-   Payment provider / UPI AutoPay for recurring mandates
-   Provider abstraction in the backend

### CI/CD

-   GitHub Actions

------------------------------------------------------------------------

## 9. Security Principles

Never store: - UPI PIN - Card CVV - Card credentials - Banking
passwords - Other payment credentials that belong with the payment
provider

The backend must: - Validate authenticated users - Validate allocation
totals - Generate donation/payment identifiers - Verify payment status -
Prevent duplicate payment processing - Maintain audit records for
material administrative changes - Treat payment callbacks/webhooks as
untrusted input until verified - Make financial records immutable after
successful completion

------------------------------------------------------------------------

## 10. MVP Boundary

### MVP includes

-   Multilingual shell
-   Home / information experience
-   Causes
-   Affiliated organisations
-   Organisation details
-   User authentication
-   Donation planner without automatic payment
-   Donation allocation UI
-   Donation domain model
-   Basic admin/content model
-   Automated tests
-   CI/CD foundation

### MVP excludes

-   Live payment collection
-   UPI AutoPay
-   Settlement/distribution automation
-   Complex financial reconciliation
-   Microservices
-   Kubernetes
-   Advanced analytics
-   Large-scale notification campaigns

The architecture must remain payment-ready without making payment
implementation a prerequisite for the information MVP.

------------------------------------------------------------------------

## 11. Definition of Done

A feature is not done merely because the screen works.

A feature is done when: - UI is implemented - API/domain behavior is
implemented where required - Validation exists - Error states are
handled - Relevant automated tests exist - Localization is included -
Accessibility/basic responsive behavior is considered - Documentation is
updated - CI passes

------------------------------------------------------------------------

## 12. Long-Term Vision

The platform should eventually allow a donor to say:

> "I want to give ₹5 every day."

and turn that intention into a transparent, manageable giving plan
across causes and organisations, while giving the donor confidence
about: - where the money is intended to go - what was actually paid -
what was allocated - what receipt was issued - and what recurring
commitments are active.

The product succeeds when donating becomes simple, transparent,
multilingual, and repeatable.
