-- ============================================================
-- REMI Creator
-- Row Level Security policies
-- ============================================================


-- ============================================================
-- ENABLE RLS
-- ============================================================

alter table public.profiles enable row level security;
alter table public.user_preferences enable row level security;
alter table public.recipes enable row level security;
alter table public.recipe_ingredients enable row level security;
alter table public.recipe_steps enable row level security;
alter table public.recipe_media enable row level security;
alter table public.recipe_imports enable row level security;
alter table public.recipe_nutrition enable row level security;
alter table public.tags enable row level security;
alter table public.recipe_tags enable row level security;
alter table public.saves enable row level security;
alter table public.collections enable row level security;
alter table public.collection_recipes enable row level security;
alter table public.user_dietary_preferences enable row level security;
alter table public.allergens enable row level security;
alter table public.user_allergens enable row level security;
alter table public.user_recipe_notes enable row level security;


-- ============================================================
-- PROFILES
--
-- Profile header information is public even when the profile's
-- content/grid is private.
--
-- Users may only create/update/delete their own profile.
-- ============================================================

create policy "Profiles are publicly readable"
on public.profiles
for select
using (true);

create policy "Users can create own profile"
on public.profiles
for insert
to authenticated
with check ((select auth.uid()) = id);

create policy "Users can update own profile"
on public.profiles
for update
to authenticated
using ((select auth.uid()) = id)
with check ((select auth.uid()) = id);

create policy "Users can delete own profile"
on public.profiles
for delete
to authenticated
using ((select auth.uid()) = id);


-- ============================================================
-- USER PREFERENCES
-- Completely private to the authenticated user.
-- ============================================================

create policy "Users can read own preferences"
on public.user_preferences
for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "Users can create own preferences"
on public.user_preferences
for insert
to authenticated
with check ((select auth.uid()) = user_id);

create policy "Users can update own preferences"
on public.user_preferences
for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

create policy "Users can delete own preferences"
on public.user_preferences
for delete
to authenticated
using ((select auth.uid()) = user_id);


-- ============================================================
-- RECIPES
--
-- Owner can access all their recipes.
--
-- Everyone else can read only recipes that are:
--   published
--   public
--   owned by a public profile
-- ============================================================

create policy "Accessible recipes are readable"
on public.recipes
for select
using (
    (select auth.uid()) = owner_id
    or (
        status = 'published'
        and visibility = 'public'
        and exists (
            select 1
            from public.profiles p
            where p.id = recipes.owner_id
              and p.profile_visibility = 'public'
        )
    )
);

create policy "Users can create own recipes"
on public.recipes
for insert
to authenticated
with check ((select auth.uid()) = owner_id);

create policy "Users can update own recipes"
on public.recipes
for update
to authenticated
using ((select auth.uid()) = owner_id)
with check ((select auth.uid()) = owner_id);

create policy "Users can delete own recipes"
on public.recipes
for delete
to authenticated
using ((select auth.uid()) = owner_id);


-- ============================================================
-- RECIPE INGREDIENTS
-- Public when parent recipe is publicly accessible.
-- Owner can manage ingredients on own recipes.
-- ============================================================

create policy "Accessible recipe ingredients are readable"
on public.recipe_ingredients
for select
using (
    exists (
        select 1
        from public.recipes r
        where r.id = recipe_ingredients.recipe_id
          and (
              (select auth.uid()) = r.owner_id
              or (
                  r.status = 'published'
                  and r.visibility = 'public'
                  and exists (
                      select 1
                      from public.profiles p
                      where p.id = r.owner_id
                        and p.profile_visibility = 'public'
                  )
              )
          )
    )
);

create policy "Owners can create recipe ingredients"
on public.recipe_ingredients
for insert
to authenticated
with check (
    exists (
        select 1 from public.recipes r
        where r.id = recipe_ingredients.recipe_id
          and r.owner_id = (select auth.uid())
    )
);

create policy "Owners can update recipe ingredients"
on public.recipe_ingredients
for update
to authenticated
using (
    exists (
        select 1 from public.recipes r
        where r.id = recipe_ingredients.recipe_id
          and r.owner_id = (select auth.uid())
    )
)
with check (
    exists (
        select 1 from public.recipes r
        where r.id = recipe_ingredients.recipe_id
          and r.owner_id = (select auth.uid())
    )
);

create policy "Owners can delete recipe ingredients"
on public.recipe_ingredients
for delete
to authenticated
using (
    exists (
        select 1 from public.recipes r
        where r.id = recipe_ingredients.recipe_id
          and r.owner_id = (select auth.uid())
    )
);


-- ============================================================
-- RECIPE STEPS
-- Same ownership/access model as ingredients.
-- ============================================================

create policy "Accessible recipe steps are readable"
on public.recipe_steps
for select
using (
    exists (
        select 1
        from public.recipes r
        where r.id = recipe_steps.recipe_id
          and (
              r.owner_id = (select auth.uid())
              or (
                  r.status = 'published'
                  and r.visibility = 'public'
                  and exists (
                      select 1 from public.profiles p
                      where p.id = r.owner_id
                        and p.profile_visibility = 'public'
                  )
              )
          )
    )
);

create policy "Owners can create recipe steps"
on public.recipe_steps
for insert
to authenticated
with check (
    exists (
        select 1 from public.recipes r
        where r.id = recipe_steps.recipe_id
          and r.owner_id = (select auth.uid())
    )
);

create policy "Owners can update recipe steps"
on public.recipe_steps
for update
to authenticated
using (
    exists (
        select 1 from public.recipes r
        where r.id = recipe_steps.recipe_id
          and r.owner_id = (select auth.uid())
    )
)
with check (
    exists (
        select 1 from public.recipes r
        where r.id = recipe_steps.recipe_id
          and r.owner_id = (select auth.uid())
    )
);

create policy "Owners can delete recipe steps"
on public.recipe_steps
for delete
to authenticated
using (
    exists (
        select 1 from public.recipes r
        where r.id = recipe_steps.recipe_id
          and r.owner_id = (select auth.uid())
    )
);


-- ============================================================
-- RECIPE MEDIA
-- ============================================================

create policy "Accessible recipe media is readable"
on public.recipe_media
for select
using (
    exists (
        select 1
        from public.recipes r
        where r.id = recipe_media.recipe_id
          and (
              r.owner_id = (select auth.uid())
              or (
                  r.status = 'published'
                  and r.visibility = 'public'
                  and exists (
                      select 1 from public.profiles p
                      where p.id = r.owner_id
                        and p.profile_visibility = 'public'
                  )
              )
          )
    )
);

create policy "Owners can create recipe media"
on public.recipe_media
for insert
to authenticated
with check (
    exists (
        select 1 from public.recipes r
        where r.id = recipe_media.recipe_id
          and r.owner_id = (select auth.uid())
    )
);

create policy "Owners can update recipe media"
on public.recipe_media
for update
to authenticated
using (
    exists (
        select 1 from public.recipes r
        where r.id = recipe_media.recipe_id
          and r.owner_id = (select auth.uid())
    )
)
with check (
    exists (
        select 1 from public.recipes r
        where r.id = recipe_media.recipe_id
          and r.owner_id = (select auth.uid())
    )
);

create policy "Owners can delete recipe media"
on public.recipe_media
for delete
to authenticated
using (
    exists (
        select 1 from public.recipes r
        where r.id = recipe_media.recipe_id
          and r.owner_id = (select auth.uid())
    )
);


-- ============================================================
-- RECIPE IMPORTS
--
-- Raw source material/transcripts are private.
-- Publishing a recipe does NOT expose its import record.
-- ============================================================

create policy "Owners can read recipe imports"
on public.recipe_imports
for select
to authenticated
using (
    exists (
        select 1 from public.recipes r
        where r.id = recipe_imports.recipe_id
          and r.owner_id = (select auth.uid())
    )
);

create policy "Owners can create recipe imports"
on public.recipe_imports
for insert
to authenticated
with check (
    exists (
        select 1 from public.recipes r
        where r.id = recipe_imports.recipe_id
          and r.owner_id = (select auth.uid())
    )
);

create policy "Owners can update recipe imports"
on public.recipe_imports
for update
to authenticated
using (
    exists (
        select 1 from public.recipes r
        where r.id = recipe_imports.recipe_id
          and r.owner_id = (select auth.uid())
    )
)
with check (
    exists (
        select 1 from public.recipes r
        where r.id = recipe_imports.recipe_id
          and r.owner_id = (select auth.uid())
    )
);

create policy "Owners can delete recipe imports"
on public.recipe_imports
for delete
to authenticated
using (
    exists (
        select 1 from public.recipes r
        where r.id = recipe_imports.recipe_id
          and r.owner_id = (select auth.uid())
    )
);


-- ============================================================
-- RECIPE NUTRITION
-- Read follows recipe visibility.
-- Writes restricted to recipe owner for now.
-- ============================================================

create policy "Accessible recipe nutrition is readable"
on public.recipe_nutrition
for select
using (
    exists (
        select 1
        from public.recipes r
        where r.id = recipe_nutrition.recipe_id
          and (
              r.owner_id = (select auth.uid())
              or (
                  r.status = 'published'
                  and r.visibility = 'public'
                  and exists (
                      select 1 from public.profiles p
                      where p.id = r.owner_id
                        and p.profile_visibility = 'public'
                  )
              )
          )
    )
);

create policy "Owners can create recipe nutrition"
on public.recipe_nutrition
for insert
to authenticated
with check (
    exists (
        select 1 from public.recipes r
        where r.id = recipe_nutrition.recipe_id
          and r.owner_id = (select auth.uid())
    )
);

create policy "Owners can update recipe nutrition"
on public.recipe_nutrition
for update
to authenticated
using (
    exists (
        select 1 from public.recipes r
        where r.id = recipe_nutrition.recipe_id
          and r.owner_id = (select auth.uid())
    )
)
with check (
    exists (
        select 1 from public.recipes r
        where r.id = recipe_nutrition.recipe_id
          and r.owner_id = (select auth.uid())
    )
);

create policy "Owners can delete recipe nutrition"
on public.recipe_nutrition
for delete
to authenticated
using (
    exists (
        select 1 from public.recipes r
        where r.id = recipe_nutrition.recipe_id
          and r.owner_id = (select auth.uid())
    )
);


-- ============================================================
-- TAGS
-- Controlled reference data.
-- Everyone can read it; ordinary users cannot modify it.
-- ============================================================

create policy "Tags are publicly readable"
on public.tags
for select
using (true);


-- ============================================================
-- RECIPE TAGS
-- Read follows recipe visibility.
-- Recipe owner controls relationships.
-- ============================================================

create policy "Accessible recipe tags are readable"
on public.recipe_tags
for select
using (
    exists (
        select 1
        from public.recipes r
        where r.id = recipe_tags.recipe_id
          and (
              r.owner_id = (select auth.uid())
              or (
                  r.status = 'published'
                  and r.visibility = 'public'
                  and exists (
                      select 1 from public.profiles p
                      where p.id = r.owner_id
                        and p.profile_visibility = 'public'
                  )
              )
          )
    )
);

create policy "Owners can add recipe tags"
on public.recipe_tags
for insert
to authenticated
with check (
    exists (
        select 1 from public.recipes r
        where r.id = recipe_tags.recipe_id
          and r.owner_id = (select auth.uid())
    )
);

create policy "Owners can remove recipe tags"
on public.recipe_tags
for delete
to authenticated
using (
    exists (
        select 1 from public.recipes r
        where r.id = recipe_tags.recipe_id
          and r.owner_id = (select auth.uid())
    )
);


-- ============================================================
-- SAVES
-- Completely private relationship.
-- ============================================================

create policy "Users can read own saves"
on public.saves
for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "Users can create own saves"
on public.saves
for insert
to authenticated
with check ((select auth.uid()) = user_id);

create policy "Users can delete own saves"
on public.saves
for delete
to authenticated
using ((select auth.uid()) = user_id);


-- ============================================================
-- COLLECTIONS
--
-- Owner always sees own collections.
-- Other users see public collections only when the owner's
-- profile is public.
-- ============================================================

create policy "Accessible collections are readable"
on public.collections
for select
using (
    owner_id = (select auth.uid())
    or (
        visibility = 'public'
        and exists (
            select 1
            from public.profiles p
            where p.id = collections.owner_id
              and p.profile_visibility = 'public'
        )
    )
);

create policy "Users can create own collections"
on public.collections
for insert
to authenticated
with check (owner_id = (select auth.uid()));

create policy "Users can update own collections"
on public.collections
for update
to authenticated
using (owner_id = (select auth.uid()))
with check (owner_id = (select auth.uid()));

create policy "Users can delete own collections"
on public.collections
for delete
to authenticated
using (owner_id = (select auth.uid()));


-- ============================================================
-- COLLECTION RECIPES
-- Access follows the collection.
-- Owner controls membership.
-- ============================================================

create policy "Accessible collection recipes are readable"
on public.collection_recipes
for select
using (
    exists (
        select 1
        from public.collections c
        where c.id = collection_recipes.collection_id
          and (
              c.owner_id = (select auth.uid())
              or (
                  c.visibility = 'public'
                  and exists (
                      select 1
                      from public.profiles p
                      where p.id = c.owner_id
                        and p.profile_visibility = 'public'
                  )
              )
          )
    )
);

create policy "Owners can add recipes to collections"
on public.collection_recipes
for insert
to authenticated
with check (
    exists (
        select 1
        from public.collections c
        where c.id = collection_recipes.collection_id
          and c.owner_id = (select auth.uid())
    )
);

create policy "Owners can update collection recipes"
on public.collection_recipes
for update
to authenticated
using (
    exists (
        select 1
        from public.collections c
        where c.id = collection_recipes.collection_id
          and c.owner_id = (select auth.uid())
    )
)
with check (
    exists (
        select 1
        from public.collections c
        where c.id = collection_recipes.collection_id
          and c.owner_id = (select auth.uid())
    )
);

create policy "Owners can remove recipes from collections"
on public.collection_recipes
for delete
to authenticated
using (
    exists (
        select 1
        from public.collections c
        where c.id = collection_recipes.collection_id
          and c.owner_id = (select auth.uid())
    )
);


-- ============================================================
-- USER DIETARY PREFERENCES
-- Private.
-- ============================================================

create policy "Users can read own dietary preferences"
on public.user_dietary_preferences
for select
to authenticated
using (user_id = (select auth.uid()));

create policy "Users can add own dietary preferences"
on public.user_dietary_preferences
for insert
to authenticated
with check (user_id = (select auth.uid()));

create policy "Users can remove own dietary preferences"
on public.user_dietary_preferences
for delete
to authenticated
using (user_id = (select auth.uid()));


-- ============================================================
-- ALLERGENS
-- Controlled reference data.
-- Everyone may read; ordinary users cannot modify.
-- ============================================================

create policy "Allergens are publicly readable"
on public.allergens
for select
using (true);


-- ============================================================
-- USER ALLERGENS
-- Completely private.
-- ============================================================

create policy "Users can read own allergens"
on public.user_allergens
for select
to authenticated
using (user_id = (select auth.uid()));

create policy "Users can add own allergens"
on public.user_allergens
for insert
to authenticated
with check (user_id = (select auth.uid()));

create policy "Users can remove own allergens"
on public.user_allergens
for delete
to authenticated
using (user_id = (select auth.uid()));


-- ============================================================
-- PRIVATE USER RECIPE NOTES
--
-- Recipe ownership is irrelevant here.
-- Only the note owner may access the note.
-- ============================================================

create policy "Users can read own recipe notes"
on public.user_recipe_notes
for select
to authenticated
using (user_id = (select auth.uid()));

create policy "Users can create own recipe notes"
on public.user_recipe_notes
for insert
to authenticated
with check (user_id = (select auth.uid()));

create policy "Users can update own recipe notes"
on public.user_recipe_notes
for update
to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

create policy "Users can delete own recipe notes"
on public.user_recipe_notes
for delete
to authenticated
using (user_id = (select auth.uid()));