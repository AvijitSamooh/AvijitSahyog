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
2. Migrate users, roles, admin authorization and role-audit history; backfill from PostgreSQL and reconcile counts before enabling the Firestore runtime path.
3. Backfill discovery domains: languages, causes, organisations, beneficiaries and media metadata; reconcile source/target counts before runtime cutover.
4. Switch public discovery reads to Firestore while keeping admin writes on PostgreSQL only after the backfill is verified.
5. Migrate application workflows and admin voting/review using Firestore transactions.
6. Keep media objects in Cloudflare R2 while Firestore owns media metadata.
7. Migrate analytics to append-only Firestore writes and replace SQL dashboard aggregation with bounded queries or derived counters.
8. Migrate donations/payment persistence with explicit transaction and idempotency rules.
9. Backfill remaining PostgreSQL data and run reconciliation checks.
10. Switch remaining production traffic to Firestore and observe.
11. Remove Prisma/PostgreSQL only after a successful verification period.

## Non-negotiable invariants

- Existing NestJS API routes and Flutter contracts remain stable unless a Firestore limitation requires an intentional API change.
- Firebase Admin credentials are server-only.
- R2 remains the image/object store during this migration.
- Application status transitions, admin authorization, vote uniqueness and donation validation remain server-enforced.
- Financial records are treated as append-only after payment confirmation.
- No production PostgreSQL deletion occurs in the initial migration.
\n\n## Discovery backfill\n\nThe first discovery migration command is:\n\n`npm run firestore:migrate-discovery`\n\nIt copies languages, causes, organisations, beneficiaries and media metadata using the existing PostgreSQL IDs. Cause/organisation translations and relationships are embedded in their documents so public reads can later avoid relational joins. Media objects remain in Cloudflare R2; only their metadata is copied to Firestore.\n\nThis command is idempotent, does not delete PostgreSQL data, and fails unless the source and target document counts reconcile.\n

## Post-cutover status

The runtime cutover is complete. PostgreSQL/Prisma source migration scripts were intentionally removed after Firestore became authoritative. Historical source-to-Firestore migration is a one-time operational prerequisite; this document is retained as architecture/history, not as an active migration command reference.
