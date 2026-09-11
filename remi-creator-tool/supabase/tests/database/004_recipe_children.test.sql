begin;

select plan(23);

-- ============================================================
-- TEST USERS
-- ============================================================

insert into auth.users (id, email)
values
(
    '55555555-5555-5555-5555-555555555555',
    'children-fiona@remi.test'
),
(
    '66666666-6666-6666-6666-666666666666',
    'children-sarah@remi.test'
);

-- ============================================================
-- PROFILES
-- ============================================================

insert into public.profiles (
    id,
    username,
    display_name,
    profile_visibility
)
values
(
    '55555555-5555-5555-5555-555555555555',
    'children_test_fiona',
    'Children Test Fiona',
    'public'
),
(
    '66666666-6666-6666-6666-666666666666',
    'children_test_sarah',
    'Children Test Sarah',
    'private'
);

-- ============================================================
-- RECIPES
-- ============================================================

insert into public.recipes (
    owner_id,
    title,
    status,
    visibility,
    published_at
)
values
(
    '55555555-5555-5555-5555-555555555555',
    'RLS Child Fiona Public',
    'published',
    'public',
    now()
),
(
    '55555555-5555-5555-5555-555555555555',
    'RLS Child Fiona Private',
    'draft',
    'private',
    null
),
(
    '66666666-6666-6666-6666-666666666666',
    'RLS Child Sarah Hidden',
    'published',
    'public',
    now()
);

-- ============================================================
-- INGREDIENTS
-- ============================================================

insert into public.recipe_ingredients (
    recipe_id,
    position,
    name,
    quantity
)
select
    id,
    0,
    'rls-test-' || id::text,
    1
from public.recipes
where title like 'RLS Child %';

-- ============================================================
-- STEPS
-- ============================================================

insert into public.recipe_steps (
    recipe_id,
    position,
    instruction
)
select
    id,
    0,
    'rls-test-step-' || id::text
from public.recipes
where title like 'RLS Child %';

-- ============================================================
-- MEDIA
-- ============================================================

insert into public.recipe_media (
    recipe_id,
    media_type,
    source_url
)
select
    id,
    'image',
    'https://rls.test/' || id::text
from public.recipes
where title like 'RLS Child %';

-- ============================================================
-- NUTRITION
-- ============================================================

insert into public.recipe_nutrition (
    recipe_id,
    provider,
    status,
    calories
)
select
    id,
    'rls-test',
    'calculated',
    500
from public.recipes
where title like 'RLS Child %';

-- ============================================================
-- TAG
-- ============================================================

insert into public.tags (
    name,
    tag_type
)
values
(
    'rls-test-category',
    'category'
);

insert into public.recipe_tags (
    recipe_id,
    tag_id
)
select
    r.id,
    t.id
from public.recipes r
cross join public.tags t
where r.title like 'RLS Child %'
  and t.name = 'rls-test-category';

-- ============================================================
-- IMPORTS
-- ============================================================

insert into public.recipe_imports (
    recipe_id,
    import_method,
    raw_source_text,
    processing_status
)
select
    id,
    'manual',
    'rls-test-fiona-import',
    'completed'
from public.recipes
where title = 'RLS Child Fiona Public';

insert into public.recipe_imports (
    recipe_id,
    import_method,
    raw_source_text,
    processing_status
)
select
    id,
    'manual',
    'rls-test-sarah-import',
    'completed'
from public.recipes
where title = 'RLS Child Sarah Hidden';

-- ============================================================
-- ANONYMOUS
-- ============================================================

set local role anon;

select results_eq(
    $$
        select count(*)::bigint
        from public.recipe_ingredients
        where name like 'rls-test-%'
    $$,
    array[1::bigint],
    'Anonymous sees ingredients for public visible recipe only'
);

select results_eq(
    $$
        select count(*)::bigint
        from public.recipe_steps
        where instruction like 'rls-test-step-%'
    $$,
    array[1::bigint],
    'Anonymous sees steps for public visible recipe only'
);

select results_eq(
    $$
        select count(*)::bigint
        from public.recipe_media
        where source_url like 'https://rls.test/%'
    $$,
    array[1::bigint],
    'Anonymous sees media for public visible recipe only'
);

select results_eq(
    $$
        select count(*)::bigint
        from public.recipe_nutrition
        where provider = 'rls-test'
    $$,
    array[1::bigint],
    'Anonymous sees nutrition for public visible recipe only'
);

select results_eq(
    $$
        select count(*)::bigint
        from public.recipe_tags
        where tag_id = (
            select id
            from public.tags
            where name = 'rls-test-category'
        )
    $$,
    array[1::bigint],
    'Anonymous sees tags for public visible recipe only'
);

select results_eq(
    $$
        select count(*)::bigint
        from public.tags
        where name = 'rls-test-category'
    $$,
    array[1::bigint],
    'Anonymous users can read tag vocabulary'
);

-- ============================================================
-- FIONA
-- ============================================================

reset role;
set local role authenticated;
set local request.jwt.claim.sub =
    '55555555-5555-5555-5555-555555555555';

select results_eq(
    $$
        select count(*)::bigint
        from public.recipe_ingredients
        where name like 'rls-test-%'
    $$,
    array[2::bigint],
    'Fiona sees ingredients for both her recipes'
);

select results_eq(
    $$
        select count(*)::bigint
        from public.recipe_steps
        where instruction like 'rls-test-step-%'
    $$,
    array[2::bigint],
    'Fiona sees steps for both her recipes'
);

select results_eq(
    $$
        select count(*)::bigint
        from public.recipe_media
        where source_url like 'https://rls.test/%'
    $$,
    array[2::bigint],
    'Fiona sees media for both her recipes'
);

select results_eq(
    $$
        select count(*)::bigint
        from public.recipe_nutrition
        where provider = 'rls-test'
    $$,
    array[2::bigint],
    'Fiona sees nutrition for both her recipes'
);

select results_eq(
    $$
        select count(*)::bigint
        from public.recipe_tags
        where tag_id = (
            select id
            from public.tags
            where name = 'rls-test-category'
        )
    $$,
    array[2::bigint],
    'Fiona sees tags for both her recipes'
);

select results_eq(
    $$
        select count(*)::bigint
        from public.recipe_imports
        where raw_source_text = 'rls-test-fiona-import'
    $$,
    array[1::bigint],
    'Fiona can read her own recipe import'
);

select results_eq(
    $$
        select count(*)::bigint
        from public.recipe_imports
        where raw_source_text = 'rls-test-sarah-import'
    $$,
    array[0::bigint],
    'Fiona cannot read Sarah recipe import'
);

select results_eq(
    $$
        update public.recipe_steps
        set instruction = 'rls-test-fiona-owner-update'
        where recipe_id = (
            select id
            from public.recipes
            where title = 'RLS Child Fiona Public'
        )
        returning 1
    $$,
    array[1],
    'Fiona can update child data on her own recipe'
);

-- ============================================================
-- SARAH
-- ============================================================

reset role;
set local role authenticated;
set local request.jwt.claim.sub =
    '66666666-6666-6666-6666-666666666666';

select results_eq(
    $$
        select count(*)::bigint
        from public.recipe_ingredients
        where name like 'rls-test-%'
    $$,
    array[2::bigint],
    'Sarah sees Fiona public ingredients and her own ingredients'
);

select results_eq(
    $$
        select count(*)::bigint
        from public.recipe_steps
        where instruction like 'rls-test-%'
    $$,
    array[2::bigint],
    'Sarah sees Fiona public steps and her own steps'
);

select results_eq(
    $$
        select count(*)::bigint
        from public.recipe_media
        where source_url like 'https://rls.test/%'
    $$,
    array[2::bigint],
    'Sarah sees Fiona public media and her own media'
);

select results_eq(
    $$
        select count(*)::bigint
        from public.recipe_nutrition
        where provider = 'rls-test'
    $$,
    array[2::bigint],
    'Sarah sees Fiona public nutrition and her own nutrition'
);

select results_eq(
    $$
        select count(*)::bigint
        from public.recipe_tags
        where tag_id = (
            select id
            from public.tags
            where name = 'rls-test-category'
        )
    $$,
    array[2::bigint],
    'Sarah sees Fiona public tags and her own tags'
);

select results_eq(
    $$
        select count(*)::bigint
        from public.recipe_imports
        where raw_source_text = 'rls-test-sarah-import'
    $$,
    array[1::bigint],
    'Sarah can read her own recipe import'
);

select results_eq(
    $$
        select count(*)::bigint
        from public.recipe_imports
        where raw_source_text = 'rls-test-fiona-import'
    $$,
    array[0::bigint],
    'Sarah cannot read Fiona recipe import'
);

select results_eq(
    $$
        update public.recipe_steps
        set instruction = 'Sarah must not change this'
        where recipe_id = (
            select id
            from public.recipes
            where title = 'RLS Child Fiona Public'
        )
        returning 1
    $$,
    $$ select 1 where false $$,
    'Sarah cannot update Fiona recipe steps'
);

select results_eq(
    $$
        delete from public.recipe_tags
        where recipe_id = (
            select id
            from public.recipes
            where title = 'RLS Child Fiona Public'
        )
        returning 1
    $$,
    $$ select 1 where false $$,
    'Sarah cannot remove tags from Fiona recipe'
);

reset role;

select * from finish();

rollback;