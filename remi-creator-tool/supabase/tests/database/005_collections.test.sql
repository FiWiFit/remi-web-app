begin;

select plan(12);

-- ============================================================
-- TEST USERS
-- ============================================================

insert into auth.users (id, email)
values
(
    '77777777-7777-7777-7777-777777777777',
    'collections-fiona@remi.test'
),
(
    '88888888-8888-8888-8888-888888888888',
    'collections-sarah@remi.test'
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
    '77777777-7777-7777-7777-777777777777',
    'collections_test_fiona',
    'Collections Fiona',
    'public'
),
(
    '88888888-8888-8888-8888-888888888888',
    'collections_test_sarah',
    'Collections Sarah',
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
    '77777777-7777-7777-7777-777777777777',
    'RLS Collection Fiona Public Recipe',
    'published',
    'public',
    now()
),
(
    '77777777-7777-7777-7777-777777777777',
    'RLS Collection Fiona Private Recipe',
    'draft',
    'private',
    null
),
(
    '88888888-8888-8888-8888-888888888888',
    'RLS Collection Sarah Recipe',
    'published',
    'public',
    now()
);

-- ============================================================
-- COLLECTIONS
-- ============================================================

insert into public.collections (
    owner_id,
    name,
    visibility
)
values
(
    '77777777-7777-7777-7777-777777777777',
    'RLS Fiona Public Collection',
    'public'
),
(
    '77777777-7777-7777-7777-777777777777',
    'RLS Fiona Private Collection',
    'private'
),
(
    '88888888-8888-8888-8888-888888888888',
    'RLS Sarah Public Collection',
    'public'
);

-- ============================================================
-- COLLECTION MEMBERSHIP
-- ============================================================

insert into public.collection_recipes (
    collection_id,
    recipe_id,
    position
)
select
    c.id,
    r.id,
    0
from public.collections c
join public.recipes r
    on r.owner_id = c.owner_id
where c.name = 'RLS Fiona Public Collection'
  and r.title = 'RLS Collection Fiona Public Recipe';

insert into public.collection_recipes (
    collection_id,
    recipe_id,
    position
)
select
    c.id,
    r.id,
    0
from public.collections c
join public.recipes r
    on r.owner_id = c.owner_id
where c.name = 'RLS Fiona Private Collection'
  and r.title = 'RLS Collection Fiona Private Recipe';

insert into public.collection_recipes (
    collection_id,
    recipe_id,
    position
)
select
    c.id,
    r.id,
    0
from public.collections c
join public.recipes r
    on r.owner_id = c.owner_id
where c.name = 'RLS Sarah Public Collection'
  and r.title = 'RLS Collection Sarah Recipe';

-- ============================================================
-- ANONYMOUS
-- ============================================================

set local role anon;

select results_eq(
    $$
        select count(*)::bigint
        from public.collections
        where name like 'RLS % Collection'
    $$,
    array[1::bigint],
    'Anonymous sees only Fiona public collection'
);

select results_eq(
    $$
        select count(*)::bigint
        from public.collection_recipes cr
        join public.collections c
            on c.id = cr.collection_id
        where c.name like 'RLS % Collection'
    $$,
    array[1::bigint],
    'Anonymous sees membership of Fiona public collection only'
);

select results_eq(
    $$
        select count(*)::bigint
        from public.collections
        where name = 'RLS Sarah Public Collection'
    $$,
    array[0::bigint],
    'Anonymous cannot see public collection owned by private profile'
);

-- ============================================================
-- FIONA
-- ============================================================

reset role;
set local role authenticated;
set local request.jwt.claim.sub =
    '77777777-7777-7777-7777-777777777777';

select results_eq(
    $$
        select count(*)::bigint
        from public.collections
        where name like 'RLS % Collection'
    $$,
    array[2::bigint],
    'Fiona sees both of her collections'
);

select results_eq(
    $$
        select count(*)::bigint
        from public.collection_recipes cr
        join public.collections c
            on c.id = cr.collection_id
        where c.name like 'RLS % Collection'
    $$,
    array[2::bigint],
    'Fiona sees membership of both her collections'
);

select results_eq(
    $$
        select count(*)::bigint
        from public.collections
        where name = 'RLS Sarah Public Collection'
    $$,
    array[0::bigint],
    'Fiona cannot see Sarah collection because Sarah profile is private'
);

-- ============================================================
-- SARAH
-- ============================================================

reset role;
set local role authenticated;
set local request.jwt.claim.sub =
    '88888888-8888-8888-8888-888888888888';

select results_eq(
    $$
        select count(*)::bigint
        from public.collections
        where name like 'RLS % Collection'
    $$,
    array[2::bigint],
    'Sarah sees Fiona public collection and her own collection'
);

select results_eq(
    $$
        select count(*)::bigint
        from public.collection_recipes cr
        join public.collections c
            on c.id = cr.collection_id
        where c.name like 'RLS % Collection'
    $$,
    array[2::bigint],
    'Sarah sees Fiona public membership and her own membership'
);

-- ============================================================
-- OWNER WRITES
-- ============================================================

reset role;
set local role authenticated;
set local request.jwt.claim.sub =
    '77777777-7777-7777-7777-777777777777';

select results_eq(
    $$
        update public.collections
        set description = 'Fiona owner update'
        where name = 'RLS Fiona Private Collection'
        returning 1
    $$,
    array[1],
    'Fiona can update her own collection'
);

reset role;
set local role authenticated;
set local request.jwt.claim.sub =
    '88888888-8888-8888-8888-888888888888';

select results_eq(
    $$
        update public.collections
        set description = 'Sarah must not change Fiona collection'
        where name = 'RLS Fiona Public Collection'
        returning 1
    $$,
    $$ select 1 where false $$,
    'Sarah cannot update Fiona collection'
);

select results_eq(
    $$
        update public.collections
        set description = 'Sarah owner update'
        where name = 'RLS Sarah Public Collection'
        returning 1
    $$,
    array[1],
    'Sarah can update her own collection'
);

select results_eq(
    $$
        delete from public.collection_recipes
        where collection_id = (
            select id
            from public.collections
            where name = 'RLS Fiona Public Collection'
        )
        returning 1
    $$,
    $$ select 1 where false $$,
    'Sarah cannot remove recipes from Fiona collection'
);

reset role;

select * from finish();

rollback;