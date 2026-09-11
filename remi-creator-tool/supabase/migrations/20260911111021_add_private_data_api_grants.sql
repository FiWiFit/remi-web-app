-- Authenticated users need table-level access to their own saves.
-- RLS still restricts each user to their own rows.
grant select, insert, delete
on table public.saves
to authenticated;

-- Authenticated users need table-level access to their own private recipe notes.
-- RLS still restricts each user to their own rows.
grant select, insert, update, delete
on table public.user_recipe_notes
to authenticated;