# Avijit Sahyog Flutter App

Flutter client for the Avijit Sahyog donation platform.

## Current features

- Multilingual application shell
- Home experience with Maharaj Ji hero image
- Cause discovery
- Cause-centric donation entry flow
- Affiliated organisation transparency
- Impact Explorer with beneficiary cards
- Beneficiary impact story detail
- Search and sorting for beneficiary discovery
- Backend-driven API configuration using `API_BASE_URL`
- Firebase Authentication with Google Sign-In and backend identity resolution

## Run locally

```bash
flutter pub get
flutter gen-l10n
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

## Test and quality

```bash
flutter analyze
flutter test
flutter test integration_test
flutter test --coverage
```

UI tests should cover primary journeys plus important loading, empty and error states.

- Dynamically managed organisation logos and beneficiary profile/gallery images delivered from the public API


## Firebase authentication

Firebase must be configured before running the authentication flow:

1. Register the target Android/Web applications in the Firebase project.
2. Run `flutterfire configure` from `app/flutter`.
3. Enable the Google provider in Firebase Authentication.
4. Configure the backend with Firebase Admin credentials so `/auth/me` can verify ID tokens.

The Flutter app initializes Firebase at startup, restores an existing Firebase session, exchanges the Firebase ID token with the backend through `GET /auth/me`, and uses the resolved backend role to unlock protected admin operations.


## UX and integration coverage

Detailed application journeys are covered by the unit/widget suites; the integration_test/ suite validates the real Linux runtime and native plugin boundary. CI runs these integration tests on Linux with an X virtual framebuffer.

See ../../docs/user-experience.md for the user journey specification and ../../docs/test-and-ux-matrix.md for traceability.
