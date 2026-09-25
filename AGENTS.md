# Repository guidance

## Architecture

- The application lives in `remi-creator-tool/`. Run application commands there.
- Use Next.js App Router and TypeScript with Browser → Next.js server → pg → PostgreSQL.
- Keep `src/app` focused on routing and route composition. Place shared and application code in the feature/components/hooks/lib/types structure under `src/`, creating missing directories only when needed.
- Prefer small, reviewable changes and the existing architecture over new abstractions.
- Propose significant architectural or database changes and obtain approval before implementation.

## Database and security

- SQL migrations in `remi-creator-tool/db/migrations/` are the database source of truth. Make schema, grant, and RLS changes through new migrations; do not rewrite applied migrations.
- Database changes require relevant PostgreSQL tests; CI currently applies the baseline and checks the 17 expected tables.
- Preserve the ownership/privacy requirements in `remi-creator-tool/README.md`. Their implementation and tests are deferred to Authentication + Accounts because direct `pg` currently has no REMI end-user identity; do not claim user-aware authorization already exists.
- Never expose `DATABASE_URL` or database credentials in client code, browser bundles, or public environment variables.

## Product boundaries

- REMI Creator's scope is: create → organise → cook → plan.
- Social discovery, feeds, and follow behaviour belong to the future REMI consumer application. Do not add them to Creator.
- There is intentionally no separate creator role or entity. Creator behaviour emerges through recipe ownership and publication.

## AI behaviour

- AI extraction produces a draft. Creator review and approval are required before extracted content becomes canonical published recipe content.
- Use AI for ambiguous interpretation. Keep scaling, unit conversion, saving, filtering, and permissions deterministic.
- Never present AI-generated allergen or dietary output as a guarantee of safety.

## Validation

- After implementation, run relevant lint, typecheck, tests, and build checks from `remi-creator-tool/`.
- Application checks: `npm run lint`, `npm run typecheck`, and `npm run build`; `npm run check` also checks formatting.
- Database validation: follow the PostgreSQL baseline and schema smoke check in `.github/workflows/database-tests.yml`; use only an isolated test database.
- Report which checks ran, their results, and any checks that could not run.

## Git workflow

- Do not stage, commit, push, merge, or delete branches unless explicitly requested.
- After implementation, show the relevant diff and validation results for human review.
- The developer retains control of repository history and pull-request merges.
