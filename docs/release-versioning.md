# Android Release Versioning

Android releases published by the CI workflow use a version derived from the base version in `app/flutter/pubspec.yaml` and the GitHub Actions run.

For example, with:

- base version: `1.0.0`
- GitHub Actions run number: `80`
- run attempt: `1`

the published release uses:

- **versionName:** `1.0.80.01`
- **versionCode:** `10008001`

The version name is intended to be the human-readable release identifier shown by Google Play. The version code remains the numeric Android release identifier required for Play uploads.

The CI workflow extracts the major and minor components from `pubspec.yaml`; the patch component in `pubspec.yaml` is not used for CI-published Android releases. The GitHub Actions run number and attempt provide the CI build identity.

Local Flutter builds continue to use the version declared in `pubspec.yaml` unless `--build-name` and `--build-number` are supplied explicitly.
