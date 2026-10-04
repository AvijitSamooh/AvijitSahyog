# Firebase persistence

AvijitSahyog uses Cloud Firestore as the authoritative application persistence layer.

## Runtime configuration

- FIREBASE_PROJECT_ID
- FIREBASE_CLIENT_EMAIL
- FIREBASE_PRIVATE_KEY (service-account private key; escaped newline sequences are supported)

For local development, GOOGLE_APPLICATION_CREDENTIALS may point to a service-account JSON file. Never commit that file or place it in Flutter/mobile configuration.

The NestJS API is the trusted server boundary. Flutter must not receive service-account credentials or directly mutate protected Firestore collections.

Cloudflare R2 remains the object store for uploaded media; Firestore stores the application and media metadata.
