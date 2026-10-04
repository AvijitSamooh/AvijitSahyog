# AvijitSahyog PostgreSQL to Firestore migration

## Target architecture

Flutter -> Firebase Authentication -> NestJS API -> Firestore
                                      -> Cloudflare R2

Firebase Authentication already exists in the application, so this migration replaces the persistence layer rather than the authentication model.

## Collection design

- users/{userId}
- causes/{causeId}
- organisations/{organisationId}
- beneficiaries/{beneficiaryId}
- applications/{applicationId}
- applications/{applicationId}/votes/{adminId}
- applicationRules/{ruleId}
- applicationWindows/{type}
- donations/{donationId}
- analyticsEvents/{eventId}
- auditLogs/{auditId}
- media/{mediaId}

Relational join tables will be embedded or represented as references/subcollections where that produces simpler reads. We will not mechanically reproduce every Prisma table.

## Migration phases

1. Add Firebase Admin/Firestore foundation without changing API behavior.
2. Migrate read-only discovery domains: languages, causes, organisations, beneficiaries.
3. Migrate application workflows and admin voting/review using Firestore transactions.
4. Migrate media metadata while retaining Cloudflare R2.
5. Migrate analytics to append-only Firestore writes and replace SQL dashboard aggregation with bounded queries or derived counters.
6. Migrate donations/payment persistence with explicit transaction and idempotency rules.
7. Backfill PostgreSQL data and run reconciliation checks.
8. Switch production traffic to Firestore and observe.
9. Remove Prisma/PostgreSQL only after a successful verification period.

## Non-negotiable invariants

- Existing NestJS API routes and Flutter contracts remain stable unless a Firestore limitation requires an intentional API change.
- Firebase Admin credentials are server-only.
- R2 remains the image/object store during this migration.
- Application status transitions, admin authorization, vote uniqueness and donation validation remain server-enforced.
- Financial records are treated as append-only after payment confirmation.
- No production PostgreSQL deletion occurs in the initial migration.
