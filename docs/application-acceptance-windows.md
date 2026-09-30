# Application Acceptance Windows

## Purpose

Help and recognition applications are accepted only when an administrator has explicitly opened the relevant application window. This keeps the application lifecycle independent from the nightly backend service window.

The existing application types are:

- Education Assistance
- Medical Help
- Pratibha Samman

## User behaviour

The public application page reads the current window state from the API.

- **Scheduled** — users see the date and time when applications will start.
- **Open** — users can enter the application form and submit.
- **Closed** — users see that applications are no longer being accepted.
- The form itself is also guarded so a stale screen cannot submit after the server-side window has closed.

The backend enforces the same rule for both new submissions and resubmissions. Client-side state is therefore only a user-experience aid; it is not the security boundary.

## Admin behaviour

Administrators can manage each application type from **Admin Portal → Help & Samman Applications**:

1. Choose a start date and time to open or reschedule the window.
2. Users see the scheduled start immediately.
3. Close the window when the event/application cycle ends.
4. After closing, the public experience reports that applications are no longer being accepted.

Starting a window after a previous close clears the old close timestamp and creates a new acceptance cycle. This supports future annual cycles without deleting historical applications.

## Time handling

Window timestamps are persisted as instants in PostgreSQL. Flutter converts administrator-selected local date/time values to UTC before sending them to the API and converts stored timestamps back to local device time for display. This keeps the stored event boundary unambiguous while giving users and administrators locally meaningful times.

## Relationship to the nightly backend service window

The nightly backend service window (9:00 PM–8:00 AM by default) is separate. During that period the Flutter client intentionally blocks backend traffic. Application acceptance windows are business-level controls and remain stored in PostgreSQL.

Both layers are enforced:

- nightly service window prevents client traffic;
- application acceptance window prevents application submission outside the configured event period.

