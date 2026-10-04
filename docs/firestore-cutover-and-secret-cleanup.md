# Firestore cutover and secret cleanup

This document is the final cleanup checklist for the PostgreSQL/Prisma retirement.

## Keep in production

These remain required after PostgreSQL is removed:

- `FIREBASE_PROJECT_ID`
- `FIREBASE_CLIENT_EMAIL`
- `FIREBASE_PRIVATE_KEY`
- `R2_ENDPOINT`
- `R2_ACCESS_KEY_ID`
- `R2_SECRET_ACCESS_KEY`
- `R2_BUCKET_NAME`
- `R2_PUBLIC_BASE_URL`
- `EXPORT_TOKEN_SECRET`
- `CORS_ORIGINS`
- `PORT`

The Android release pipeline also continues to need:

- `ANDROID_KEYSTORE_BASE64` (GitHub Actions secret)
- `ANDROID_STORE_PASSWORD` (GitHub Actions secret)
- `ANDROID_KEY_PASSWORD` (GitHub Actions secret)
- `ANDROID_KEY_ALIAS` (GitHub Actions secret)
- `PLAY_STORE_SERVICE_ACCOUNT_JSON` (GitHub Actions secret)
- `GOOGLE_SERVICES_JSON` (GitHub Actions repository variable)
- `API_BASE_URL` (GitHub Actions repository variable)

## Remove after final cutover

Only remove these after the final PostgreSQL reconciliation has succeeded and the old service is no longer deployed:

- `DATABASE_URL`
- `DIRECT_URL`
- Neon/PostgreSQL connection secrets or environment variables with equivalent names
- any Render/Neon database attachment that exists only for Avijit Sahyog
- Prisma-specific CI configuration
- PostgreSQL CI service configuration
- `BACKEND_SERVICE_WINDOW_ENABLED`
- `BACKEND_SERVICE_OFFLINE_START`
- `BACKEND_SERVICE_OFFLINE_END`

The last three are legacy build-time downtime variables. Runtime downtime is now persisted in Firestore and controlled by SUPER_ADMIN.

## Do not remove

Do not remove Firebase Admin credentials, R2 credentials, Android signing credentials, Play Store publishing credentials, or `EXPORT_TOKEN_SECRET`. They serve independent production functions.

## Final removal order

1. Complete all PostgreSQL -> Firestore data migrations.
2. Run reconciliation for every migrated collection and relationship.
3. Confirm production reads and writes no longer touch Prisma/PostgreSQL.
4. Remove Prisma from application modules and runtime services.
5. Remove PostgreSQL readiness checks and health dependencies.
6. Remove Prisma packages, scripts, schema and migrations.
7. Remove PostgreSQL from CI.
8. Restore `npm ci` in CI and verify the lockfile.
9. Deploy the Firestore-only backend.
10. Observe production for one release cycle.
11. Remove the PostgreSQL/Neon deployment and its credentials.
12. Rotate any credentials that were only needed for the old deployment.

Never delete the old database before reconciliation and a verified production cutover.
