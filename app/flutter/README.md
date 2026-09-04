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
flutter test --coverage
```

UI tests should cover primary journeys plus important loading, empty and error states.

- Dynamically managed organisation logos and beneficiary profile/gallery images delivered from the public API
