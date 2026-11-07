-- Allow the creator to read a freshly inserted organization before the AFTER INSERT owner-membership trigger completes.
-- Required for PostgREST INSERT ... RETURNING (Supabase .insert(...).select()).
drop policy if exists organizations_select on public.organizations;
create policy organizations_select on public.organizations
  for select to authenticated
  using (created_by = (select auth.uid()) or public.is_member(id));
