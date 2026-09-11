-- ============================================================
-- REMI Creator
-- Refine initial schema following domain model review
-- ============================================================


-- ============================================================
-- 1. USER PREFERENCES
-- Dietary preferences and allergies are no longer stored as
-- text arrays. They will be represented relationally below.
-- ============================================================

alter table public.user_preferences
    drop column dietary_preferences,
    drop column allergies;


-- ============================================================
-- 2. RECIPES
-- Remove the recipe-level notes field.
--
-- Notes are personal to a user + recipe relationship rather
-- than part of the canonical recipe.
--
-- Ingredient confirmation applies to the reviewed ingredient
-- set as a whole, so record when that set was confirmed.
-- ============================================================

alter table public.recipes
    drop column notes,
    add column ingredients_confirmed_at timestamptz;


-- ============================================================
-- 3. RECIPE INGREDIENTS
-- Confirmation now happens at recipe level rather than
-- independently on every ingredient row.
-- ============================================================

alter table public.recipe_ingredients
    drop column confirmed;


-- ============================================================
-- 4. RECIPE NUTRITION
-- Nutrition is stored for the whole canonical recipe.
-- Per-serving values can be calculated using recipes.servings.
-- ============================================================

alter table public.recipe_nutrition
    drop column serving_count;


-- ============================================================
-- 5. USER DIETARY PREFERENCES
-- Connects users to controlled dietary tags.
--
-- Example:
-- Fiona -> Vegetarian
-- Fiona -> Gluten-free
-- ============================================================

create table public.user_dietary_preferences (
    user_id uuid not null
        references public.profiles(id)
        on delete cascade,

    tag_id uuid not null
        references public.tags(id)
        on delete cascade,

    created_at timestamptz not null default now(),

    primary key (user_id, tag_id)
);


-- ============================================================
-- 6. ALLERGENS
-- Controlled allergen vocabulary.
--
-- Kept separate from general recipe tags because allergens
-- represent a different domain/safety concept.
-- ============================================================

create table public.allergens (
    id uuid primary key default gen_random_uuid(),

    name text not null unique,

    created_at timestamptz not null default now()
);


-- ============================================================
-- 7. USER ALLERGENS
-- Private relationship between a user and their allergens.
--
-- Example:
-- Fiona -> Peanut
-- Fiona -> Milk
-- ============================================================

create table public.user_allergens (
    user_id uuid not null
        references public.profiles(id)
        on delete cascade,

    allergen_id uuid not null
        references public.allergens(id)
        on delete cascade,

    created_at timestamptz not null default now(),

    primary key (user_id, allergen_id)
);


-- ============================================================
-- 8. PRIVATE USER RECIPE NOTES
--
-- Every authenticated user can have their own private note
-- against a recipe, including the recipe's owner.
--
-- These notes are NOT part of the canonical/public recipe.
-- ============================================================

create table public.user_recipe_notes (
    user_id uuid not null
        references public.profiles(id)
        on delete cascade,

    recipe_id uuid not null
        references public.recipes(id)
        on delete cascade,

    note text not null,

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    primary key (user_id, recipe_id)
);


-- Maintain updated_at automatically for private recipe notes.

create trigger set_user_recipe_notes_updated_at
before update on public.user_recipe_notes
for each row
execute function public.set_updated_at();


-- ============================================================
-- 9. INDEXES
-- Additional indexes for reverse relationship lookups.
-- ============================================================

create index user_dietary_preferences_tag_id_idx
    on public.user_dietary_preferences(tag_id);

create index user_allergens_allergen_id_idx
    on public.user_allergens(allergen_id);

create index user_recipe_notes_recipe_id_idx
    on public.user_recipe_notes(recipe_id);


    -- ============================================================
-- PROFILE VISIBILITY
--
-- Profile metadata remains publicly readable.
-- This setting controls whether other users can access the
-- profile owner's published content/grid.
-- ============================================================

alter table public.profiles
    add column profile_visibility text not null default 'public'
        check (profile_visibility in ('public', 'private'));