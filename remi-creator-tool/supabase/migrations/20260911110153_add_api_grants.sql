-- Public visitors need table-level SELECT permission.
-- RLS still determines which recipe rows they can actually see.
grant select on table public.recipes to anon;

-- Authenticated users need table-level permissions to work with recipes.
-- RLS still determines which rows each user can access or modify.
grant select, insert, update, delete
on table public.recipes
to authenticated;