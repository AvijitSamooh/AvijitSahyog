# Configurable application rules

Administrators can configure acceptance rules independently for Education Assistance, Medical Help and Pratibha Samman. Each active rule has English, Hindi, Marathi and Gujarati text and a display order.

Users see the active rules in their selected language before the application form and must acknowledge every current rule before submission. The backend validates the complete set of active rule IDs, so the acknowledgement cannot be bypassed by changing the client.

Accepted rules are stored with a text snapshot on the application. If an administrator edits a rule later, previously submitted applications retain the wording that the applicant acknowledged.

Admin API:
- GET /admin/application-rules/:type
- POST /admin/application-rules
- PATCH /admin/application-rules/:id
- DELETE /admin/application-rules/:id (soft-deactivates the rule)

Public API:
- GET /application-rules/:type?language=en
