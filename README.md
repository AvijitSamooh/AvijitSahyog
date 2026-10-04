# Avijit Sahyog

A multilingual, independent donation and community-help platform.

## Technology
- Flutter / Dart / Riverpod
- NestJS / Node.js / TypeScript / REST
- Firebase Authentication
- Cloud Firestore
- Cloudflare R2
- Firebase Analytics
- GitHub Actions / Render / Vercel

## Runtime downtime

Backend downtime is controlled by a SUPER_ADMIN and persisted in Firestore at `platformSettings/downtime`. Login remains available during downtime. Super Admin authentication and the downtime control endpoint remain available, while ordinary backend requests receive a server-side 503 response. The backend evaluates the configured window in Asia/Kolkata.

## Backend environment

The NestJS service uses `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY`, the R2 credentials, `EXPORT_TOKEN_SECRET`, `CORS_ORIGINS` and `PORT`. PostgreSQL/Prisma is no longer a runtime dependency.

## Local validation

Use `scripts/validate.ps1` or the CI workflow to run backend and Flutter checks. Never commit production secrets.