# Help & Recognition Applications

## Purpose

Avijit Sahyog supports authenticated applications for two assistance programs and one recognition program.

### Assistance

- **Education Assistance** — a user can request help for education-related need.
- **Medical Help** — a user can request medical assistance.

Applicants provide a requested amount and supporting images. Administrators review the application, record individual votes, and can approve an amount for donation, request clarification, or reject with a reason.

### Pratibha Samman

A student can apply with marksheets and achievement evidence. Administrators review the evidence, record a 1–5 score and optional comment, and can mark the profile as **Considered for Samman** or **Not Selected**.

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

Authenticated users can upload JPEG, PNG and WebP evidence through the existing R2 media foundation. Uploaded media is linked to the application through explicit foreign-key relations.

The upload and submission steps are intentionally separate so storage failures do not create a partially persisted application record. An application cannot be submitted without at least one evidence image.

## API

Authenticated user endpoints:

- POST /media/upload
- POST /applications
- GET /applications/mine
- GET /applications/mine/:id
- PATCH /applications/mine/:id/resubmit

Administrator endpoints:

- GET /admin/applications
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
