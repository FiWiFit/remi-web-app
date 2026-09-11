begin;

select plan(17);

-- ============================================================
-- TEST USERS
-- ============================================================

insert into auth.users (id, email)
values
(
    '33333333-3333-3333-3333-333333333333',
    'private-fiona@remi.test'
),
(
    '44444444-4444-4444-4444-444444444444',
    'private-sarah@remi.test'
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
    '33333333-3333-3333-3333-333333333333',
    'private_test_fiona',
    'Private Test Fiona',
    'public'
),
(
    '44444444-4444-4444-4444-444444444444',
    'private_test_sarah',
    'Private Test Sarah',
    'public'
);

-- ============================================================
-- USER PREFERENCES
-- ============================================================

insert into public.user_preferences (
    user_id,
    preferred_unit_system,
    show_nutrition
)
values
(
    '33333333-3333-3333-3333-333333333333',
    'metric',
    true
),
(
    '44444444-4444-4444-4444-444444444444',
    'imperial',
    false
);

-- ============================================================
-- RECIPE
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
    '33333333-3333-3333-3333-333333333333',
    'RLS Private Data Recipe',
    'published',
    'public',
    now()
);

-- ============================================================
-- SAVE
-- ============================================================

insert into public.saves (
    user_id,
    recipe_id
)
select
    '33333333-3333-3333-3333-333333333333',
    id
from public.recipes
where title = 'RLS Private Data Recipe';

-- ============================================================
-- PRIVATE NOTE
-- ============================================================

insert into public.user_recipe_notes (
    user_id,
    recipe_id,
    note
)
select
    '33333333-3333-3333-3333-333333333333',
    id,
    'RLS Fiona private note'
from public.recipes
where title = 'RLS Private Data Recipe';

-- ============================================================
-- DIETARY PREFERENCE
-- ============================================================

insert into public.tags (
    name,
    tag_type
)
values
(
    'rls-test-vegetarian',
    'dietary'
);

insert into public.user_dietary_preferences (
    user_id,
    tag_id
)
select
    '33333333-3333-3333-3333-333333333333',
    id
from public.tags
where name = 'rls-test-vegetarian'
  and tag_type = 'dietary';

-- ============================================================
-- ALLERGEN
-- ============================================================

insert into public.allergens (
    name
)
values
(
    'rls-test-peanuts'
);

insert into public.user_allergens (
    user_id,
    allergen_id
)
select
    '33333333-3333-3333-3333-333333333333',
    id
from public.allergens
where name = 'rls-test-peanuts';

-- ============================================================
-- ANONYMOUS VOCABULARY ACCESS
-- ============================================================

set local role anon;

select results_eq(
    $$
        select count(*)::bigint
        from public.tags
        where name = 'rls-test-vegetarian'
          and tag_type = 'dietary'
    $$,
    array[1::bigint],
    'Anonymous user can read dietary tag vocabulary'
);

select results_eq(
    $$
        select count(*)::bigint
        from public.allergens
        where name = 'rls-test-peanuts'
    $$,
    array[1::bigint],
    'Anonymous user can read allergen vocabulary'
);

-- ============================================================
-- FIONA
-- ============================================================

reset role;
set local role authenticated;
set local request.jwt.claim.sub =
    '33333333-3333-3333-3333-333333333333';

select results_eq(
    $$
        select count(*)::bigint
        from public.user_preferences
        where user_id =
            '33333333-3333-3333-3333-333333333333'
    $$,
    array[1::bigint],
    'Fiona can read her user preferences'
);

select results_eq(
    $$
        select count(*)::bigint
        from public.saves
        where user_id =
            '33333333-3333-3333-3333-333333333333'
    $$,
    array[1::bigint],
    'Fiona can read her saves'
);

select results_eq(
    $$
        select count(*)::bigint
        from public.user_recipe_notes
        where user_id =
            '33333333-3333-3333-3333-333333333333'
    $$,
    array[1::bigint],
    'Fiona can read her private recipe notes'
);

select results_eq(
    $$
        select count(*)::bigint
        from public.user_dietary_preferences
        where user_id =
            '33333333-3333-3333-3333-333333333333'
    $$,
    array[1::bigint],
    'Fiona can read her dietary preferences'
);

select results_eq(
    $$
        select count(*)::bigint
        from public.user_allergens
        where user_id =
            '33333333-3333-3333-3333-333333333333'
    $$,
    array[1::bigint],
    'Fiona can read her allergens'
);

-- ============================================================
-- SARAH CANNOT READ FIONA PRIVATE DATA
-- ============================================================

reset role;
set local role authenticated;
set local request.jwt.claim.sub =
    '44444444-4444-4444-4444-444444444444';

select results_eq(
    $$
        select count(*)::bigint
        from public.user_preferences
        where user_id =
            '33333333-3333-3333-3333-333333333333'
    $$,
    array[0::bigint],
    'Sarah cannot read Fiona user preferences'
);

select results_eq(
    $$
        select count(*)::bigint
        from public.saves
        where user_id =
            '33333333-3333-3333-3333-333333333333'
    $$,
    array[0::bigint],
    'Sarah cannot read Fiona saves'
);

select results_eq(
    $$
        select count(*)::bigint
        from public.user_recipe_notes
        where user_id =
            '33333333-3333-3333-3333-333333333333'
    $$,
    array[0::bigint],
    'Sarah cannot read Fiona notes'
);

select results_eq(
    $$
        select count(*)::bigint
        from public.user_dietary_preferences
        where user_id =
            '33333333-3333-3333-3333-333333333333'
    $$,
    array[0::bigint],
    'Sarah cannot read Fiona dietary preferences'
);

select results_eq(
    $$
        select count(*)::bigint
        from public.user_allergens
        where user_id =
            '33333333-3333-3333-3333-333333333333'
    $$,
    array[0::bigint],
    'Sarah cannot read Fiona allergens'
);

-- ============================================================
-- CROSS-USER WRITE ISOLATION
-- ============================================================

select results_eq(
    $$
        delete from public.saves
        where user_id =
            '33333333-3333-3333-3333-333333333333'
        returning 1
    $$,
    $$ select 1 where false $$,
    'Sarah cannot delete Fiona saves'
);

select results_eq(
    $$
        update public.user_recipe_notes
        set note = 'Sarah must not change this'
        where user_id =
            '33333333-3333-3333-3333-333333333333'
        returning 1
    $$,
    $$ select 1 where false $$,
    'Sarah cannot update Fiona private notes'
);

select results_eq(
    $$
        delete from public.user_dietary_preferences
        where user_id =
            '33333333-3333-3333-3333-333333333333'
        returning 1
    $$,
    $$ select 1 where false $$,
    'Sarah cannot delete Fiona dietary preferences'
);

select results_eq(
    $$
        delete from public.user_allergens
        where user_id =
            '33333333-3333-3333-3333-333333333333'
        returning 1
    $$,
    $$ select 1 where false $$,
    'Sarah cannot delete Fiona allergens'
);

select results_eq(
    $$
        update public.user_preferences
        set preferred_unit_system = 'imperial'
        where user_id =
            '33333333-3333-3333-3333-333333333333'
        returning 1
    $$,
    $$ select 1 where false $$,
    'Sarah cannot update Fiona user preferences'
);

reset role;

select * from finish();

rollback;