# Public Organisation Profiles and Gallery

Avijit Sahyog organisations are managed by administrators. Users do not upload organisation images.

## User flow

1. A cause detail page lists its active affiliated organisations.
2. The organisation card is tappable and opens the organisation detail page.
3. The detail page shows the administrator-selected logo, public organisation information and administrator-uploaded gallery images.
4. If an organisation has a valid mobile number, the card shows Call and WhatsApp actions.
5. Tapping a gallery image opens a full-screen swipeable viewer with pinch-to-zoom support.

## Media contract

Organisation media continues to use the existing `LOGO` and `GALLERY` media purposes. The public cause response now includes the organisation gallery alongside the logo so the existing cause-detail API flow can render the profile without requiring a second user-facing upload or storage flow.

Only active organisations attached to an active cause are exposed through the cause detail response. Gallery ordering follows the administrator-managed `displayOrder`.

## Affiliate contact actions

Administrators can optionally store an Indian mobile number for an organisation. The backend normalizes valid numbers to E.164 format (`+91...`). The public cause response exposes this field to the Flutter app. The card only renders contact actions for a valid mobile number; Call opens the device dialer and WhatsApp opens the chat using the international number format.
