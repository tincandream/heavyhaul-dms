-- ============================================================
-- 026_route_planning.sql
-- Heavy Haul Command
-- Route Planning + Golden Routes
-- ============================================================

create extension if not exists pgcrypto;


-- ============================================================
-- ROUTE PLANS
-- Working route plans for individual loads
-- ============================================================

create table if not exists public.route_plans (

  id uuid
    primary key
    default gen_random_uuid(),

  tenant_id uuid
    not null,

  load_id uuid,

  route_name text,

  freight_type text
    not null
    default 'heavy_haul',

  equipment_type text,

  origin text
    not null,

  destination text
    not null,

  states text[]
    not null
    default '{}',

  waypoints text[]
    not null
    default '{}',

  loaded_miles numeric,

  pickup_at timestamptz,

  delivery_at timestamptz,


  -- Route review

  permit_route_confirmed boolean
    not null
    default false,

  state_rules_reviewed boolean
    not null
    default false,

  bridge_tunnel_reviewed boolean
    not null
    default false,

  construction_reviewed boolean
    not null
    default false,

  travel_windows_reviewed boolean
    not null
    default false,

  escorts_reviewed boolean
    not null
    default false,


  -- Operational notes

  parking_staging text,

  fuel_service_notes text,

  route_notes text,


  -- Escort information

  escort_company text,

  escort_contact text,

  escort_phone text,

  escort_meeting_location text,

  escort_meeting_time timestamptz,


  -- Generated Google Maps route

  google_maps_url text,


  created_at timestamptz
    not null
    default now(),

  updated_at timestamptz
    not null
    default now()

);


-- ============================================================
-- ROUTE PLAN INDEXES
-- ============================================================

create index if not exists
  route_plans_tenant_idx

on public.route_plans (
  tenant_id
);


create index if not exists
  route_plans_load_idx

on public.route_plans (
  load_id
);



-- ============================================================
-- GOLDEN ROUTES
--
-- Reusable route knowledge organized by freight type.
--
-- Supports:
-- Heavy Haul / Oversize
-- Reefer
-- Dry Van
-- Flatbed
-- Step Deck
-- Specialized
-- Other
-- ============================================================

create table if not exists public.golden_routes (

  id uuid
    primary key
    default gen_random_uuid(),

  tenant_id uuid
    not null,


  -- Route identity

  route_name text
    not null,

  freight_type text
    not null
    default 'heavy_haul',

  equipment_type text,


  -- Route

  origin text
    not null,

  destination text
    not null,

  origin_state text,

  destination_state text,

  states text[]
    not null
    default '{}',

  waypoints text[]
    not null
    default '{}',

  corridor text,

  highways text,


  -- General route intelligence

  parking_staging text,

  fuel_service_notes text,

  problem_areas text,

  general_notes text,


  -- ==========================================================
  -- HEAVY HAUL / OVERSIZE HISTORY
  -- ==========================================================

  previous_length_in integer,

  previous_width_in integer,

  previous_height_in integer,

  previous_gross_weight_lb integer,

  axle_notes text,

  permit_notes text,

  escort_notes text,

  clearance_notes text,

  travel_restriction_notes text,


  -- ==========================================================
  -- REEFER ROUTE KNOWLEDGE
  -- ==========================================================

  reefer_notes text,

  washout_service_notes text,

  receiver_approach_notes text,


  -- ==========================================================
  -- ROUTE HISTORY
  -- ==========================================================

  successful_uses integer
    not null
    default 0,

  last_used_on date,

  last_verified_on date,


  -- Shareable map route

  google_maps_url text,


  -- Archive without deleting route history

  active boolean
    not null
    default true,


  created_at timestamptz
    not null
    default now(),

  updated_at timestamptz
    not null
    default now()

);



-- ============================================================
-- GOLDEN ROUTE INDEXES
-- ============================================================

create index if not exists
  golden_routes_tenant_idx

on public.golden_routes (
  tenant_id
);


create index if not exists
  golden_routes_freight_idx

on public.golden_routes (
  tenant_id,
  freight_type
);


create index if not exists
  golden_routes_states_idx

on public.golden_routes (
  origin_state,
  destination_state
);



-- ============================================================
-- UPDATED_AT FUNCTION
-- ============================================================

create or replace function
  public.heavyhaul_set_updated_at()

returns trigger

language plpgsql

as $$

begin

  new.updated_at = now();

  return new;

end;

$$;



-- ============================================================
-- ROUTE PLAN UPDATED_AT TRIGGER
-- ============================================================

drop trigger if exists
  route_plans_set_updated_at

on public.route_plans;


create trigger
  route_plans_set_updated_at

before update
on public.route_plans

for each row

execute function
  public.heavyhaul_set_updated_at();



-- ============================================================
-- GOLDEN ROUTE UPDATED_AT TRIGGER
-- ============================================================

drop trigger if exists
  golden_routes_set_updated_at

on public.golden_routes;


create trigger
  golden_routes_set_updated_at

before update
on public.golden_routes

for each row

execute function
  public.heavyhaul_set_updated_at();



-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

alter table
  public.route_plans
enable row level security;


alter table
  public.golden_routes
enable row level security;



-- ============================================================
-- ROUTE PLAN SECURITY POLICY
-- ============================================================

drop policy if exists
  route_plans_tenant_access

on public.route_plans;


create policy
  route_plans_tenant_access

on public.route_plans

for all

using (

  exists (

    select 1

    from public.app_users au

    where
      au.auth_uid = auth.uid()

      and
      au.tenant_id =
        route_plans.tenant_id

  )

)

with check (

  exists (

    select 1

    from public.app_users au

    where
      au.auth_uid = auth.uid()

      and
      au.tenant_id =
        route_plans.tenant_id

  )

);



-- ============================================================
-- GOLDEN ROUTE SECURITY POLICY
-- ============================================================

drop policy if exists
  golden_routes_tenant_access

on public.golden_routes;


create policy
  golden_routes_tenant_access

on public.golden_routes

for all

using (

  exists (

    select 1

    from public.app_users au

    where
      au.auth_uid = auth.uid()

      and
      au.tenant_id =
        golden_routes.tenant_id

  )

)

with check (

  exists (

    select 1

    from public.app_users au

    where
      au.auth_uid = auth.uid()

      and
      au.tenant_id =
        golden_routes.tenant_id

  )

);
