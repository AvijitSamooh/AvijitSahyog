# Backend Read/Write Budget and Resilience

## Goals

AvijitSahyog should minimize Neon database work without weakening business correctness. Read-heavy reference content should remain available during the configured backend downtime window.

## Implemented strategy

### Analytics writes
- Flutter keeps Firebase Analytics as the detailed analytics sink.
- Backend mirroring is queued in memory and sent in batches of up to 25 events.
- The API accepts at most 50 events per request and persists the whole batch with one Prisma `createMany` operation.
- The client flushes on batch size or after a short timer.
- The queue is bounded so analytics cannot grow without limit in process memory.

This changes the common path from one HTTP request + one INSERT per event to one HTTP request + one INSERT operation per batch.

### Reference-data memory cache

The backend caches:
- causes and cause descriptions
- organisations and organisation descriptions
- application rules and rule descriptions

Normal cache lifetime is 10 minutes. A stale copy can be served for up to 24 hours when the database read fails. Admin writes invalidate the corresponding cache immediately.

This cache is deliberately limited to small, read-heavy reference datasets. User-specific, transactional, donation, application-submission, voting and media mutation paths are not cached.

### Client-side downtime cache

The Flutter causes repository persists cause lists and detail responses in SharedPreferences:
- fresh cache: 1 hour
- stale fallback: up to 30 days

When the backend is unavailable or inside the configured service downtime window, the app can still render previously loaded cause names/descriptions and cause details.

### Admin analytics

Expensive dashboard analytics are cached in process:
- standard analytics: 60 seconds fresh / 10 minutes stale
- advanced analytics: 5 minutes fresh / 1 hour stale

This prevents repeated admin refreshes from repeatedly executing the expensive AnalyticsEvent aggregation queries.

## Safety boundaries

- Cache invalidation happens after successful admin writes.
- Analytics batch size is bounded.
- Existing single-event analytics endpoint remains available for compatibility.
- Firebase Analytics remains unchanged.
- Transactional writes continue to hit the database and are not hidden behind cache.
- Stale data is limited to reference/observability views; it is not used for authorization or business-rule enforcement.

## Next measurement targets

After deployment, query volume should be checked for:
1. AnalyticsEvent INSERT rate.
2. Cause/organisation/rule SELECT frequency.
3. Admin dashboard AnalyticsEvent query frequency.
4. Help-application list payload size and pagination.

If Neon pressure remains high, the next architectural step is pre-aggregated analytics rather than adding more indexes to AnalyticsEvent.
