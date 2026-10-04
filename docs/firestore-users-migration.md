# Firestore users and authorization migration

This slice moves the authenticated user and role/authorization boundary to Firestore while keeping the rest of the application on PostgreSQL/Prisma.

## Firestore collections

### `users/{internalUserId}`

The document ID remains the existing PostgreSQL UUID so downstream migrations can preserve identifiers.

Fields:
- `id`
- `firebaseUid`
- `email`
- `displayName`
- `photoUrl`
- `role`: `USER`, `ADMIN`, or `SUPER_ADMIN`
- `preferredLanguage`
- `createdAt`
- `updatedAt`
- `searchTokens`: generated lowercase prefixes used by server-side admin search

### `auditLogs/{auditId}`

Existing role-change audit records are copied with the same IDs. New role changes are written atomically with the user role update.

## Runtime behaviour

- `GET /auth/me` resolves and upserts the user in Firestore.
- `AdminGuard` and `SuperAdminGuard` read roles from Firestore.
- Super-admin user management reads/writes Firestore.
- PostgreSQL remains untouched by these runtime paths after the cutover.
- Existing API response shapes are preserved.

Admin search uses bounded prefix tokens because Firestore does not provide PostgreSQL-style arbitrary substring matching. This is an intentional contract-preserving approximation for common name/email searches; the token strategy is documented so it can be evolved without changing the API.

## Backfill

Run:

`npm run firestore:migrate-users`

The migration:
1. Reads users and role-change audit logs from PostgreSQL.
2. Upserts Firestore documents using the original IDs.
3. Is idempotent and does not delete PostgreSQL records.
4. Reconciles source and target document counts before succeeding.

Run it once before enabling the Firestore-backed runtime paths in production, and keep PostgreSQL available for rollback until the migration has been observed in production.
