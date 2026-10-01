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
| Public cause discovery/detail | ✓ | ✓ | — | — | ✓ |
| Organisation discovery/detail/contact actions | ✓ | ✓ | — | — | ✓ |
| Beneficiary impact explorer | ✓ | ✓ | — | — | ✓ |
| Authentication / identity resolution | ✓ | ✓ | — | — | ✓ |
| Admin role/route protection | ✓ | ✓ | — | — | ✓ |
| Admin content management | ✓ | ✓ | — | — | ✓ |
| Media upload/attachment/partial failure | ✓ | ✓ | — | — | ✓ |
| Application acceptance window | ✓ | ✓ | ✓ | — | ✓ |
| Configurable application rules | ✓ | ✓* | ✓ | — | ✓ |
| Assistance submit/history/delete | ✓ | ✓ | ✓ | — | ✓ |
| Rejected/clarification resubmission | ✓ | ✓ | ✓ | — | ✓ |
| Pratibha Samman voting/decisions | ✓ | ✓ | ✓ | — | ✓ |
| Service-window offline UX | ✓ | ✓ | — | targeted widget coverage | ✓ |
| Admin dashboard/analytics/health | ✓ | ✓ | — | — | ✓ |
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

### Application rules — rendered UI regression matrix

The configurable-rules row is considered covered by widget/UI tests only when the test verifies the **user-visible rendered output**, not merely provider/service data.

| Regression scenario | Required boundary | Assertion |
|---|---|---|
| Rule number renders | Widget/UI | Visible ordinal such as `1.` |
| Rule text renders | Widget/UI | Exact localized rule text is visible |
| English rule rendering | Widget/UI | English translation appears |
| Hindi rule rendering | Widget/UI | Hindi translation appears |
| Marathi rule rendering | Widget/UI | Marathi translation appears |
| Gujarati rule rendering | Widget/UI | Gujarati translation appears |
| Language/provider wiring | Widget/UI | Selected locale requests and displays the matching translation |
| Important dates | Widget/UI | Available/registration/event dates display actual values, not implementation placeholders |
| Literal interpolation regression | Widget/UI | No literal `${...}` implementation expression is visible |
| Long/multiline rule | Widget/UI | Full rule remains readable without clipping |
| Loading/empty/error | Widget/UI | Explicit state and retry/empty behaviour are asserted where applicable |
| Admin translation → user rendering | Widget + HTTP | Saved translation is returned and rendered for the selected language |

`*` For configurable rules, a passing provider/service test alone is insufficient. The UI test must exercise the actual screen and assert rendered content.

### Release regression gate

For a user-visible dynamic feature, coverage must validate the path:

**persisted/API data → repository/provider → widget → rendered user-visible result**

A test that only verifies an intermediate model/provider response does not count as UI regression coverage.

For multilingual features, at least one representative rendered assertion is required for each supported language when the feature's content itself is localized (English, Hindi, Marathi and Gujarati). Tests must also assert that implementation placeholders such as escaped interpolation are not displayed to users.


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


### Flutter integration boundary

Detailed application UX states are intentionally covered by widget tests because they require controlled Riverpod/application state. The integration suite separately validates that the Flutter application can launch on the CI Linux target and execute a real native plugin call (SharedPreferences). This avoids turning integration tests into slow duplicates of widget tests while still exercising the native/runtime boundary.
