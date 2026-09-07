# Avijit Sahyog Development Rules

This repository is developed collaboratively by humans and AI agents. These rules are mandatory for all new features and changes.

## 0. Branch and Pull Request Safety

- **Never commit directly to `master`/`main`.**
- Create a dedicated feature, fix or chore branch from the latest `master` before making changes.
- All changes must reach `master` through a Pull Request with CI checks.
- Do not merge a PR unless required CI checks pass, except when a repository owner explicitly approves an exception.
- Follow every rule in this document for every change, including small fixes and AI-generated code.
- Before editing, confirm the target branch is not `master`/`main`.

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

### Multi-step workflows and partial failures

For any user action that performs more than one persistence, API, storage, or external-service operation, tests must cover the workflow boundaries—not only the individual methods.

Required scenario matrix:

- Complete success across all steps.
- Failure before any persistent side effect.
- Failure after each successful persistent side effect.
- Accurate user-visible outcome for partial success.
- Retry behaviour, including protection against duplicate records or repeated unintended side effects.
- Recovery path when the user can safely resume or edit the already-created entity.

Before implementation, explicitly identify the ordered workflow steps and their side effects. Do not wrap a multi-step workflow in a single generic error assertion that hides whether an earlier step succeeded.

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

## 7. Mandatory Local Validation and CI Discipline

GitHub Actions CI is a final confirmation gate, **not a debugging environment**. Before creating a commit, pushing code, opening a PR, or requesting review, validate affected code locally whenever the execution environment supports the required tooling.

### Mandatory repository validation script

Run from the repository root before every push:

```powershell
# Default: validate Flutter UI and backend
.\scripts\validate.ps1

# Optional targeted validation
.\scripts\validate.ps1 -Target ui
.\scripts\validate.ps1 -Target backend
```

The default command validates both targets and must be used for normal feature work. Targeted commands are useful while iterating on an isolated layer, but run the default command before pushing whenever both toolchains are available.

### Flutter — validation sequence

The UI target runs:

```bash
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
flutter build web
```

Rules:

- Do not commit or push with known compilation, analyzer, or test failures.
- Run the complete Flutter test suite, not only a targeted test, before pushing.
- When UI structure, titles, navigation, widgets, localization, or page shells change, proactively inspect affected existing UI/widget tests and update stale expectations before validation.
- Fix failures locally and repeat validation until clean.
- Do not make speculative commits solely to discover the next CI failure.
- Prefer one consolidated, locally validated commit over repeated "fix CI" commits.
- If the agent execution environment cannot run Flutter commands, explicitly state exactly which commands could not be run and why. Never claim validation passed when it was not executed.
- If commands are available, running them is mandatory; inspecting code or reasoning about likely correctness is not a substitute.

### Backend

The backend target runs:

```bash
npm ci
npm run prisma:generate
npm run build
npm test
```

Also validate affected Prisma schema/migrations.

CI failures must be fixed by reading the actual failing job logs. Do not repeatedly change tests based on assumptions.

### Required delivery workflow

1. Inspect architecture and affected tests.
2. Implement the complete coherent change.
3. Update localization and tests.
4. Run the mandatory repository validation script (default: both UI and backend).
5. Fix every failure locally.
6. Re-run validation until clean.
7. Review the final diff for regressions and debug artifacts.
8. Commit and push once validation is clean.
9. Use GitHub CI as final confirmation only.

Do not report implementation work as complete until this workflow has been followed, or any unavailable validation has been explicitly disclosed.

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
- [ ] Documentation impact has been explicitly reviewed
- [ ] Existing automated tests affected by the change have been updated
- [ ] New or changed behaviour has appropriate regression coverage
- [ ] Multi-step workflows include boundary/partial-failure and retry-safety coverage where applicable
- [ ] Relevant `docs/` files are updated for every significant product flow, domain, architecture, API contract, or operational change
- [ ] If no documentation changed, the PR explains why the change is implementation-only
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
6. Run mandatory local analysis/tests before committing or pushing; inspect CI only as final confirmation.
7. Fix root causes, not symptoms.
8. Update documentation when behaviour or architecture changes.
9. Before declaring the work complete, explicitly review whether the change alters product vision, user flow, domain model, API contract, architecture, iteration plan, or operational assumptions. If yes, update the relevant `docs/` files in the same PR and explain the documentation impact in the PR.
10. Treat tests as part of the implementation contract. When changing a feature, user flow, API contract, domain model, validation rule, UI behaviour, or architecture, identify and update/add the affected automated tests in the same PR. Do not leave stale tests that describe the old behaviour.

Never declare a fix complete without verifying the relevant checks.
