# Firebase persistence foundation

AvijitSahyog is being migrated from PostgreSQL/Prisma to Cloud Firestore incrementally.

Runtime configuration:
- FIREBASE_PROJECT_ID
- FIREBASE_CLIENT_EMAIL
- FIREBASE_PRIVATE_KEY (service-account private key; escaped newline sequences are supported)

For local development, GOOGLE_APPLICATION_CREDENTIALS may point to a service-account JSON file. Never commit that file or place it in Flutter/mobile configuration.

The NestJS API remains the trusted server boundary. Flutter must not receive service-account credentials or directly mutate protected Firestore collections.

Do not remove Prisma/PostgreSQL until all production persistence paths have been migrated and verified.
