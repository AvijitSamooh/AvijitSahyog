# Help & Recognition Applications

## Purpose

Avijit Sahyog supports authenticated applications for two assistance programs and one recognition program.

### Assistance

- **Education Assistance** — a user can request help for education-related need.
- **Medical Help** — a user can request medical assistance.
- **Cause detail entry points** — the Education and Healthcare cause detail pages also expose the relevant assistance application directly, so users do not have to navigate through the separate applications page.

Applicants provide a requested amount and supporting images. Administrators review the application, record individual votes, and can approve an amount for donation, request clarification, or reject with a reason.

### Pratibha Samman

A student can apply with marksheets and achievement evidence. For the 2025-26 batch, the form also collects a clear face photo for certificate printing, mother and father names, date of birth, class/standard, school/institute name, address and mobile/WhatsApp contact, plus optional additional accomplishments. Administrators review the evidence, record a 1–5 score and optional comment, and can mark the profile as **Considered for Samman** or **Not Selected**.

The Pratibha Samman application window exposes three important dates: form availability, the last registration date, and the event date. The 2026 event date is intended to be Sharad Purnima, 25 October 2026; the registration deadline remains administrator-configurable. The event is organised under **Avijit Sarv Kalyaan Samiti**, registration number **01/05/03/37787/21**. Avijit Sahyog is part of the Avijit Samooh ecosystem.

Pratibha Samman is deliberately a separate workflow from need-based assistance.

## User workflow

    Sign in
      ↓
    Choose Education Assistance / Medical Help / Pratibha Samman
      ↓
    Enter application details
      ↓
    Upload supporting images
      ↓
    Submit
      ↓
    Application history + current status
      ↓
    Open full application / edit while non-final
      ↓
    Success confirmation after submit / localized error on failure
      ↓
    Applicant can delete their own non-final application
      ↓
    If rejected or clarification requested
      ↓
    Resubmit with clarification and updated evidence

## Assistance review workflow

    SUBMITTED
      ↓
    UNDER_REVIEW
      ↓
    Admin votes (1–5)
      ↓
    APPROVED_FOR_DONATION
      OR
    CLARIFICATION_REQUIRED
      OR
    REJECTED

For approved assistance, both requested and approved amounts are retained. The approved amount cannot exceed the requested amount.

A rejection requires a reason. A clarification request requires the clarification details.

## Pratibha Samman review workflow

    SUBMITTED
      ↓
    Admin votes / compares applications
      ↓
    CONSIDERED_FOR_SAMMAN
      OR
    NOT_SELECTED

Each administrator has one vote per application and can update that vote. The admin view exposes the average score so applications can be compared consistently.

## Media

Authenticated users can upload JPEG, PNG and WebP evidence through the existing R2 media foundation. Uploads are validated from image bytes rather than trusting the multipart MIME type. Uploaded media is linked to the application through explicit foreign-key relations.

The upload and submission steps are intentionally separate so storage failures do not create a partially persisted application record. Before R2 storage, every accepted image is auto-rotated, resized to at most 1600px on either axis, converted to WebP, and progressively re-encoded when the processed object exceeds 1.5 MB. The original camera file is never stored. An application cannot be submitted without at least one evidence image.

## API

Authenticated user endpoints:

- POST /media/upload
- POST /applications
- GET /applications/mine
- GET /applications/mine/:id
- PATCH /applications/mine/:id
- DELETE /applications/mine/:id
- DELETE /media/:id (only for unreferenced user-uploaded images)
- PATCH /applications/mine/:id/resubmit

Administrator endpoints:

- GET /admin/applications
- GET /admin/applications/photo-manifest
- POST /admin/applications/certificate-photo-export (creates a short-lived certificate ZIP download)
- GET /exports/certificate-photos?token=... (short-lived certificate ZIP download)
- POST /admin/applications/:id/vote
- PATCH /admin/applications/:id/review

## Statuses

- SUBMITTED
- UNDER_REVIEW
- CLARIFICATION_REQUIRED
- APPROVED_FOR_DONATION
- REJECTED
- CONSIDERED_FOR_SAMMAN
- NOT_SELECTED

## Product boundary

Approval makes an assistance application suitable for donation; it does not itself create a donation or move money. Payment, donation allocation and settlement remain separate financial workflows.


## Applicant information

Every new help or recognition application collects a contact snapshot from the applicant:

- Full name
- Mobile number
- Email (optional)
- Address
- City
- State
- PIN code
- Requested amount for assistance applications
- Need/achievement explanation
- Mandatory clear face photo
- Supporting documents or images
- Pratibha Samman certificate photo (recognition applications only)
- Mother name, father name, date of birth, class/standard and school/institute (recognition applications only)
- Other accomplishments (optional for recognition applications)

The applicant details are stored with the application so administrators can review the request even if the user's profile later changes.

Supporting images are uploaded through the authenticated user media endpoint before the application is submitted. The UI supports gallery selection and camera capture, shows uploaded previews/count and upload progress, limits an application to 10 images, and surfaces upload errors so the user can retry. The Pratibha Samman certificate photo supports both gallery and camera capture and shows the same upload-progress feedback.


## Submission and deletion behaviour

The submit action disables itself while the backend call is in flight. On success, the applicant receives an explicit localized confirmation dialog before returning to application history; on failure, the form remains open and shows a localized error so the applicant can retry without unknowingly creating duplicate submissions.

Applicants can delete their own applications while they are not in a final approval/recognition state. Finalised applications are retained for review and audit continuity.

Administrator review actions surface localized success/failure feedback. Pratibha Samman decisions explicitly support both **Considered for Samman** and **Not Selected**.


### Application rules

Administrators can configure ordered acceptance rules for each application type. Application windows additionally support a form availability date, registration deadline and event date; the backend prevents submissions after the configured registration deadline. Rules require English, Hindi, Marathi and Gujarati text. Applicants see the active rules in their selected language and must acknowledge every current rule before submission; the backend validates the full active rule set and stores a text snapshot of the acknowledged rules with the application.

### Selected Pratibha Samman students in Labharthi / Impact

When an administrator selects a Pratibha Samman application, the student is automatically published into the existing Beneficiary (Labharthi) / Impact explorer. The submitted clear certificate photo is used as the public profile photo, supporting evidence is available as gallery media, and the public story includes the 2025-26 batch, class/standard, school/institute, achievements and the administrator's recognition note. The publication is linked to the source application so the same application cannot create duplicate beneficiary records. Recognition beneficiaries do not display a monetary contribution amount.

### Application management UX

Applicants can open any non-final application from history to view the complete submitted details and uploaded images. Non-final applications can be edited; saving an edit replaces the submitted media/rules snapshot and restarts the review cycle. Removed supporting images are detached and cleaned from storage when they are no longer referenced. Final decisions cannot be edited.

Every new application requires a clear face photo. The face photo is displayed on applicant history and administrator application cards. For Pratibha Samman, the certificate face photo is also used as the application face photo unless a separate certificate photo is supplied.

The administrator portal separates **Applications** from **Application configuration** so application review/list browsing cannot accidentally open window/rule editing controls. The application list opens a full detail screen with all applicant fields and uploaded media, and provides a **Certificate Photos** export workflow for the final Considered for Samman set. The workflow shows how many certificate photos are ready, flags missing photos, and downloads a ZIP containing numbered JPEG photos plus a CSV manifest for the certificate-printing team. The download URL is short-lived and does not create a second permanent copy in R2.


## Review queue and shortlisting

Each new or edited application must provide an overall percentage from 0 to 100. The backend stores the value and the administrator application queue orders candidates by overall percentage descending, with applications that predate this field kept as legacy records.

The admin review screen provides:
- total application count;
- needs-review count (submitted, under review and clarification-required);
- selected count (approved for donation or considered for Samman);
- rejected count;
- not-selected count for Samman applications;
- a Top 50 by overall percentage review view for high-volume rounds.

The percentage is a prioritisation signal, not an automatic approval. Administrators still inspect evidence, cast reviewer votes where applicable, and make the final review decision.

When an applicant edits an application or resubmits after rejection/clarification, the application returns to SUBMITTED, reviewer votes are cleared, approval/rejection metadata is reset, and it enters a fresh review cycle.
