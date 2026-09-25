This is a [Next.js](https://nextjs.org) project bootstrapped with [`create-next-app`](https://nextjs.org/docs/app/api-reference/cli/create-next-app).

## Getting Started

The runtime architecture is Browser → Next.js server → pg → PostgreSQL. Database access lives in the server-only `src/lib/db.ts`; browsers must never receive database credentials.

Use Node.js 24 and an existing PostgreSQL database. Run `npm ci` from this directory and set `DATABASE_URL` in the ignored `.env.local` file. Next.js loads this file; `psql` does not. For database commands, provide `DATABASE_URL` separately through your shell's secure environment without printing it.

For a new, empty local development database only, apply the baseline once:

```sh
psql "$DATABASE_URL" -X --set=ON_ERROR_STOP=1 --single-transaction --file=db/migrations/001_initial_schema.sql
```

Do not rerun the baseline on an existing schema. Database changes belong in new files under `db/migrations/`.

```sh
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) with your browser to see the result.

You can start editing the page by modifying `app/page.tsx`. The page auto-updates as you edit the file.

This project uses [`next/font`](https://nextjs.org/docs/app/building-your-application/optimizing/fonts) to automatically optimize and load [Geist](https://vercel.com/font), a new font family for Vercel.

## Learn More

To learn more about Next.js, take a look at the following resources:

- [Next.js Documentation](https://nextjs.org/docs) - learn about Next.js features and API.
- [Learn Next.js](https://nextjs.org/learn) - an interactive Next.js tutorial.

You can check out [the Next.js GitHub repository](https://github.com/vercel/next.js) - your feedback and contributions are welcome!

## Deploy on Vercel

The easiest way to deploy your Next.js app is to use the [Vercel Platform](https://vercel.com/new?utm_medium=default-template&filter=next.js&utm_source=create-next-app&utm_campaign=create-next-app-readme) from the creators of Next.js.

Check out our [Next.js deployment documentation](https://nextjs.org/docs/app/building-your-application/deploying) for more details.

## Validation

Run `npm run lint`, `npm run typecheck`, `npm run format:check`, and `npm run build`, or use `npm run check` for the combined application checks.

The root `.github/workflows/database-tests.yml` provisions PostgreSQL 17 with an isolated `remi_test` database, applies `db/migrations/001_initial_schema.sql` with `psql` and error-stop enabled, and checks all 17 expected public table names. This verifies schema setup, not end-user authorization. There is currently no replacement local authorization-test suite.

## Security requirements retained from the Supabase migration

Authenticated ownership/privacy authorization is intentionally deferred to Authentication + Accounts. Direct `pg` currently has no REMI end-user identity; the database connection identity is not an application user. The portable baseline does not implement the former user-aware RLS policies. Successful database connectivity and schema smoke checks do not establish multi-user privacy. Restore and test the requirements below when identity is introduced, before exposing private data or user-owned mutations.

| Area                  | Required access behaviour                                                                                                                                                                                                                                                                       |
| --------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Profiles              | Profile metadata is publicly readable even when the profile is private. Only the matching user may create, update, or delete their profile. Private profile visibility protects content, not the profile header.                                                                                |
| Recipes               | Owners may read all their recipes, including drafts, archived and private recipes. Other viewers may read a recipe only when it is published, public, and owned by a public profile. Only the owner may create, update, or delete it.                                                           |
| Recipe children       | Ingredients, steps, media metadata, nutrition, and recipe-tag relationships follow recipe visibility. Only the recipe owner may manage them; recipe tags support add/remove rather than update.                                                                                                 |
| Imports               | Import records, raw source material, and transcripts are accessible and mutable only by the recipe owner, even after publication.                                                                                                                                                               |
| Private user data     | User preferences, saves, dietary preferences, user allergens, and recipe notes are accessible only by the matching user. A recipe owner cannot read or change someone else's notes. Preferences and notes support CRUD; saves, dietary preferences, and user allergens support read/add/remove. |
| Collections           | Owners may see and manage all their collections. Others may read only public collections whose owner profile is public.                                                                                                                                                                         |
| Collection membership | Read access follows the collection. Only its owner may add, update, or remove membership, including ordering.                                                                                                                                                                                   |
| Controlled vocabulary | Tags and allergens are publicly readable; ordinary users cannot modify the vocabulary.                                                                                                                                                                                                          |
| Mutation isolation    | Deny cross-user inserts, updates, and deletes. Check both existing and resulting ownership on updates; moving a child or membership row must not bypass ownership checks. Unauthenticated viewers receive no private-data or mutation access.                                                   |

Historical policy limitations must remain visible during the replacement design: collection membership checked collection visibility, not the referenced recipe's visibility; saves and notes checked user ownership but did not require access to the referenced recipe. These are unresolved authorization decisions, not guarantees to copy silently. Media-row permissions did not establish protection for externally accessible media bytes.

The retired five pgTAP suites contained 64 assertions: table existence/RLS enabled (2), profile/recipe visibility and mutation isolation (10), private user data and vocabulary reads (17), recipe children/imports and mutation isolation (23), and collections/membership (12). They used seeded identities, role switching, and transaction rollback. Replacement tests must cover public visitors, owners, and other users, including private-profile content hiding and cross-user mutation denial. The former tests exercised selected reads/updates/deletes, not every insertion or ownership-transfer case; full replacement coverage must not be inferred from the old assertion count.

The eight retired migrations covered the initial 13-table schema, refinement to 17 tables, RLS, and five API-grant additions. Refinements replaced preference/allergy arrays with relationships, moved private notes out of recipes, moved ingredient confirmation to recipe level, made nutrition whole-recipe, and added profile visibility. The portable baseline preserves that final domain structure while replacing the dependency on external authentication user IDs with database-generated profile IDs. The old SQL remains available in repository history; service configuration and disposable generated runtime state are retired.
