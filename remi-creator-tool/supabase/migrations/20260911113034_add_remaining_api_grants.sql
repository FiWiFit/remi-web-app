-- Profiles
grant insert, update, delete
on table public.profiles
to authenticated;

-- User preferences
grant select, insert, update, delete
on table public.user_preferences
to authenticated;

-- Recipe child data visible with the parent recipe
grant select
on table public.recipe_ingredients,
             public.recipe_steps,
             public.recipe_media,
             public.recipe_nutrition
to anon;

grant select, insert, update, delete
on table public.recipe_ingredients,
             public.recipe_steps,
             public.recipe_media,
             public.recipe_nutrition
to authenticated;

-- Import/provenance data is never public
grant select, insert, update, delete
on table public.recipe_imports
to authenticated;

-- Controlled vocabulary
grant select
on table public.tags,
             public.allergens
to anon, authenticated;

-- Recipe/tag relationships follow recipe visibility
grant select
on table public.recipe_tags
to anon;

grant select, insert, delete
on table public.recipe_tags
to authenticated;

-- Collections
grant select
on table public.collections,
             public.collection_recipes
to anon;

grant select, insert, update, delete
on table public.collections,
             public.collection_recipes
to authenticated;