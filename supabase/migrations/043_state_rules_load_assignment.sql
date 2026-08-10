-- ============================================================
-- 043_state_rules_load_assignment.sql
-- Heavy Haul Command
--
-- Adds load/opportunity-specific State Rules reviews.
-- The reusable state_permit_rules table remains the master library.
-- Safe to rerun.
-- ============================================================

create extension if not exists pgcrypto;

create table if not exists public.route_state_reviews (
  id uuid primary key default gen_random_uuid(),

  tenant_id uuid not null
    references public.tenants(id)
    on delete cascade,

  route_plan_id uuid not null
    references public.route_plans(id)
    on delete cascade,

  load_id uuid
    references public.loads(id)
    on delete cascade,

  opportunity_id uuid
    references public.load_opportunities(id)
    on delete cascade,

  state char(2) not null,

  review_status text not null default 'assigned'
    check (review_status in ('assigned','reviewing','reviewed','returned')),

  state_rule_snapshot jsonb not null default '{}'::jsonb,

  applicability_notes text,
  dispatcher_notes text,
  driver_handoff_notes text,

  assigned_at timestamptz not null default now(),
  reviewed_at timestamptz,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint route_state_review_parent_check
    check (load_id is not null or opportunity_id is not null)
);

create unique index if not exists route_state_reviews_route_state_uidx
  on public.route_state_reviews (route_plan_id, state);

create index if not exists route_state_reviews_tenant_idx
  on public.route_state_reviews (tenant_id, review_status);

create index if not exists route_state_reviews_load_idx
  on public.route_state_reviews (load_id)
  where load_id is not null;

create index if not exists route_state_reviews_opportunity_idx
  on public.route_state_reviews (opportunity_id)
  where opportunity_id is not null;


create table if not exists public.route_state_points (
  id uuid primary key default gen_random_uuid(),

  tenant_id uuid not null
    references public.tenants(id)
    on delete cascade,

  review_id uuid not null
    references public.route_state_reviews(id)
    on delete cascade,

  state char(2) not null,

  point_type text not null
    check (
      point_type in (
        'bridge',
        'toll',
        'weigh_station',
        'checkpoint',
        'inspection',
        'travel_window',
        'construction',
        'required_route',
        'escort_meeting',
        'staging',
        'other'
      )
    ),

  location_name text not null,
  notes text,

  handoff_level text not null default 'reference'
    check (handoff_level in ('reference','suggested','required')),

  added_to_route boolean not null default false,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists route_state_points_review_idx
  on public.route_state_points (review_id, created_at);


create or replace function public.route_state_touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists route_state_reviews_touch
  on public.route_state_reviews;

create trigger route_state_reviews_touch
before update on public.route_state_reviews
for each row
execute function public.route_state_touch_updated_at();

drop trigger if exists route_state_points_touch
  on public.route_state_points;

create trigger route_state_points_touch
before update on public.route_state_points
for each row
execute function public.route_state_touch_updated_at();


alter table public.route_state_reviews enable row level security;
alter table public.route_state_points enable row level security;

drop policy if exists route_state_reviews_tenant_access
  on public.route_state_reviews;

create policy route_state_reviews_tenant_access
on public.route_state_reviews
for all
using (
  exists (
    select 1
    from public.app_users au
    where au.auth_uid = auth.uid()
      and au.tenant_id = route_state_reviews.tenant_id
  )
)
with check (
  exists (
    select 1
    from public.app_users au
    where au.auth_uid = auth.uid()
      and au.tenant_id = route_state_reviews.tenant_id
  )
);

drop policy if exists route_state_points_tenant_access
  on public.route_state_points;

create policy route_state_points_tenant_access
on public.route_state_points
for all
using (
  exists (
    select 1
    from public.app_users au
    where au.auth_uid = auth.uid()
      and au.tenant_id = route_state_points.tenant_id
  )
)
with check (
  exists (
    select 1
    from public.app_users au
    where au.auth_uid = auth.uid()
      and au.tenant_id = route_state_points.tenant_id
  )
);


select table_name
from information_schema.tables
where table_schema='public'
  and table_name in ('route_state_reviews','route_state_points')
order by table_name;
