# Avijit Sahyog Development Rules

This repository is developed collaboratively by humans and AI agents. These rules are mandatory for all new features and changes.

## 1. Before Writing Code

- Inspect the existing architecture and nearby implementations before changing code.
- Prefer extending existing patterns over introducing parallel patterns.
- Understand the full user flow, not just the requested screen.
- Identify affected Flutter, backend, database, localization and test layers.
- Do not make speculative fixes. When CI fails, inspect the actual failing logs first.

## 2. Flutter Architecture

- Keep feature code organised by feature and responsibility.
- Reuse shared components, theme values and navigation patterns.
- Tab destinations must remain inside the main navigation shell; do not push a tab page with Navigator when selecting an existing bottom-navigation destination.
- Avoid nested Scaffold/AppBar structures unless explicitly required.
- Use responsive layouts and support loading, empty and error states.
- Assets must be committed and registered in `app/flutter/pubspec.yaml`.
- Asset paths are case-sensitive and must exactly match committed filenames.

## 3. Localization Is Mandatory

Every new user-visible string must support all currently supported languages:

- English (`en`)
- Hindi (`hi`)
- Marathi (`mr`)
- Gujarati (`gu`)

Rules:

- Do not introduce hardcoded user-visible strings in widgets.
- Add matching keys to every `app_*.arb` file.
- Use generated `AppLocalizations` in Flutter.
- Ensure new screens remain reachable with the existing language selector.
- Add/update localization tests when a feature introduces new localized UI.

## 4. Backend Service Rules

For new backend functionality:

- Keep controllers thin.
- Put business logic in services.
- Validate request input with DTOs and validation decorators.
- Use Prisma through the established data-access pattern.
- Define explicit response/error behaviour.
- Avoid leaking database implementation details unnecessarily.
- Add pagination/filtering/sorting where collection growth makes it appropriate.
- Update Prisma schema, migrations and seed data together when changing persistent models.
- Production database changes must use committed Prisma migrations; do not depend on `db push`.

## 5. API Contract Rules

- Keep endpoint naming consistent with existing REST conventions.
- Do not silently break existing response shapes.
- Handle loading, empty and error states in Flutter for API-backed features.
- When adding query parameters, test default, valid and invalid combinations.
- Update client models/repositories/providers when backend contracts change.

## 6. Testing Is Part of the Feature

A feature is not complete without tests.

### Flutter

Add or update tests for:

- Primary user journey
- Navigation
- Loading state where relevant
- Empty state where relevant
- Error state where relevant
- Important regressions introduced by the change
- Localization-sensitive UI when new strings/screens are added

Prefer stable behavioural assertions over brittle implementation details.

For scrollable widgets, remember that off-screen content may be lazily built. Scroll into view before asserting lower content.

### Backend

Add or update tests for:

- Service business logic
- Important controller/API behaviour
- Filtering and sorting
- Validation and error cases
- Regression scenarios

Critical donation, allocation and payment logic requires scenario-based tests.

## 7. CI Discipline

Before considering work complete:

### Flutter

```bash
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
```

### Backend

```bash
npm ci
npm run prisma:generate
npm test
```

Also validate affected Prisma schema/migrations.

CI failures must be fixed by reading the actual failing job logs. Do not repeatedly change tests based on assumptions.

## 8. Definition of Done

Before opening a PR, verify:

- [ ] Feature works in the intended user flow
- [ ] Existing navigation is not broken
- [ ] All new UI strings are localized
- [ ] Assets are committed and registered
- [ ] Backend changes have DTO/service/controller tests
- [ ] Flutter feature/regression tests are included
- [ ] Existing tests still pass
- [ ] Static analysis passes
- [ ] Database migrations/seeds are updated if needed
- [ ] Documentation is updated for meaningful architectural or feature changes
- [ ] CI logs have been checked for any failure

## 9. Coverage Goals

Coverage is a quality signal, not a substitute for meaningful tests.

Targets:

- Aim for 70%+ overall project coverage as the codebase matures
- Aim for 80%+ coverage for new domain/service logic
- Aim for 90%+ coverage for critical financial, allocation and payment logic

Do not add trivial tests merely to increase percentages. Prioritise meaningful branches, failure paths and real user journeys.

## 10. AI Agent Working Principle

When implementing a change:

1. Inspect before editing.
2. Identify all affected layers.
3. Implement the smallest coherent solution.
4. Add localization for every new user-visible string.
5. Add tests in the same change.
6. Run analysis/tests or inspect CI results.
7. Fix root causes, not symptoms.
8. Update documentation when behaviour or architecture changes.

Never declare a fix complete without verifying the relevant checks.
