-- ============================================================
-- 037_load_assembly_meta.sql
-- Heavy Haul Command
--
-- Persists New Load assignment metadata that does not belong
-- directly on the reusable Fleet Setup, Route Planning, or
-- State Rules master records.
--
-- Safe to rerun.
-- ============================================================

create extension if not exists pgcrypto;

create table if not exists public.load_assembly_meta (

  load_id uuid primary key
    references public.loads(id)
    on delete cascade,

  tenant_id uuid not null
    references public.tenants(id)
    on delete cascade,

  route_source_type text,

  route_source_id uuid,

  route_name text,

  route_notes text,

  route_url text,

  state_rules_reviewed_at timestamptz,

  state_rules_snapshot jsonb
    not null
    default '[]'::jsonb,

  created_at timestamptz
    not null
    default now(),

  updated_at timestamptz
    not null
    default now(),

  constraint load_assembly_route_source_type_check
    check (
      route_source_type is null
      or route_source_type in (
        'route_plan',
        'golden_route',
        'manual'
      )
    )

);

create index if not exists load_assembly_meta_tenant_idx
  on public.load_assembly_meta (tenant_id);

create index if not exists load_assembly_meta_route_source_idx
  on public.load_assembly_meta (route_source_type, route_source_id);


create or replace function public.load_assembly_meta_set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;


drop trigger if exists load_assembly_meta_set_updated_at
  on public.load_assembly_meta;

create trigger load_assembly_meta_set_updated_at
before update on public.load_assembly_meta
for each row
execute function public.load_assembly_meta_set_updated_at();


alter table public.load_assembly_meta
  enable row level security;


drop policy if exists load_assembly_meta_tenant_access
  on public.load_assembly_meta;

create policy load_assembly_meta_tenant_access
on public.load_assembly_meta
for all
using (
  exists (
    select 1
    from public.app_users au
    where au.auth_uid = auth.uid()
      and au.tenant_id = load_assembly_meta.tenant_id
  )
)
with check (
  exists (
    select 1
    from public.app_users au
    where au.auth_uid = auth.uid()
      and au.tenant_id = load_assembly_meta.tenant_id
  )
);


select
  column_name,
  data_type
from information_schema.columns
where table_schema = 'public'
  and table_name = 'load_assembly_meta'
order by ordinal_position;
