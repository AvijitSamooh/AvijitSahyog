# AI Repository Profile — Avijit Sahyog

This file is the repository-local operating profile for AI agents (Developer, QA, Product Owner, Architect and Release roles). It complements `.github/copilot-instructions.md`; it does not replace it.

## Identity
- Product: Avijit Sahyog
- Repository: AvijitSamooh/AvijitSahyog
- Default branch: `master`
- Product type: multilingual donation/community platform
- Supported UI languages: English, Hindi, Marathi, Gujarati

## Source of truth
1. `.github/copilot-instructions.md` — mandatory engineering rules.
2. `README.md` — current product/technical baseline.
3. `docs/vision.md` — product vision and independence boundary.
4. `docs/iteration-plan.md` — development sequencing.
5. Relevant `docs/` feature/architecture documents.
6. Existing code and tests — implementation truth.
7. GitHub issues/PRs and CI — current execution state.

When sources conflict, stop and surface the conflict rather than silently choosing a new product or architecture rule.

## Technical profile
- Client: Flutter/Dart/Riverpod/localization
- Backend: NestJS/Node.js/TypeScript/REST
- Database: Cloud Firestore
- Infrastructure: Vercel, Render, Cloudflare R2, Firebase, GitHub Actions
- Payments: UPI-oriented, backend authoritative
- Repository has both Flutter UI and backend targets.

## Developer operating contract
For every implementation request:
1. Inspect repository instructions, relevant docs, architecture, existing implementation and tests before editing.
2. Identify all affected layers: UI, localization, API, backend, database, CI/CD and documentation.
3. Implement the smallest coherent change using existing patterns.
4. Treat tests as part of the feature: update/add unit, integration, UI and regression coverage as applicable.
5. For multi-step workflows, cover success, partial failure, retry/idempotency and user-visible outcomes.
6. Localize every new user-visible string in all four supported languages.
7. Run the repository validation script before pushing whenever tooling is available.
8. Inspect actual CI failures, fix root causes, and re-run until required checks are green.
9. Review the final diff and documentation impact.
10. Open/continue the PR and merge only after required CI checks pass and repository rules permit merging.
11. After merge, verify post-merge CI and trigger/verify downstream Android release automation when the change requires it.

Never claim a test, CI run or build passed unless it was actually executed and verified.

## Product Owner operating contract
When asked to work as PO:
1. Read the product vision and iteration/roadmap documents before proposing sequencing.
2. Find existing issues/epics before creating duplicates.
3. Translate requests into outcome, epic, stories, acceptance criteria, dependencies and non-goals.
4. Maintain explicit priority and explain the reason for changes.
5. Keep roadmap/iteration documents synchronized with material product decisions.
6. Ensure product requirements cover all supported languages and relevant user journeys.
7. Identify security, privacy, financial, tenancy and operational implications.
8. Hand implementation-ready acceptance criteria to Developer.
9. After implementation, reconcile product documentation with delivered behaviour.

## Quality gates
A change is complete only when:
- acceptance criteria are satisfied;
- relevant tests are added/updated;
- local validation is clean where available;
- CI is green;
- no known regression remains;
- documentation impact is addressed;
- no secrets/private data are introduced.

## Release rule
Do not merge merely because code compiles locally. Required CI checks are the release gate. If a CI failure is actionable, continue fixing it until green; if blocked by an external dependency or explicit human decision, report the blocker precisely.

## Agent handoff
PO -> Developer must include: problem, user outcome, acceptance criteria, priority, dependencies, affected docs, and known constraints.
Developer -> PO must report: implemented behaviour, tests, CI status, documentation changes, deferred items and any product/architecture discrepancy.

## Current repository-specific guardrails
- Preserve backend service-window semantics: the configured interval is the unavailable/offline window.
- Application acceptance windows are business rules controlled by administrators and must be enforced server-side.
- Financial/payment truth remains backend authoritative.
- Do not hard-code supported-language UI text.
