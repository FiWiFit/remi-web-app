-- Authenticated users need table-level access to their own dietary preferences.
-- RLS still restricts each user to their own rows.
grant select, insert, delete
on table public.user_dietary_preferences
to authenticated;

-- Authenticated users need table-level access to their own allergens.
-- RLS still restricts each user to their own rows.
grant select, insert, delete
on table public.user_allergens
to authenticated;