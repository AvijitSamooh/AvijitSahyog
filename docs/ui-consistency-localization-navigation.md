# UI Consistency, Localization and Navigation

## Shared navigation

The application has three persistent primary destinations:

- Home
- Causes
- Impact

Settings/language is intentionally not a primary bottom-navigation destination. Language remains available from the top-right application menu.

The shared page scaffold supplies bottom navigation to secondary, detail and admin pages so navigation remains consistent. Selecting a primary destination from a secondary page returns to the root shell and changes the selected destination.

## Admin access

Authenticated administrators see Admin Portal directly in the top-right application menu. Users no longer need to open Profile first.

## Localization and typography

All user-visible UI copy must use the four supported Flutter locales:

- English (en)
- Hindi (hi)
- Marathi (mr)
- Gujarati (gu)

Admin analytics, platform health, cause management and beneficiary management copy is localized through the existing ARB files.

The app does not declare an unbundled Poppins font. Shared typography uses platform/font fallback stacks so Indic scripts render with appropriate glyphs while preserving a consistent Material 3 visual system.

## Dropdowns and visual consistency

Material 3 dropdown text and menu shape are standardized through the application theme. Sort labels and other user-visible dropdown values must use localized AppLocalizations strings rather than English-only internal labels.

## Regression coverage

UI tests cover:

- the three-destination navigation model;
- absence of Settings from bottom navigation;
- bottom navigation on secondary/detail pages;
- direct Admin Portal access from the top-right menu for administrators;
- localized language selection;
- existing admin navigation flows.
