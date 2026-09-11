-- Profile metadata is publicly readable.
-- RLS still controls the rows exposed by the profiles table.
grant select
on table public.profiles
to anon, authenticated;