# Avijit Sahyog — Giving Platform Vision

## 1. Product role

Avijit Sahyog is an **independent donation and giving application**, being built specifically for **Maharaj Ji and the associated Sangh/community**.

It is a standalone product with its own product vision, architecture, data, operations and roadmap. It is **not part of the Jain Community Platform ecosystem** and must not acquire dependencies on that platform.

Avijit Sahyog should remain focused exclusively on the **giving and financial domain** rather than becoming a general-purpose community platform.

## 2. Product Vision

Build a trusted, multilingual donation platform that makes it simple for people to discover causes, understand where their money can be used, distribute a donation across causes, make payments through familiar UPI apps, and maintain a transparent history of their giving.

The long-term product is a **donation platform**, not merely a donation app.

It should support:
- Multiple causes / donation buckets
- Multiple affiliated organisations under each cause
- Flexible donation allocation
- One-time UPI donations
- Donation history and receipts
- Personal donation planning
- Monthly UPI AutoPay / recurring donations
- Multilingual content and UI
- Transparent administration and reconciliation
- Expansion to additional organisations and causes without an app release
- Privacy-conscious giving analytics and monitoring

## 3. Product Independence Boundary

Avijit Sahyog is a standalone application and should remain independently deployable and operable.

It must not depend on:
- Jain Community Platform services or databases
- Jain Community Platform identity or tenancy models
- Digital Library services, content or entitlement rules
- Shri Andinath Jinalay application services
- Shared business logic from unrelated applications

If external integrations are introduced in the future, they must be explicit, optional and contract-based. An integration must never make another application's architecture or roadmap a prerequisite for Avijit Sahyog to function.

Avijit Sahyog owns the financial truth for its own donation domain, including donation intent, allocations, payment state, receipts, recurring commitments and financial audit records.

## 4. Financial architecture

```mermaid
flowchart TB
    User[Donor / User]
    App[Avijit Sahyog\nIndependent Giving Platform]
    Giving[Giving & Financial Domain]
    Payments[Payment Provider Abstraction]
    Analytics[Usage & Giving Analytics]
    Audit[Financial Audit / Trust]

    User --> App
    App --> Giving
    Giving --> Payments
    Giving --> Analytics
    Giving --> Audit
```

The architecture is intentionally self-contained. Any future third-party service integration should be introduced behind a stable interface without creating a dependency on another product ecosystem.

## 5. Donor experience

A donor should be able to:

1. Open the app.
2. Understand the platform and supported causes.
3. Explore causes such as Jeev Daya.
4. See affiliated organisations under a cause.
5. Choose a donation amount.
6. Distribute the amount by percentage, equal share or configured selection.
7. Review the exact allocation.
8. Start a UPI payment.
9. Complete the payment and return to the app.
10. See the verified donation status.
11. Receive/download a receipt.
12. View past donations.
13. Create a planner such as ₹2/day or ₹5/day.
14. Later convert the planner into a monthly UPI AutoPay mandate.

## 6. Allocation model

A donor allocates money **only across Causes**. Affiliated Organisations are discovery and transparency entities beneath a Cause; the donor is never required to choose which organisation receives an allocation.

The platform records donor intent as:

`Donation → DonationAllocation → Cause`

Any later organization-level routing, settlement or reconciliation is an administrative responsibility and must not retroactively change the donor's recorded cause allocation.

For every successful donation:

`sum(allocation amounts) == donation amount`

## 7. Payment architecture

### One-time donation

Preferred flow:

Flutter → Backend → UPI Intent → Installed UPI app → Return to Flutter → Backend verification/reconciliation.

The Flutter callback is not the final source of truth.

### Recurring donation

Later phase:

Flutter → Backend → UPI AutoPay mandate registration → User approval → Mandate active → Scheduled debit → Provider callback/webhook → Donation creation → Receipt.

Recurring payments should not be implemented as a custom payment mechanism.

## 8. Multilingual architecture

Flutter UI strings use Flutter localization resources.

Backend-managed content uses translation records. English is the mandatory fallback. Initial target languages are English, Hindi, Marathi and Gujarati.

## 9. Security principles

Never store UPI PIN, card CVV, card credentials, banking passwords or other payment credentials belonging with the payment provider.

The backend must validate authenticated users, allocation totals and payment status; prevent duplicate processing; maintain audit records; verify callbacks/webhooks; and make financial records immutable after successful completion.

## 10. Monitoring and usage analytics

The platform should include first-class monitoring for both operational health and product usage.

Operational monitoring should cover:
- API availability and latency
- Database health
- Error rates
- Background jobs and scheduled work
- Payment callback/webhook failures
- Authentication and critical-flow failures
- Deployment/CI health where appropriate

Usage analytics should help answer questions such as:
- How many users visit the platform?
- How often do users return?
- Which screens, causes and journeys are most used?
- Which donation flows are started and completed?
- Where do users drop off?
- Which languages and device/platform combinations are being used?

Analytics must be privacy-conscious and must not become the source of truth for financial records. Financial truth remains in the giving domain and its audit trail.

## 11. MVP boundary

### MVP includes
- Multilingual shell
- Home / information experience
- Causes
- Affiliated organisations
- Organisation details
- Optional user authentication with public browsing
- Role-based admin access
- Donation planner without automatic payment
- Donation allocation UI
- Donation domain model
- Basic admin/content model
- Beneficiary / impact explorer
- Automated tests
- CI/CD foundation

### MVP excludes
- Live payment collection
- UPI AutoPay
- Settlement/distribution automation
- Complex financial reconciliation
- Microservices
- Kubernetes
- Advanced analytics
- Large-scale notification campaigns

The architecture remains payment-ready without making payment implementation a prerequisite for the information MVP.

## 12. Definition of Done

A feature is done when UI, required API/domain behavior, validation, error states, relevant automated tests, localization, accessibility/basic responsive behavior, documentation and CI requirements are satisfied.

## 13. Long-Term Giving Vision

The platform should eventually allow a donor to say:

> "I want to give ₹5 every day."

and turn that intention into a transparent, manageable giving plan across causes and participating organizations, while giving the donor confidence about where the money is intended to go, what was actually paid, what was allocated, what receipt was issued and what recurring commitments are active.

The product succeeds when donating becomes simple, transparent, multilingual and repeatable for the people served by Maharaj Ji and the Sangh.

## 14. Testing & Quality Target

- 70% overall line coverage as the project matures
- 80%+ coverage for new domain/service logic
- 90%+ for critical financial, allocation and payment logic
- UI tests covering primary journeys and important empty/error states

CI must run analysis/build, automated tests and Prisma schema validation before merge.
