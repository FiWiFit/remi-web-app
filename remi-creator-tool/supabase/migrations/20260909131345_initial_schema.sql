-- ============================================================
-- REMI Creator
-- Initial PostgreSQL / Supabase schema
-- ============================================================


-- ============================================================
-- PROFILES
-- One application profile per Supabase Auth user.
-- A user is not permanently classified as a "creator".
-- Publishing recipes is what makes a profile creator-facing.
-- ============================================================

create table public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,

    username text not null unique,
    display_name text not null,
    bio text,
    avatar_url text,

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);


-- ============================================================
-- USER PREFERENCES
-- Private preferences used later for personalised recipe
-- presentation, filtering and cooking experience.
-- ============================================================

create table public.user_preferences (
    user_id uuid primary key references public.profiles(id) on delete cascade,

    preferred_unit_system text not null default 'metric'
        check (preferred_unit_system in ('metric', 'imperial')),

    show_nutrition boolean not null default true,

    dietary_preferences text[] not null default '{}',
    allergies text[] not null default '{}',

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);


-- ============================================================
-- RECIPES
-- Canonical recipe record.
-- Import/AI processing is intentionally stored separately.
-- ============================================================

create table public.recipes (
    id uuid primary key default gen_random_uuid(),

    owner_id uuid not null
        references public.profiles(id)
        on delete cascade,

    title text not null,
    description text,

    status text not null default 'draft'
        check (status in ('draft', 'published', 'archived')),

    visibility text not null default 'private'
        check (visibility in ('private', 'public')),

    servings numeric check (servings > 0),

    prep_time_minutes integer
        check (prep_time_minutes is null or prep_time_minutes >= 0),

    cook_time_minutes integer
        check (cook_time_minutes is null or cook_time_minutes >= 0),

    notes text,

    published_at timestamptz,

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint published_recipe_requires_published_at
        check (
            status <> 'published'
            or published_at is not null
        )
);


-- ============================================================
-- RECIPE INGREDIENTS
-- Ingredients stay structured so they can later support:
-- nutrition, scaling, dietary analysis and shopping lists.
-- ============================================================

create table public.recipe_ingredients (
    id uuid primary key default gen_random_uuid(),

    recipe_id uuid not null
        references public.recipes(id)
        on delete cascade,

    position integer not null
        check (position >= 0),

    name text not null,

    quantity numeric
        check (quantity is null or quantity >= 0),

    unit text,

    preparation_note text,

    confirmed boolean not null default false,

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    unique (recipe_id, position)
);


-- ============================================================
-- RECIPE STEPS
-- Ordered structured cooking instructions.
-- ============================================================

create table public.recipe_steps (
    id uuid primary key default gen_random_uuid(),

    recipe_id uuid not null
        references public.recipes(id)
        on delete cascade,

    position integer not null
        check (position >= 0),

    instruction text not null,

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    unique (recipe_id, position)
);


-- ============================================================
-- RECIPE MEDIA
-- Stores references/metadata.
-- Actual image/video bytes should live in Supabase Storage.
-- ============================================================

create table public.recipe_media (
    id uuid primary key default gen_random_uuid(),

    recipe_id uuid not null
        references public.recipes(id)
        on delete cascade,

    media_type text not null
        check (media_type in ('image', 'video')),

    storage_path text,
    source_url text,

    position integer not null default 0
        check (position >= 0),

    alt_text text,

    created_at timestamptz not null default now(),

    constraint recipe_media_has_location
        check (
            storage_path is not null
            or source_url is not null
        )
);


-- ============================================================
-- RECIPE IMPORTS
-- Provenance and AI/import processing information.
-- This keeps ingestion mechanics separate from canonical recipe
-- data.
-- ============================================================

create table public.recipe_imports (
    id uuid primary key default gen_random_uuid(),

    recipe_id uuid not null
        references public.recipes(id)
        on delete cascade,

    import_method text not null
        check (
            import_method in (
                'manual',
                'url',
                'video',
                'audio',
                'image'
            )
        ),

    source_platform text,
    source_url text,

    raw_source_text text,
    transcript text,

    processing_status text not null default 'pending'
        check (
            processing_status in (
                'pending',
                'processing',
                'review_required',
                'completed',
                'failed'
            )
        ),

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);


-- ============================================================
-- RECIPE NUTRITION
-- Provider-neutral calculated nutrition result.
-- Nutrition should be calculated only from confirmed ingredient
-- information.
-- ============================================================

create table public.recipe_nutrition (
    id uuid primary key default gen_random_uuid(),

    recipe_id uuid not null unique
        references public.recipes(id)
        on delete cascade,

    provider text,

    status text not null default 'pending'
        check (
            status in (
                'pending',
                'calculated',
                'failed'
            )
        ),

    calories numeric
        check (calories is null or calories >= 0),

    protein_g numeric
        check (protein_g is null or protein_g >= 0),

    carbohydrate_g numeric
        check (carbohydrate_g is null or carbohydrate_g >= 0),

    fat_g numeric
        check (fat_g is null or fat_g >= 0),

    fiber_g numeric
        check (fiber_g is null or fiber_g >= 0),

    sugar_g numeric
        check (sugar_g is null or sugar_g >= 0),

    sodium_mg numeric
        check (sodium_mg is null or sodium_mg >= 0),

    serving_count numeric
        check (serving_count is null or serving_count > 0),

    calculated_at timestamptz,

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);


-- ============================================================
-- TAGS
-- Controlled searchable/filterable recipe metadata.
-- ============================================================

create table public.tags (
    id uuid primary key default gen_random_uuid(),

    name text not null,
    tag_type text not null
        check (
            tag_type in (
                'dietary',
                'cuisine',
                'meal_type',
                'category'
            )
        ),

    created_at timestamptz not null default now(),

    unique (name, tag_type)
);


-- ============================================================
-- RECIPE TAGS
-- Many-to-many relationship between recipes and tags.
-- ============================================================

create table public.recipe_tags (
    recipe_id uuid not null
        references public.recipes(id)
        on delete cascade,

    tag_id uuid not null
        references public.tags(id)
        on delete cascade,

    created_at timestamptz not null default now(),

    primary key (recipe_id, tag_id)
);


-- ============================================================
-- SAVES
-- One persistent save relationship can power:
--
-- 1. "My Saves"
-- 2. "Recipes I've saved from this creator"
--
-- creator_id does not belong here because it is derivable from
-- recipes.owner_id.
-- ============================================================

create table public.saves (
    user_id uuid not null
        references public.profiles(id)
        on delete cascade,

    recipe_id uuid not null
        references public.recipes(id)
        on delete cascade,

    created_at timestamptz not null default now(),

    primary key (user_id, recipe_id)
);


-- ============================================================
-- COLLECTIONS
-- Same concept can represent a private personal collection or
-- a publicly visible creator collection.
-- ============================================================

create table public.collections (
    id uuid primary key default gen_random_uuid(),

    owner_id uuid not null
        references public.profiles(id)
        on delete cascade,

    name text not null,
    description text,

    visibility text not null default 'private'
        check (visibility in ('private', 'public')),

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);


-- ============================================================
-- COLLECTION RECIPES
-- Many-to-many relationship between collections and recipes.
-- ============================================================

create table public.collection_recipes (
    collection_id uuid not null
        references public.collections(id)
        on delete cascade,

    recipe_id uuid not null
        references public.recipes(id)
        on delete cascade,

    position integer
        check (position is null or position >= 0),

    added_at timestamptz not null default now(),

    primary key (collection_id, recipe_id)
);


-- ============================================================
-- INDEXES
-- Foreign-key indexes and common REMI query paths.
-- ============================================================

create index recipes_owner_id_idx
    on public.recipes(owner_id);

create index recipes_public_catalogue_idx
    on public.recipes(owner_id, status, visibility);

create index recipe_ingredients_recipe_id_idx
    on public.recipe_ingredients(recipe_id);

create index recipe_steps_recipe_id_idx
    on public.recipe_steps(recipe_id);

create index recipe_media_recipe_id_idx
    on public.recipe_media(recipe_id);

create index recipe_imports_recipe_id_idx
    on public.recipe_imports(recipe_id);

create index recipe_tags_tag_id_idx
    on public.recipe_tags(tag_id);

create index saves_recipe_id_idx
    on public.saves(recipe_id);

create index collections_owner_id_idx
    on public.collections(owner_id);

create index collection_recipes_recipe_id_idx
    on public.collection_recipes(recipe_id);


-- ============================================================
-- UPDATED_AT TRIGGER
-- Reusable PostgreSQL trigger so updated_at is maintained by
-- the database rather than relying on every client to remember.
-- ============================================================

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;


create trigger set_profiles_updated_at
before update on public.profiles
for each row
execute function public.set_updated_at();

create trigger set_user_preferences_updated_at
before update on public.user_preferences
for each row
execute function public.set_updated_at();

create trigger set_recipes_updated_at
before update on public.recipes
for each row
execute function public.set_updated_at();

create trigger set_recipe_ingredients_updated_at
before update on public.recipe_ingredients
for each row
execute function public.set_updated_at();

create trigger set_recipe_steps_updated_at
before update on public.recipe_steps
for each row
execute function public.set_updated_at();

create trigger set_recipe_imports_updated_at
before update on public.recipe_imports
for each row
execute function public.set_updated_at();

create trigger set_recipe_nutrition_updated_at
before update on public.recipe_nutrition
for each row
execute function public.set_updated_at();

create trigger set_collections_updated_at
before update on public.collections
for each row
execute function public.set_updated_at();