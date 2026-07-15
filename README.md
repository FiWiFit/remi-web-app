# REMI Creator

REMI Creator is a food-first creator extension tool that gives food creators a structured, searchable home for the recipes and educational content they already share on social platforms.

Creators receive a unique REMI profile link that they can place in their Instagram, TikTok, newsletter, or other social-media bios. Their followers can use that page to find, read, save, and return to properly formatted recipes without relying on compressed captions or unstructured saved-post folders.

> Project status: planning and initial implementation.

## Product goal

Build a standalone web product that improves the usefulness and longevity of food content shared on existing platforms.

REMI Creator does not depend on the future REMI consumer app to provide value. The web product is intended to remain useful in its own right, while creating structured recipe and user-interaction data that may later be reused by REMI's food-only mobile app.

## Target users

### Primary user: food creator

Examples include:

- chefs;
- recipe developers;
- food writers;
- bakers;
- home cooks;
- food educators;
- creators whose recipes currently live in social-media captions, videos, newsletters, or blogs.

### Secondary user: follower or reader

A follower uses a creator's REMI link to:

- search the creator's recipes;
- read a structured recipe;
- save recipes;
- follow the creator on REMI;
- return to previously saved content.

### Internal user: REMI administrator

During the initial launch period, an administrator may support creator onboarding, correct imported content, manage incomplete recipes, and resolve publication issues.

## Confirmed launch direction

### Creator profiles

- unique public creator URL;
- creator profile information;
- searchable recipe grid;
- follower count;
- structured recipe pages.

### Structured recipes

A recipe may contain:

- title;
- description;
- cover image or video;
- ingredient names, quantities, and units;
- numbered method steps;
- preparation and cooking times;
- serving quantity;
- equipment;
- metric and imperial presentation;
- optional media for individual steps;
- topics, dietary labels, cuisine, and other metadata.

### Accounts and interaction

- account creation and authentication;
- persistent user sessions;
- save and unsave recipes;
- follow and unfollow creators;
- personal saved-recipes page.

### Creator upload and onboarding

The intended primary workflow is AI-assisted but creator-controlled:

1. The creator pastes a supported social-post URL, records a voice description, or uses the manual editor.
2. REMI extracts available caption text and, where required, transcribes spoken audio.
3. An AI service proposes a structured recipe.
4. The creator reviews and edits every field.
5. Nutrition data may be calculated from confirmed ingredients and quantities.
6. The creator publishes the recipe.

Manual entry and administrator-assisted onboarding remain available as fallback options.

### Analytics

The product should collect enough behavioural data to evaluate:

- profile and recipe visits;
- referral source;
- account conversion;
- saves;
- follows;
- repeat visits;
- use and completion of each upload method;
- time taken from import to publication;
- extent of creator edits after AI extraction.

## Scope boundaries

### Launch scope

- creator profile links;
- structured recipe pages;
- creator-profile search;
- account authentication;
- saves;
- follows;
- manual recipe editor;
- AI-assisted URL import;
- caption-to-recipe structuring;
- audio transcription when recipe information is spoken;
- voice-to-text recipe creation;
- creator review before publication;
- nutrition calculation after ingredient confirmation;
- admin or concierge fallback;
- product analytics;
- responsive web experience;
- end-to-end testing of critical flows.

### Post-launch candidates

- automatic topic and cuisine tagging;
- dietary inference;
- equipment suggestions;
- improved multimodal video understanding;
- creator analytics reports;
- public and private collections;
- paid creator plans;
- additional creator tools.

### Out of scope for the current web launch

- the REMI consumer social feed;
- topic questions and answers;
- reputation badges;
- direct messaging;
- group messaging;
- creator subscriptions or paid recipes;
- native iOS or Android applications.

## Relationship with REMI: The App

REMI Creator and REMI: The App are separate products in the same food ecosystem.

- **REMI Creator** is a standalone web tool for publishing and extending food content.
- **REMI: The App** is the future food-only consumer and community platform for discovery, collections, questions, expertise, and creator monetisation.

The web product should preserve stable user, creator, recipe, media, topic, save, and follow identities so that the same underlying data can be made available to the mobile app later. The exact technical implementation will be documented through design documents and architecture decision records during development.

## Planned technology

These choices remain subject to the project's documented engineering review process.

- Next.js;
- React;
- TypeScript;
- PostgreSQL through Supabase;
- Supabase Authentication;
- Supabase Storage;
- PostHog analytics;
- Cypress end-to-end testing;
- Vercel deployment.

## Repository structure

The initial repository is intended to contain the web application, database migrations, tests, and project documentation together.

```text
remi-web-app/
├── README.md
├── .gitignore
├── docs/
│   ├── adr/
│   ├── design/
│   ├── reading-reviews/
│   ├── sprint-logs/
│   └── product/
├── src/                  # Created/configured with the Next.js application
├── supabase/
│   └── migrations/
├── cypress/
└── public/
```

The exact application directories may change when the Next.js project is initialised.

## Documentation

The repository documentation will include:

- product requirements;
- design documents for individual system areas;
- architecture decision records;
- reading reviews that apply technical literature to REMI;
- sprint and retrospective records.

## Local development

To be completed after the Next.js and Supabase projects are initialised.

### Prerequisites

TBC.

### Installation

TBC.

### Environment variables

TBC. Secret values must not be committed to Git.

### Run locally

TBC.

### Run tests

TBC.

## Deployment

TBC after the first deployment workflow is implemented.

## Current milestones

1. Establish the Git repository and documentation structure.
2. Complete initial user journeys and data-model research.
3. Initialise the Next.js application and Supabase project.
4. Deploy an application skeleton.
5. Implement authentication.
6. Implement creator profiles and structured recipes.
7. Implement creator-controlled upload workflows.
8. Implement saves, follows, and analytics.
9. Add Cypress coverage and production hardening.
10. Launch an initial creator beta.

## Open product questions

- Which social platforms can be supported legally and reliably for URL import?
- Which import methods must be available at public launch versus beta?
- What nutrition-data provider best fits the required coverage, accuracy, licensing, and cost?
- Should collections be included in the initial paid product or introduced after launch?
- What limits should apply to free creator accounts?
- Which creator analytics should be visible at launch?
- What moderation and correction workflow is required for inaccurate AI extraction?
- Which data must be retained for the future REMI app, and which operational data should remain specific to REMI Creator?

## Maintainer

REMI is currently designed and developed by its founder as an end-to-end product engineering project.

## Licence

TBC. No licence is granted unless a licence file is added to this repository.
