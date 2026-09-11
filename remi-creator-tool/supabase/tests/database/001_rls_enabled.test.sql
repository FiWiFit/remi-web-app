begin;

select plan(2);

-- ------------------------------------------------------------
-- All expected REMI tables exist
-- ------------------------------------------------------------

select results_eq(
    $$
        select count(*)::bigint
        from pg_catalog.pg_tables
        where schemaname = 'public'
          and tablename in (
              'profiles',
              'user_preferences',
              'recipes',
              'recipe_ingredients',
              'recipe_steps',
              'recipe_media',
              'recipe_imports',
              'recipe_nutrition',
              'tags',
              'recipe_tags',
              'saves',
              'collections',
              'collection_recipes',
              'user_dietary_preferences',
              'allergens',
              'user_allergens',
              'user_recipe_notes'
          )
    $$,
    array[17::bigint],
    'All 17 REMI public tables exist'
);

-- ------------------------------------------------------------
-- Every REMI table has RLS enabled
-- ------------------------------------------------------------

select results_eq(
    $$
        select count(*)::bigint
        from pg_catalog.pg_class c
        join pg_catalog.pg_namespace n
          on n.oid = c.relnamespace
        where n.nspname = 'public'
          and c.relname in (
              'profiles',
              'user_preferences',
              'recipes',
              'recipe_ingredients',
              'recipe_steps',
              'recipe_media',
              'recipe_imports',
              'recipe_nutrition',
              'tags',
              'recipe_tags',
              'saves',
              'collections',
              'collection_recipes',
              'user_dietary_preferences',
              'allergens',
              'user_allergens',
              'user_recipe_notes'
          )
          and c.relrowsecurity = false
    $$,
    array[0::bigint],
    'RLS is enabled on every REMI public table'
);

select * from finish();

rollback;