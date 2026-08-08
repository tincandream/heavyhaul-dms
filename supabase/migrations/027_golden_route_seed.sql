-- ============================================================
-- 027_golden_route_seed.sql
-- Heavy Haul Command
-- Preloaded Reference Golden Routes
--
-- IMPORTANT:
-- These are REFERENCE FREIGHT CORRIDORS / STARTING POINTS.
-- They are NOT guaranteed truck-legal routes for every vehicle,
-- shipment, permit, dimension, weight, axle configuration,
-- hazmat load, weather condition, construction condition, or
-- appointment requirement.
--
-- Heavy haul / oversize:
-- The current permit-authorized route and state requirements control.
--
-- Source framework:
-- FHWA National Highway Freight Network (NHFN)
-- FHWA Freight Analysis Framework (FAF)
-- ============================================================


-- ============================================================
-- 1. ADD ROUTE CLASSIFICATION FIELDS
-- ============================================================

alter table public.golden_routes
  add column if not exists route_class text
  not null
  default 'company';

alter table public.golden_routes
  add column if not exists source_note text;

create index if not exists golden_routes_class_idx
  on public.golden_routes (tenant_id, route_class);


-- ============================================================
-- 2. REFERENCE CORRIDOR LIBRARY
--
-- Each corridor is expanded into six freight types:
--
-- heavy_haul
-- reefer
-- dry_van
-- flatbed
-- step_deck
-- specialized
-- ============================================================

with corridor_seed as (

  select *
  from (
    values

    -- I-5 WEST COAST
    (
      'I-5 West Coast Corridor',
      'San Diego, CA',
      'Seattle, WA',
      'CA',
      'WA',
      array['CA','OR','WA']::text[],
      array[
        'Los Angeles, CA',
        'Sacramento, CA',
        'Portland, OR'
      ]::text[],
      'West Coast north-south freight backbone',
      'I-5',
      'Major West Coast freight corridor connecting Southern California, Northern California, Oregon, and Washington.'
    ),

    -- I-10 SOUTHERN
    (
      'I-10 Southern Corridor',
      'Los Angeles, CA',
      'Jacksonville, FL',
      'CA',
      'FL',
      array['CA','AZ','NM','TX','LA','MS','AL','FL']::text[],
      array[
        'Phoenix, AZ',
        'San Antonio, TX',
        'New Orleans, LA'
      ]::text[],
      'Southern transcontinental freight backbone',
      'I-10',
      'Major southern east-west freight corridor linking Southern California, the Southwest, Texas, Gulf Coast, and Florida.'
    ),

    -- I-20 SOUTHERN
    (
      'I-20 Southern Industrial Corridor',
      'Dallas, TX',
      'Atlanta, GA',
      'TX',
      'GA',
      array['TX','LA','MS','AL','GA']::text[],
      array[
        'Shreveport, LA',
        'Jackson, MS',
        'Birmingham, AL'
      ]::text[],
      'South-Central to Southeast freight corridor',
      'I-20',
      'Reference corridor connecting major distribution, manufacturing, construction, and industrial markets across the South.'
    ),

    -- I-35 CENTRAL
    (
      'I-35 Central Freight Corridor',
      'Laredo, TX',
      'Minneapolis, MN',
      'TX',
      'MN',
      array['TX','OK','KS','MO','IA','MN']::text[],
      array[
        'San Antonio, TX',
        'Oklahoma City, OK',
        'Kansas City, MO'
      ]::text[],
      'Central north-south freight backbone',
      'I-35',
      'Major north-south freight corridor connecting the Texas border region with central U.S. distribution and Midwest markets.'
    ),

    -- I-40
    (
      'I-40 Trans-South Freight Corridor',
      'Barstow, CA',
      'Wilmington, NC',
      'CA',
      'NC',
      array['CA','AZ','NM','TX','OK','AR','TN','NC']::text[],
      array[
        'Albuquerque, NM',
        'Oklahoma City, OK',
        'Memphis, TN'
      ]::text[],
      'Southwest to Mid-South and Southeast freight backbone',
      'I-40',
      'Major east-west freight corridor through the Southwest, Oklahoma, Arkansas, Tennessee, and North Carolina.'
    ),

    -- I-55
    (
      'I-55 Mississippi Valley Corridor',
      'New Orleans, LA',
      'Chicago, IL',
      'LA',
      'IL',
      array['LA','MS','TN','AR','MO','IL']::text[],
      array[
        'Jackson, MS',
        'Memphis, TN',
        'St. Louis, MO'
      ]::text[],
      'Mississippi Valley north-south freight corridor',
      'I-55',
      'Reference north-south freight corridor connecting Gulf Coast, Memphis, St. Louis, and Chicago-region markets.'
    ),

    -- I-65
    (
      'I-65 Central South Corridor',
      'Mobile, AL',
      'Gary, IN',
      'AL',
      'IN',
      array['AL','TN','KY','IN']::text[],
      array[
        'Birmingham, AL',
        'Nashville, TN',
        'Louisville, KY'
      ]::text[],
      'Gulf / Southeast to Midwest freight corridor',
      'I-65',
      'Reference corridor linking Alabama, Nashville, Louisville, Indianapolis-region freight, and the southern Chicago market.'
    ),

    -- I-70
    (
      'I-70 Central Interstate Corridor',
      'Denver, CO',
      'Columbus, OH',
      'CO',
      'OH',
      array['CO','KS','MO','IL','IN','OH']::text[],
      array[
        'Kansas City, MO',
        'St. Louis, MO',
        'Indianapolis, IN'
      ]::text[],
      'Central U.S. east-west freight corridor',
      'I-70',
      'Major central interstate reference corridor serving Mountain West, Plains, Midwest, and Ohio Valley freight markets.'
    ),

    -- I-75
    (
      'I-75 Southeast to Great Lakes Corridor',
      'Miami, FL',
      'Detroit, MI',
      'FL',
      'MI',
      array['FL','GA','TN','KY','OH','MI']::text[],
      array[
        'Atlanta, GA',
        'Knoxville, TN',
        'Cincinnati, OH'
      ]::text[],
      'Southeast to Great Lakes freight backbone',
      'I-75',
      'Major north-south freight reference corridor connecting Florida, Atlanta, Tennessee, Ohio, and Michigan.'
    ),

    -- I-80
    (
      'I-80 Western / Midwest Corridor',
      'Sacramento, CA',
      'Chicago, IL',
      'CA',
      'IL',
      array['CA','NV','UT','WY','NE','IA','IL']::text[],
      array[
        'Salt Lake City, UT',
        'Omaha, NE',
        'Des Moines, IA'
      ]::text[],
      'Western to Midwest east-west freight backbone',
      'I-80',
      'Major transcontinental freight reference corridor connecting Northern California, Mountain West, Plains, and Chicago.'
    ),

    -- I-90
    (
      'I-90 Northern Freight Corridor',
      'Seattle, WA',
      'Boston, MA',
      'WA',
      'MA',
      array[
        'WA','ID','MT','WY','SD','MN','WI',
        'IL','IN','OH','PA','NY','MA'
      ]::text[],
      array[
        'Billings, MT',
        'Minneapolis, MN',
        'Chicago, IL'
      ]::text[],
      'Northern transcontinental freight backbone',
      'I-90',
      'Major northern east-west freight reference corridor connecting Pacific Northwest, northern Plains, Great Lakes, New York, and New England.'
    ),

    -- I-95
    (
      'I-95 East Coast Corridor',
      'Miami, FL',
      'Boston, MA',
      'FL',
      'MA',
      array[
        'FL','GA','SC','NC','VA','MD','DE',
        'PA','NJ','NY','CT','RI','MA'
      ]::text[],
      array[
        'Jacksonville, FL',
        'Richmond, VA',
        'New York, NY'
      ]::text[],
      'East Coast north-south freight backbone',
      'I-95',
      'Major East Coast freight reference corridor connecting Florida, Southeast, Mid-Atlantic, Northeast, and New England markets.'
    )

  ) as c (
    corridor_name,
    origin,
    destination,
    origin_state,
    destination_state,
    states,
    waypoints,
    corridor,
    highways,
    corridor_note
  )

),

freight_types as (

  select *
  from (
    values
      ('heavy_haul'),
      ('reefer'),
      ('dry_van'),
      ('flatbed'),
      ('step_deck'),
      ('specialized')
  ) as f (freight_type)

),

expanded_seed as (

  select
    c.*,
    f.freight_type,

    case f.freight_type

      when 'heavy_haul' then
        'REFERENCE ONLY — Heavy haul/oversize routing must be reverified for the exact load. Current state permits, dimensions, weight, axle configuration, escort requirements, clearances, construction, and travel restrictions control.'

      when 'reefer' then
        'REFERENCE ONLY — General freight backbone for reefer planning. Verify current appointment timing, fuel strategy, parking, washout/service availability, weather, and temperature-control requirements.'

      when 'dry_van' then
        'REFERENCE ONLY — General national freight corridor for dry-van planning. Verify current road conditions, appointments, tolls, parking, and carrier-specific operating preferences.'

      when 'flatbed' then
        'REFERENCE ONLY — General freight corridor for flatbed planning. Verify cargo securement needs, tarping/staging requirements, dimensions, weather exposure, and any load-specific restrictions.'

      when 'step_deck' then
        'REFERENCE ONLY — General freight corridor for step-deck planning. Verify loaded height, dimensions, securement, clearances, and any oversize permit requirements for the actual shipment.'

      when 'specialized' then
        'REFERENCE ONLY — Starting corridor for specialized freight planning. Verify equipment requirements, dimensions, permits, escorts, route restrictions, securement, and customer-specific instructions.'

      else
        'REFERENCE ONLY — Verify route suitability for the current load.'

    end as freight_note

  from corridor_seed c
  cross join freight_types f

),

tenants as (

  select distinct tenant_id
  from public.app_users
  where tenant_id is not null

)

insert into public.golden_routes (

  tenant_id,

  route_name,
  route_class,
  source_note,

  freight_type,
  equipment_type,

  origin,
  destination,
  origin_state,
  destination_state,

  states,
  waypoints,

  corridor,
  highways,

  parking_staging,
  fuel_service_notes,
  problem_areas,
  general_notes,

  permit_notes,
  escort_notes,
  clearance_notes,
  travel_restriction_notes,

  reefer_notes,
  washout_service_notes,
  receiver_approach_notes,

  successful_uses,
  last_used_on,
  last_verified_on,

  google_maps_url,
  active

)

select

  t.tenant_id,

  'REFERENCE — ' || e.corridor_name,
  'reference',
  'FHWA National Highway Freight Network / Freight Analysis Framework reference-corridor seed.',

  e.freight_type,
  null,

  e.origin,
  e.destination,
  e.origin_state,
  e.destination_state,

  e.states,
  e.waypoints,

  e.corridor,
  e.highways,

  null,
  null,
  null,

  e.corridor_note || ' ' || e.freight_note,

  case
    when e.freight_type = 'heavy_haul'
      then 'No permit approval is implied by this reference record. Obtain and follow current permits for the actual move.'
    else null
  end,

  case
    when e.freight_type = 'heavy_haul'
      then 'Escort requirements are load- and state-specific. Verify for the current dimensions and route.'
    else null
  end,

  case
    when e.freight_type in ('heavy_haul','step_deck','specialized')
      then 'No clearance guarantee is implied. Verify loaded height, structures, bridges, tunnels, and current restrictions.'
    else null
  end,

  case
    when e.freight_type = 'heavy_haul'
      then 'Verify state travel windows, curfews, weekend/holiday restrictions, construction, weather, and permit conditions.'
    else null
  end,

  case
    when e.freight_type = 'reefer'
      then 'Use this corridor as a starting point only. Add company-preferred fuel, washout, parking, repair, and cold-chain service locations as they are learned.'
    else null
  end,

  null,
  null,

  0,
  null,
  null,

  null,
  true

from tenants t
cross join expanded_seed e

where not exists (

  select 1

  from public.golden_routes g

  where g.tenant_id = t.tenant_id
    and g.route_name = 'REFERENCE — ' || e.corridor_name
    and g.freight_type = e.freight_type
    and g.route_class = 'reference'

);


-- ============================================================
-- 3. VERIFICATION
--
-- Expected for one tenant:
-- 12 corridors x 6 freight types = 72 reference records.
-- ============================================================

select
  route_class,
  freight_type,
  count(*) as route_count

from public.golden_routes

where route_class = 'reference'

group by
  route_class,
  freight_type

order by
  freight_type;
