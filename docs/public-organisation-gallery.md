# Public Organisation Profiles and Gallery

Avijit Sahyog organisations are managed by administrators. Users do not upload organisation images.

## User flow

1. A cause detail page lists its active affiliated organisations.
2. The organisation card is tappable and opens the organisation detail page.
3. The detail page shows the administrator-selected logo, public organisation information and administrator-uploaded gallery images.
4. Tapping a gallery image opens a full-screen swipeable viewer with pinch-to-zoom support.

## Media contract

Organisation media continues to use the existing `LOGO` and `GALLERY` media purposes. The public cause response now includes the organisation gallery alongside the logo so the existing cause-detail API flow can render the profile without requiring a second user-facing upload or storage flow.

Only active organisations attached to an active cause are exposed through the cause detail response. Gallery ordering follows the administrator-managed `displayOrder`.
