# Admin User Management

## Scalability

The Manage administrators screen is intentionally server-paginated. It must not load the complete user table as administrator count grows.

### Administrator list

- Default role filter: `ADMIN`
- Default page size: 3
- Maximum API page size: 20
- With an empty search, the screen lists current administrators only (`role=ADMIN`).
- With a non-empty search, the backend searches across regular users and administrators (`role=ALL`) by display name and email.
- Search results show each matching user's name, email, current role, and available profile photo so multiple similarly named users can be distinguished before a role change.
- Search resets the Flutter page to 1 after a short debounce.
- The UI renders only the current server page and exposes previous/next navigation when more pages exist.

### Make-admin flow

The user-selection flow uses the same backend endpoint with `role=USER`, server-side search, and pagination. This prevents downloading the complete regular-user population merely to find a candidate.

### API contract

`GET /admin/users`

Query parameters:

- `search` — optional name/email search text
- `role` — `ADMIN` (default), `USER`, or `ALL` for cross-role search
- `page` — positive integer, default `1`
- `pageSize` — positive integer, default `3`, maximum `20`

Response shape:

```json
{
  "items": [],
  "page": 1,
  "pageSize": 3,
  "total": 0
}
```

Invalid pagination values and unsupported roles are rejected rather than silently coerced.

## Audit history

Role changes continue to be written transactionally with the role update. Pagination affects presentation only and does not change the audit contract.

## Testing expectations

Regression coverage should verify server pagination, role filtering, cross-role search, result details, role-selection actions, page navigation, empty states, and invalid query values.
