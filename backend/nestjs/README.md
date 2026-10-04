# Avijit Sahyog Backend

NestJS REST API for Avijit Sahyog.

## Persistence

Firebase Authentication provides identity, Cloud Firestore is the authoritative application datastore, and Cloudflare R2 stores media/object content. PostgreSQL/Prisma is retired from the runtime.

## Key endpoints
- `GET /health`
- `GET /health/ready`
- `GET /platform-downtime`
- `PATCH /platform-downtime` (SUPER_ADMIN)
- `GET /languages`
- `GET /causes`
- `GET /organisations/:id`
- `GET /beneficiaries`

## Development
```bash
npm ci
npm run start:dev
```

## Tests
```bash
npm test
npm run test:cov
```