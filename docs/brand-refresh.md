# Avijit Sahyog brand refresh

## Scope

Avijit Sahyog is presented as part of the Avijit Samuh ecosystem. The app uses the Avijit Samuh visual language, the existing Muni Shri Ajitsagar Ji asset, and a dedicated opening sequence introducing the guru connection before entering the main application.

The Avijit Samuh website describes the organisation as working in education, service, cooperation and recognition. The app retains that four-part visual vocabulary in its branded presentation.

## Visual system

The application theme uses one shared palette:

- Primary maroon: #6E1A14
- Deep maroon: #4C120D
- Saffron: #F5A623
- Cream: #FFF8ED
- Soft cream: #FCE8C9
- Primary text: #39271C
- Secondary text: #6B4F36
- Divider: #E8DCC8

Feature screens should consume Theme.of(context) and AppTheme rather than introducing a new palette.

## Navigation

AppNavigationBar is the single shared primary bottom navigation component. Tab destinations stay inside the existing AppShellScope navigation controller.

## Assets

Guru and brand imagery is intentionally referenced through Flutter asset paths. The existing assets/images/AjitSagarJi.png remains replaceable without changing Dart code.

The official Avijit Samuh logo and the selected Acharya Shri Vidyasagar Ji image should be stored beside that asset using:

- assets/images/AvijitSamuhLogo.png
- assets/images/VidyasagarJi.png

## Localization

New branding strings are localized in English, Hindi, Marathi and Gujarati.

## Testing

The refresh adds regression coverage for the splash branding and preserves the shared navigation consistency test.
