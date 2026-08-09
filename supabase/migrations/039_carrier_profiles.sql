-- ============================================================
-- 039_carrier_profiles.sql
-- Fleet Command → Profile
--
-- One reusable operating profile per carrier.
-- New Load can later read this record automatically when a fleet
-- is assigned.
--
-- Safe to rerun.
-- ============================================================

create table if not exists public.carrier_profiles (

  id uuid primary key
    default gen_random_uuid(),

  tenant_id uuid not null
    references public.tenants(id)
    on delete cascade,

  carrier_id uuid not null
    references public.carriers(id)
    on delete cascade,

  target_rate_per_mile numeric(10,2),

  minimum_rate_per_mile numeric(10,2),

  minimum_day_rate numeric(12,2),

  max_deadhead_miles integer,

  detention_rate_per_hour numeric(10,2),

  detention_after_hours numeric(6,2),

  tonu_minimum numeric(12,2),

  layover_rate_per_day numeric(12,2),

  negotiables text,

  preferences text,

  requirements text,

  notes text,

  created_at timestamptz
    not null
    default now(),

  updated_at timestamptz
    not null
    default now(),

  constraint carrier_profiles_carrier_unique
    unique (carrier_id)

);


create index if not exists carrier_profiles_tenant_idx
  on public.carrier_profiles (tenant_id);


create or replace function public.carrier_profiles_set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;


drop trigger if exists carrier_profiles_set_updated_at
  on public.carrier_profiles;

create trigger carrier_profiles_set_updated_at
before update on public.carrier_profiles
for each row
execute function public.carrier_profiles_set_updated_at();


alter table public.carrier_profiles
  enable row level security;


drop policy if exists carrier_profiles_tenant_access
  on public.carrier_profiles;

create policy carrier_profiles_tenant_access
on public.carrier_profiles
for all
using (
  exists (
    select 1
    from public.app_users au
    where au.auth_uid = auth.uid()
      and au.tenant_id = carrier_profiles.tenant_id
  )
)
with check (
  exists (
    select 1
    from public.app_users au
    where au.auth_uid = auth.uid()
      and au.tenant_id = carrier_profiles.tenant_id
  )
);


select
  column_name,
  data_type
from information_schema.columns
where table_schema = 'public'
  and table_name = 'carrier_profiles'
order by ordinal_position;
