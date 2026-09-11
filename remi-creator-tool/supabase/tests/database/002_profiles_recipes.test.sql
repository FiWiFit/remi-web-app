begin;

select plan(10);

-- ============================================================
-- TEST USERS
-- ============================================================

insert into auth.users (id, email)
values
(
    '11111111-1111-1111-1111-111111111111',
    'rls-fiona@remi.test'
),
(
    '22222222-2222-2222-2222-222222222222',
    'rls-sarah@remi.test'
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
    '11111111-1111-1111-1111-111111111111',
    'rls_fiona',
    'RLS Fiona',
    'public'
),
(
    '22222222-2222-2222-2222-222222222222',
    'rls_sarah',
    'RLS Sarah',
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
    '11111111-1111-1111-1111-111111111111',
    'RLS Fiona Public Recipe',
    'published',
    'public',
    now()
),
(
    '11111111-1111-1111-1111-111111111111',
    'RLS Fiona Private Draft',
    'draft',
    'private',
    null
),
(
    '22222222-2222-2222-2222-222222222222',
    'RLS Sarah Hidden Recipe',
    'published',
    'public',
    now()
);

-- ============================================================
-- ANONYMOUS
-- ============================================================

set local role anon;

select results_eq(
    $$
        select count(*)::bigint
        from public.profiles
        where username in ('rls_fiona', 'rls_sarah')
    $$,
    array[2::bigint],
    'Anonymous users can read both profile headers'
);

select results_eq(
    $$
        select count(*)::bigint
        from public.recipes
        where title like 'RLS %'
    $$,
    array[1::bigint],
    'Anonymous user sees only Fiona public recipe'
);

-- ============================================================
-- FIONA
-- ============================================================

reset role;
set local role authenticated;
set local request.jwt.claim.sub =
    '11111111-1111-1111-1111-111111111111';

select results_eq(
    $$
        select count(*)::bigint
        from public.recipes
        where title like 'RLS %'
    $$,
    array[2::bigint],
    'Fiona sees her public recipe and private draft'
);

select results_eq(
    $$
        select count(*)::bigint
        from public.recipes
        where title = 'RLS Fiona Private Draft'
    $$,
    array[1::bigint],
    'Fiona can read her own private draft'
);

select results_eq(
    $$
        update public.profiles
        set bio = 'Fiona updated her own profile'
        where id = '11111111-1111-1111-1111-111111111111'
        returning 1
    $$,
    array[1],
    'Fiona can update her own profile'
);

select results_eq(
    $$
        update public.recipes
        set description = 'Owner update'
        where owner_id = '11111111-1111-1111-1111-111111111111'
          and title = 'RLS Fiona Private Draft'
        returning 1
    $$,
    array[1],
    'Fiona can update her own recipe'
);

-- ============================================================
-- SARAH
-- ============================================================

reset role;
set local role authenticated;
set local request.jwt.claim.sub =
    '22222222-2222-2222-2222-222222222222';

select results_eq(
    $$
        select count(*)::bigint
        from public.recipes
        where title like 'RLS %'
    $$,
    array[2::bigint],
    'Sarah sees Fiona public recipe and her own hidden recipe'
);

select results_eq(
    $$
        select count(*)::bigint
        from public.recipes
        where title = 'RLS Sarah Hidden Recipe'
    $$,
    array[1::bigint],
    'Sarah can read her own recipe despite private profile'
);

select results_eq(
    $$
        update public.profiles
        set bio = 'Sarah must not change Fiona'
        where id = '11111111-1111-1111-1111-111111111111'
        returning 1
    $$,
    $$ select 1 where false $$,
    'Sarah cannot update Fiona profile'
);

select results_eq(
    $$
        update public.recipes
        set description = 'Sarah must not change Fiona recipe'
        where owner_id = '11111111-1111-1111-1111-111111111111'
        returning 1
    $$,
    $$ select 1 where false $$,
    'Sarah cannot update Fiona recipes'
);

reset role;

select * from finish();

rollback;