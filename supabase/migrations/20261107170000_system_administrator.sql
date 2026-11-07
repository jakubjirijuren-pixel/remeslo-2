-- Global system administrators are explicitly appointed by database owner, never by users.
create schema if not exists private;
create table if not exists private.system_administrators (
 user_id uuid primary key references auth.users(id) on delete cascade,
 appointed_at timestamptz not null default now()
);
revoke all on schema private from public,anon,authenticated;
revoke all on private.system_administrators from public,anon,authenticated;
create or replace function public.is_system_administrator()
returns boolean language sql stable security definer set search_path = ''
as $$ select exists(select 1 from private.system_administrators a where a.user_id=(select auth.uid())) $$;
revoke all on function public.is_system_administrator() from public,anon;
grant execute on function public.is_system_administrator() to authenticated;
drop policy if exists organizations_select on public.organizations;
create policy organizations_select on public.organizations for select to authenticated
using (created_by=(select auth.uid()) or public.is_member(id) or public.is_system_administrator());
drop policy if exists memberships_select on public.memberships;
create policy memberships_select on public.memberships for select to authenticated
using (public.is_member(organization_id) or public.is_system_administrator());
do $$ declare t text; begin
 foreach t in array array['customers','inquiries','quotes','jobs','workers','job_assignments','time_entries','inventory_items','material_usage','vehicles','vehicle_trips','invoices','documents','quote_items','invoice_items'] loop
 execute format('drop policy if exists %I on public.%I',t||'_select',t);
 execute format('create policy %I on public.%I for select to authenticated using(public.is_member(organization_id) or public.is_system_administrator())',t||'_select',t);
 execute format('drop policy if exists %I on public.%I',t||'_insert',t);
 execute format('create policy %I on public.%I for insert to authenticated with check(public.is_manager(organization_id) or public.is_system_administrator())',t||'_insert',t);
 execute format('drop policy if exists %I on public.%I',t||'_update',t);
 execute format('create policy %I on public.%I for update to authenticated using(public.is_manager(organization_id) or public.is_system_administrator()) with check(public.is_manager(organization_id) or public.is_system_administrator())',t||'_update',t);
 execute format('drop policy if exists %I on public.%I',t||'_delete',t);
 execute format('create policy %I on public.%I for delete to authenticated using(public.is_manager(organization_id) or public.is_system_administrator())',t||'_delete',t);
 end loop;
end $$;
drop policy if exists audit_select on public.audit_events;
create policy audit_select on public.audit_events for select to authenticated using(public.is_manager(organization_id) or public.is_system_administrator());
