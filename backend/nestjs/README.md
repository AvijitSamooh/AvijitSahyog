# Avijit Sahyog Backend

NestJS REST API for Avijit Sahyog.

## Current domains

- Languages
- Causes and translations
- Organisations and translations
- Beneficiaries / Impact Explorer
- Donation foundations

## Key endpoints

- `GET /health`
- `GET /languages`
- `GET /causes`
- `GET /causes/:id`
- `GET /organisations/:id`
- `GET /beneficiaries`
- `GET /beneficiaries/:id`

The beneficiary collection supports discovery filters and sorting.

## Development

```bash
npm ci
npm run prisma:generate
npm run start:dev
```

## Database

Production startup applies committed Prisma migrations and runs the idempotent seed:

```bash
npm run prisma:deploy
npm run prisma:seed
```

## Tests

```bash
npm test
npm run test:cov
```

CI also validates the Prisma schema and generates the Prisma client before building the application.
