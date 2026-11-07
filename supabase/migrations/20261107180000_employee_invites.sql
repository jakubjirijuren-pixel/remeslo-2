-- Organization admins can read memberships and manage worker accounts through a server-side invite function.
-- Never grant client-side insert/update on memberships.
drop policy if exists memberships_select on public.memberships;
create policy memberships_select on public.memberships for select to authenticated
using(public.is_member(organization_id) or public.is_system_administrator());
create or replace function public.can_manage_employees(org uuid)
returns boolean language sql stable security definer set search_path = ''
as $$ select exists(select 1 from public.memberships m where m.organization_id=org and m.user_id=(select auth.uid()) and m.role in ('owner','admin')) or public.is_system_administrator() $$;
revoke all on function public.can_manage_employees(uuid) from public,anon;
grant execute on function public.can_manage_employees(uuid) to authenticated;
