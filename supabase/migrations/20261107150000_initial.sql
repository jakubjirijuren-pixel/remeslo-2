
create extension if not exists pgcrypto;
create table public.organizations (
 id uuid primary key default gen_random_uuid(),
 name text not null check(length(trim(name))>0),
 created_by uuid not null default auth.uid() references auth.users(id),
 created_at timestamptz not null default now()
);
create table public.memberships (
 organization_id uuid not null references public.organizations(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 role text not null check(role in ('owner','admin','manager','worker','accountant','viewer')),
 primary key (organization_id,user_id)
);
create or replace function public.is_member(org uuid) returns boolean
language sql stable security definer set search_path = ''
as $$ select exists(select 1 from public.memberships m where m.organization_id=org and m.user_id=auth.uid()) $$;
create or replace function public.is_manager(org uuid) returns boolean
language sql stable security definer set search_path = ''
as $$ select exists(select 1 from public.memberships m where m.organization_id=org and m.user_id=auth.uid() and m.role in ('owner','admin','manager')) $$;
revoke all on function public.is_member(uuid), public.is_manager(uuid) from public, anon;
grant execute on function public.is_member(uuid),public.is_manager(uuid) to authenticated;
create or replace function public.add_organization_owner() returns trigger
language plpgsql security definer set search_path = ''
as $$ begin insert into public.memberships(organization_id,user_id,role) values (new.id,new.created_by,'owner'); return new; end $$;
revoke all on function public.add_organization_owner() from public, anon, authenticated;
create trigger organization_owner after insert on public.organizations for each row execute function public.add_organization_owner();
alter table public.organizations enable row level security;
alter table public.memberships enable row level security;
create policy organizations_select on public.organizations for select to authenticated using (public.is_member(id));
create policy organizations_insert on public.organizations for insert to authenticated with check (created_by=(select auth.uid()));
create policy organizations_update on public.organizations for update to authenticated using (public.is_manager(id)) with check (public.is_manager(id) and created_by = (select created_by from public.organizations where id=organizations.id));
create policy memberships_select on public.memberships for select to authenticated using(public.is_member(organization_id));

create table public.customers (
 id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.organizations(id) on delete cascade,
 name text not null,email text,phone text,address text,ico text,notes text,
 created_at timestamptz not null default now(),unique(organization_id,id)
);
create table public.inquiries (
 id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.organizations(id) on delete cascade,
 name text not null,customer_id uuid,status text not null default 'new',description text,
 created_at timestamptz not null default now(),unique(organization_id,id),
 foreign key(organization_id,customer_id) references public.customers(organization_id,id)
);
create table public.quotes (
 id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.organizations(id) on delete cascade,
 name text not null,customer_id uuid,status text not null default 'draft',total numeric(14,2) not null default 0,
 created_at timestamptz not null default now(),unique(organization_id,id),
 foreign key(organization_id,customer_id) references public.customers(organization_id,id)
);
create table public.jobs (
 id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.organizations(id) on delete cascade,
 name text not null,customer_id uuid,quote_id uuid,status text not null default 'planned',
 start_at timestamptz,end_at timestamptz,description text,
 created_at timestamptz not null default now(),unique(organization_id,id),
 foreign key(organization_id,customer_id) references public.customers(organization_id,id),
 foreign key(organization_id,quote_id) references public.quotes(organization_id,id)
);
create table public.workers (
 id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.organizations(id) on delete cascade,
 name text not null,user_id uuid references auth.users(id),phone text,hourly_rate numeric(12,2),
 created_at timestamptz not null default now(),unique(organization_id,id)
);
create table public.job_assignments (
 id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.organizations(id) on delete cascade,
 job_id uuid not null,worker_id uuid not null,created_at timestamptz not null default now(),
 foreign key(organization_id,job_id) references public.jobs(organization_id,id),
 foreign key(organization_id,worker_id) references public.workers(organization_id,id)
);
create table public.time_entries (
 id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.organizations(id) on delete cascade,
 job_id uuid not null,worker_id uuid not null,started_at timestamptz not null,ended_at timestamptz,notes text,
 created_at timestamptz not null default now(),
 foreign key(organization_id,job_id) references public.jobs(organization_id,id),
 foreign key(organization_id,worker_id) references public.workers(organization_id,id)
);
create table public.inventory_items (
 id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.organizations(id) on delete cascade,
 name text not null,sku text,unit text not null default 'ks',quantity numeric(14,3) not null default 0,cost numeric(14,2) not null default 0,
 created_at timestamptz not null default now(),unique(organization_id,id)
);
create table public.material_usage (
 id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.organizations(id) on delete cascade,
 job_id uuid not null,item_id uuid not null,quantity numeric(14,3) not null check(quantity>0),
 created_at timestamptz not null default now(),
 foreign key(organization_id,job_id) references public.jobs(organization_id,id),
 foreign key(organization_id,item_id) references public.inventory_items(organization_id,id)
);
create table public.vehicles (
 id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.organizations(id) on delete cascade,
 name text not null,plate text,created_at timestamptz not null default now(),unique(organization_id,id)
);
create table public.vehicle_trips (
 id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.organizations(id) on delete cascade,
 vehicle_id uuid not null,job_id uuid,start_at timestamptz not null,end_at timestamptz,km numeric(12,1),
 created_at timestamptz not null default now(),
 foreign key(organization_id,vehicle_id) references public.vehicles(organization_id,id),
 foreign key(organization_id,job_id) references public.jobs(organization_id,id)
);
create table public.invoices (
 id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.organizations(id) on delete cascade,
 number text not null,customer_id uuid,job_id uuid,status text not null default 'draft',
 issued_on date,due_on date,total numeric(14,2) not null default 0,
 created_at timestamptz not null default now(),unique(organization_id,id),unique(organization_id,number),
 foreign key(organization_id,customer_id) references public.customers(organization_id,id),
 foreign key(organization_id,job_id) references public.jobs(organization_id,id)
);
create table public.documents (
 id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.organizations(id) on delete cascade,
 name text not null,job_id uuid,storage_path text not null,
 created_at timestamptz not null default now(),
 foreign key(organization_id,job_id) references public.jobs(organization_id,id)
);
create table public.quote_items (
 id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.organizations(id) on delete cascade,
 quote_id uuid not null,description text not null,quantity numeric(12,3) not null default 1,unit_price numeric(14,2) not null default 0,
 vat_rate numeric(5,2) not null default 21,created_at timestamptz not null default now(),
 foreign key(organization_id,quote_id) references public.quotes(organization_id,id)
);
create table public.invoice_items (
 id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.organizations(id) on delete cascade,
 invoice_id uuid not null,description text not null,quantity numeric(12,3) not null default 1,unit_price numeric(14,2) not null default 0,
 vat_rate numeric(5,2) not null default 21,created_at timestamptz not null default now(),
 foreign key(organization_id,invoice_id) references public.invoices(organization_id,id)
);
create table public.notifications (
 id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.organizations(id) on delete cascade,
 user_id uuid not null references auth.users(id),title text not null,body text,read_at timestamptz,
 created_at timestamptz not null default now()
);
create table public.audit_events (
 id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.organizations(id) on delete cascade,
 actor_id uuid references auth.users(id),action text not null,entity_type text not null,entity_id uuid,
 details jsonb not null default '{}'::jsonb,created_at timestamptz not null default now()
);
do $$ declare t text; begin
 foreach t in array array['customers','inquiries','quotes','jobs','workers','job_assignments','time_entries','inventory_items','material_usage','vehicles','vehicle_trips','invoices','documents','quote_items','invoice_items'] loop
 execute format('alter table public.%I enable row level security',t);
 execute format('create policy %I on public.%I for select to authenticated using(public.is_member(organization_id))',t||'_select',t);
 execute format('create policy %I on public.%I for insert to authenticated with check(public.is_manager(organization_id))',t||'_insert',t);
 execute format('create policy %I on public.%I for update to authenticated using(public.is_manager(organization_id)) with check(public.is_manager(organization_id))',t||'_update',t);
 execute format('create policy %I on public.%I for delete to authenticated using(public.is_manager(organization_id))',t||'_delete',t);
 end loop;
end $$;
alter table public.notifications enable row level security;
create policy notifications_select on public.notifications for select to authenticated using(user_id=(select auth.uid()) and public.is_member(organization_id));
create policy notifications_update on public.notifications for update to authenticated using(user_id=(select auth.uid()) and public.is_member(organization_id)) with check(user_id=(select auth.uid()) and public.is_member(organization_id));
alter table public.audit_events enable row level security;
create policy audit_select on public.audit_events for select to authenticated using(public.is_manager(organization_id));
revoke all on public.audit_events from anon,authenticated;
grant select on public.audit_events to authenticated;
grant select,insert,update on public.organizations to authenticated;
grant select on public.memberships to authenticated;
do $$ declare t text; begin
 foreach t in array array['customers','inquiries','quotes','jobs','workers','job_assignments','time_entries','inventory_items','material_usage','vehicles','vehicle_trips','invoices','documents','quote_items','invoice_items'] loop
 execute format('grant select,insert,update,delete on public.%I to authenticated',t);
 end loop;
end $$;
grant select,update on public.notifications to authenticated;
