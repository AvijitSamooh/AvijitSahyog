# Avijit Sahyog — Causes & Organisations Data Model

## Scope

Iteration 2.1 defines the content/discovery domain used to show donation causes and the affiliated organisations under each cause.

Financial models such as Donation, Payment, Allocation, Receipt and Mandate are intentionally outside the current discovery scope.\n\n## Donation allocation boundary\n\nThe donor allocates a donation across **Causes**, not individual Organisations. The intended financial relationship is:\n\n```text\nDonation\n  └── DonationAllocation\n        └── Cause\n              └── affiliated Organisations (discovery/transparency)\n```\n\nOrganisations may later participate in operational routing or settlement, but organisation selection is not part of donor intent and must not be required by the donation allocation UI or API.

## Entities

### Language

Stores supported backend content languages.

- `code` — stable language code such as `en`, `hi`, `mr`, `gu`
- `name` — English/display name
- `nativeName` — language's native name
- `isDefault` — identifies the fallback language
- `isActive` — controls availability

### Cause

Represents a donation bucket/cause, for example Jeev Daya or Education.

- `slug` — stable API-friendly identifier
- `isActive` — whether the cause is currently available
- `displayOrder` — ordering in the UI

Cause names and descriptions are stored separately in `CauseTranslation`.

### Organisation

Represents an affiliated organisation that can receive allocations under one or more causes.

The model stores non-translatable operational/contact data such as:

- logo
- website
- phone/email
- address
- city/state/country
- latitude/longitude
- active state
- display order

Organisation names and descriptions are stored in `OrganisationTranslation`.

### Beneficiary

Represents a person or initiative whose support can be transparently explored by donors.

- `name` — beneficiary or initiative display name
- `photoUrl` — optional image
- `story` — optional impact story
- `supportedYear` — year of support
- `contributionAmount` — contribution amount associated with the record
- `causeId` — required cause relationship
- `organisationId` — optional affiliated organisation relationship
- `isActive` — controls public visibility
- `displayOrder` — presentation ordering

Beneficiaries support the Impact Explorer and are not part of donation allocation logic.

### OrganisationCause

Explicit many-to-many relationship between organisations and causes.

An explicit relation is used instead of an implicit Prisma many-to-many relation because the relationship itself needs state and presentation metadata:

- `isActive`
- `displayOrder`

This also leaves room for future relationship-specific fields without redesigning the relation.

## Translation strategy

```text
Cause
  └── CauseTranslation ── Language

Organisation
  └── OrganisationTranslation ── Language
```

Each cause can have at most one translation per language, and each organisation can have at most one translation per language.

English remains the mandatory fallback language as defined by `docs/vision.md`.

## Important design decisions

1. Stable IDs are UUIDs.
2. Slugs are unique and intended for API/UI routing.
3. Content can be activated/deactivated without deleting historical references.
4. Translation records are separate from the core entity so adding a language does not require a schema redesign.
5. Organisation-to-cause is an explicit relation because the relationship has its own lifecycle and ordering.
6. Donation/payment state is deliberately outside this model.

## Current API additions

The impact domain exposes:

- `GET /beneficiaries`
- `GET /beneficiaries/:id`

The collection supports filtering/searching and sorting for discovery.

## Next iteration

Iteration 2.2 will expose this model through NestJS services/controllers and REST endpoints:

- `GET /causes`
- `GET /causes/:id`
- `GET /causes/:id/organisations`
- `GET /organisations`
- `GET /organisations/:id`
