# AvijitSahyog Firestore architecture

## Target architecture

Flutter -> Firebase Authentication -> NestJS API -> Cloud Firestore
                                      -> Cloudflare R2

Firebase Authentication already exists in the application. The persistence cutover is complete: Firestore is authoritative and PostgreSQL/Prisma is no longer a runtime dependency.

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

Relational join tables are represented as embedded fields, references, or subcollections where that produces simpler Firestore reads. The design does not mechanically reproduce every former relational table.

## Runtime invariants

- Existing NestJS API routes and Flutter contracts remain stable unless a Firestore limitation requires an intentional API change.
- Firebase Admin credentials are server-only.
- Cloudflare R2 remains the image/object store.
- Application status transitions, admin authorization, vote uniqueness and donation validation remain server-enforced.
- Financial records are treated as append-only after payment confirmation.
- Firestore is the authoritative runtime persistence layer.

## Migration history

The historical PostgreSQL -> Firestore backfill was idempotent and reconciliation-gated. PostgreSQL data was retained during the transition so rollback/reconciliation was possible. After the Firestore cutover was verified, Prisma/PostgreSQL application code, migrations and CI dependencies were removed.

The historical migration steps are retained in git history for auditability; they are not active runtime commands.
