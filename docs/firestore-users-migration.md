# Firestore users and authorization

This migration is complete. Authenticated user persistence and role/authorization data are stored in Firestore.

## Firestore collections

### users/{internalUserId}

The document ID preserves the former internal identifier so downstream records can retain stable references.

Fields:
- id
- firebaseUid
- email
- displayName
- photoUrl
- role: USER, ADMIN, or SUPER_ADMIN
- preferredLanguage
- createdAt
- updatedAt
- searchTokens: generated lowercase prefixes used by server-side admin search

### auditLogs/{auditId}

Role-change audit records are stored with stable IDs. New role changes are written with the user role update.

## Runtime behaviour

- GET /auth/me resolves and upserts the user in Firestore.
- AdminGuard and SuperAdminGuard read roles from Firestore.
- Super-admin user management reads/writes Firestore.
- PostgreSQL is not used by these runtime paths or by the current backend persistence layer.
- Existing API response shapes are preserved.

Admin search uses bounded prefix tokens because Firestore does not provide PostgreSQL-style arbitrary substring matching. This is an intentional contract-preserving approximation for common name/email searches.
