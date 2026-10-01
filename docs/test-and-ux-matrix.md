# Test, Requirements & User-Experience Traceability

## Purpose

This is the release-readiness matrix for Avijit Sahyog. It connects product documentation, implementation and automated testing so important user journeys are tested at the right boundary.

## Test levels

| Level | Responsibility |
|---|---|
| Unit | Function, model, service or repository logic in isolation |
| Widget | Flutter screen/component behaviour |
| HTTP integration/E2E | NestJS controller, guard and service boundary |
| Flutter integration | Large Flutter user journeys |
| CI | Repository-wide quality gate |

Flutter's official guidance distinguishes unit/widget tests from integration tests and recommends integration coverage for important use cases.

## Current implemented-scope matrix

| Journey / capability | Unit/service | Widget/UI | HTTP E2E | Flutter integration | UX documented |
|---|---:|---:|---:|---:|---:|
| App shell / splash / primary navigation | ✓ | ✓ | — | ✓ | ✓ |
| Four-language selection/fallback | ✓ | ✓ | — | — | ✓ |
| Public cause discovery/detail | ✓ | ✓ | ✓ | — | ✓ |
| Organisation discovery/detail/contact actions | ✓ | ✓ | ✓ | — | ✓ |
| Beneficiary impact explorer | ✓ | ✓ | ✓ | — | ✓ |
| Authentication / identity resolution | ✓ | ✓ | ✓ | — | ✓ |
| Admin role/route protection | ✓ | ✓ | ✓ | — | ✓ |
| Admin content management | ✓ | ✓ | ✓ | — | ✓ |
| Media upload/attachment/partial failure | ✓ | ✓ | ✓ | — | ✓ |
| Application acceptance window | ✓ | ✓ | ✓ | ✓ | ✓ |
| Configurable application rules | ✓ | ✓ | ✓ | ✓ | ✓ |
| Assistance submit/history/delete | ✓ | ✓ | ✓ | ✓ | ✓ |
| Rejected/clarification resubmission | ✓ | ✓ | ✓ | partial | ✓ |
| Pratibha Samman voting/decisions | ✓ | ✓ | ✓ | partial | ✓ |
| Service-window offline UX | ✓ | ✓ | — | targeted widget coverage | ✓ |
| Admin dashboard/analytics/health | ✓ | ✓ | ✓ | — | ✓ |
| Donation allocation | ✓ | ✓ | — | — | roadmap documented |
| Live payment / AutoPay | future | future | future | future | roadmap only |

## Multi-step scenario matrix

For application and admin workflows, tests should cover:

1. Complete success.
2. Validation failure before persistence.
3. Failure after an earlier successful side effect.
4. Accurate partial-success user-visible outcome.
5. Retry without duplicate side effects.
6. Recovery/resubmission when allowed.
7. Authorization boundary.
8. Localized user-visible outcome.

The service tests already cover business-rule variants. The HTTP integration suite verifies those workflows are reachable through actual route and guard boundaries. Flutter integration tests verify the corresponding user-facing availability and rules states.

## Coverage policy

- 70% overall line coverage baseline as the codebase matures.
- 80%+ for new backend domain/service logic.
- 90%+ for future critical financial/payment/allocation logic.
- Do not satisfy coverage by adding tests that merely execute lines without asserting outcomes.

CI publishes backend and Flutter coverage artifacts. Threshold enforcement should be introduced only after a clean-master baseline is captured.

## Definition of done for future features

A new feature updates all applicable columns before completion:

- requirements/documentation;
- implementation;
- unit/service tests;
- widget/UI tests;
- HTTP integration/E2E;
- Flutter integration;
- localization;
- UX/error-state documentation.

If a column is intentionally not applicable, the feature documentation must say why.
