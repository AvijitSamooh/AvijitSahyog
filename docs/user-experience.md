# Avijit Sahyog — User Experience Specification

## 1. Experience principles

1. Discover before asking — public information remains accessible without sign-in.
2. One clear next action — primary screens expose the next useful action.
3. Never hide state — loading, empty, scheduled, open, closed and error states are explicit.
4. Protect user work — recoverable failures keep the form available for retry.
5. Localized by default — English, Hindi, Marathi and Gujarati are first-class experiences.
6. Trust through transparency — causes, organisations, beneficiaries, application status and review outcomes are understandable.
7. Keep admin and donor experiences separate.

## 2. Primary journeys

### Public discovery

Launch → Home → Cause → Organisation / Impact story → Back to shell

Expected outcomes:
- no login required;
- consistent Home/Causes/Impact navigation;
- content comes from the backend;
- missing/empty content is explicit.

### Help / recognition application

Sign in → Applications → Choose programme → Availability → Rules → Applicant details → Evidence → Submit → Confirmation → History

Availability:
- Scheduled: show local start date/time and prevent entry.
- Open: allow entry.
- Closed: explain that submissions are no longer accepted.

Submission safeguards:
- every active rule must be acknowledged;
- assistance requires a positive requested amount;
- at least one evidence image is required;
- submit is disabled while work is in progress;
- success shows confirmation;
- failure leaves the form available for retry.

### Application history and recovery

History → Status → Delete when allowed OR Resubmit after rejection/clarification

- non-final applications can be deleted after confirmation;
- final applications remain retained;
- rejected/clarification-required applications expose a recovery path;
- resubmission carries updated evidence and clarification.

### Admin review

Admin Portal → Applications → Filter → Inspect evidence → Vote → Review decision

Assistance:
- approve with an amount no higher than requested;
- request clarification;
- reject with a reason.

Pratibha Samman:
- each administrator has one 1–5 vote;
- vote can be updated;
- decisions are Considered for Samman or Not Selected.

## 3. Global UI states

Every backend-backed screen defines:
- loading;
- empty;
- error + retry;
- mutation success confirmation;
- permission/authorization state where relevant.

## 4. Service-window experience

The nightly service window is an unavailable interval, defaulting to 9:00 PM–8:00 AM local device time.

During the interval:
- static content remains visible;
- a localized banner explains the interval;
- taps show the service-unavailable message;
- API traffic is blocked before HTTP;
- the user is never given a false success state.

## 5. Localization and accessibility

All user-visible strings exist in English, Hindi, Marathi and Gujarati.

Forms:
- expose clear labels and validation;
- preserve entered values on recoverable errors;
- provide semantic labels/tooltips for important actions;
- remain usable with large text and narrow screens;
- do not rely on colour alone for status.

## 6. Admin experience

Admin actions:
- expose the object being changed;
- distinguish destructive from reversible actions;
- show success/failure feedback;
- preserve audit-relevant history;
- prevent unauthorized users from reaching protected operations.

## 7. UX acceptance checklist

Before release:
- [ ] Primary journey has an automated test.
- [ ] Loading/empty/error states are tested.
- [ ] Mutation success/failure is tested.
- [ ] Recoverable failures preserve user work.
- [ ] Localization exists in all four languages.
- [ ] Navigation returns to the main shell consistently.
- [ ] Accessibility/basic responsive behaviour is reviewed.
- [ ] Documentation matches shipped behaviour.
