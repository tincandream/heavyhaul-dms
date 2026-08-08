Thursday 6:32 PM

export default function LoginPage() {
return (
<main
className="min-h-screen bg-cover bg-center flex items-center justify-center px-4"
style={{
backgroundImage:
"linear-gradient(rgba(15,23,42,.72), rgba(15,23,42,.82)), url('/heavy-haul-bg.jpg')",
}}
>

Heavy Haul Command

Dispatch Management System

    <form className="space-y-5">
      <div>
        <label className="mb-2 block text-sm text-slate-200">
          Email
        </label>
        <input
          type="email"
          placeholder="you@company.com"
          className="w-full rounded-lg border border-slate-700 bg-slate-900/80 px-4 py-3 text-white outline-none focus:border-orange-500"
        />
      </div>

      <div>
        <label className="mb-2 block text-sm text-slate-200">
          Password
        </label>
        <input
          type="password"
          placeholder="••••••••"
          className="w-full rounded-lg border border-slate-700 bg-slate-900/80 px-4 py-3 text-white outline-none focus:border-orange-500"
        />
      </div>

      <button
        type="submit"
        className="w-full rounded-lg bg-orange-500 py-3 font-semibold text-white hover:bg-orange-600"
      >
        Sign In
      </button>
    </form>
  </div>
</main>


);
} <--wanting to make this something similar to this for the sign on to my hh management system. ive been creating it with claude, github and supabase

Let’s try this color palette it’s the same from my site
Edit
Edit
Edit
Edit
Pasted text(20260807-035444).txt
Document
Yesterday 8:47 AM
Pasted text(20260807-134744).txt
Document
are you able to see the code?
Pasted text(20260807-224449).txt
Document
Pasted text(20260807-230138).txt
Document
Pasted text(20260808-022408).txt
Document
Pasted text(20260808-180839).txt
Document
Pasted text(20260808-185101).txt
Document

Yes — that was the plan, and you’re right to bring it back up.

We should preload the Golden Routes section with useful national freight corridors, then let your own successful company routes build on top of that.

The important distinction is that I would label the preloaded entries Reference Golden Routes rather than pretending they are universally permit-approved. FHWA’s National Highway Freight Network identifies the highways most critical to U.S. freight movement, and the Primary Highway Freight System alone covers about 41,799 centerline miles. That gives us a solid authoritative backbone for the preload.

I’d organize the database by freight type like this:

Heavy Haul / Oversize — major freight corridors as starting points, with strong VERIFY PERMIT ROUTE labeling
Reefer — major produce, food-processing, cold-storage, port and distribution corridors
Dry Van — major national distribution and manufacturing lanes
Flatbed / Step Deck — construction, steel, machinery and industrial corridors
Specialized — industrial, energy, port and equipment corridors

The preloaded records can contain things like:

I-40 Mid-South Corridor
Freight Types:
Heavy Haul
Dry Van
Reefer
Flatbed
Step Deck

Memphis, TN ↔ Little Rock, AR ↔ Oklahoma City, OK

Reference Type:
National Freight Corridor

Highways:
I-40

[ Open in Google Maps ]
[ Use as Starting Point ]

FHWA also provides the Freight Analysis Framework, which includes freight flows by origin, destination, commodity and mode. That means we can do something smarter than simply dumping every Interstate into the database: we can seed corridors that actually matter to freight movement and attach relevant freight categories.

Then your Golden Routes screen becomes:

GOLDEN ROUTES

Search...
Freight Type ▼
Origin State ▼
Destination State ▼
Route Type ▼

REFERENCE ROUTES
I-40 Mid-South Corridor
I-35 Central Corridor
I-10 Southern Corridor
I-75 Southeast / Midwest Corridor
...

COMPANY GOLDEN ROUTES
Routes your carriers have actually used successfully

And I'd visually distinguish them:

REFERENCE = preloaded national freight intelligence
COMPANY VERIFIED = one of your actual successfully used routes

For heavy haul, even a Company Verified route would still show Reverify for current load, because dimensions, weight, axles, permits, construction and restrictions can change. The NHFN itself is a national freight-planning network, not an oversize permit-routing system.

So yes: we should preload it.

The next logical step is a new migration, 027_golden_route_seed.sql, that inserts the initial national Golden Route/reference-corridor library into the golden_routes table you just created. Then they will automatically appear on the Golden Routes tab and can be filtered by freight type.

ok , made

Great — if you've created 027_golden_route_seed.sql, we're ready for the actual preload.

I’d like to seed it with a useful starter library rather than a handful of arbitrary highways: major U.S. freight corridors categorized for Heavy Haul/Oversize, Reefer, Dry Van, Flatbed, Step Deck, and Specialized, with Google Maps-compatible origins/destinations and clear REFERENCE — VERIFY BEFORE USE status.

I'll also make sure the seed SQL matches the exact columns we created in 026, so it can be pasted into both GitHub and Supabase without changing your schema.

Next, I'll give you the complete 027_golden_route_seed.sql code to paste into the file you just made.

sounds good
Worked for 45s

Done — 027_golden_route_seed.sql is ready.

Download 027_golden_route_seed.sql

I built the preload around major Interstate freight backbones using FHWA’s National Highway Freight Network as the reference framework. FHWA defines the NHFN as the national network supporting critical highway freight movement, while the Freight Analysis Framework provides origin/destination, commodity, and mode freight-flow data.

This migration seeds 12 national reference corridors across 6 freight types, so with one tenant you’ll get 72 preloaded Golden Route records:

Heavy Haul / Oversize · Reefer · Dry Van · Flatbed · Step Deck · Specialized

The corridors include I-5, I-10, I-20, I-35, I-40, I-55, I-65, I-70, I-75, I-80, I-90, and I-95. They’re deliberately labeled REFERENCE rather than pretending they are permit-approved heavy-haul routes. FHWA’s freight network identifies critical freight highways; it is not an oversize/overweight permitting system.

The migration also adds:

route_class
source_note

so later we can distinguish:

REFERENCE
Preloaded national freight corridor

COMPANY
A route your operation has actually used/saved
Do this now

Put the same SQL in:

supabase/migrations/027_golden_route_seed.sql

and commit it to GitHub.

Then paste the same SQL into Supabase → SQL Editor → Run.

At the very bottom, 027 automatically runs a verification query. For one tenant, you should see approximately:

heavy_haul    12
reefer        12
dry_van       12
flatbed       12
step_deck     12
specialized   12

After that, open Fleet Command → Route Planning → Golden Routes. The tab should no longer be empty — you should immediately have the preloaded route library to search by freight type. 

027_golden_route_seed.sql
Code

Library
/
027_golden_route_seed.sql
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
--
-- This lets us distinguish:
--   reference = preloaded national freight corridor
--   company   = route saved/verified by your operation
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
-- Each corridor is expanded into six freight-type records:
--
-- heavy_haul
-- reefer
-- dry_van
-- flatbed
-- step_deck
-- specialized
--
-- This means the existing Freight Type filter in
-- route-planning.html can pull up relevant reference routes
-- immediately.
-- ============================================================

with corridor_seed as (

  select *
  from (
    values

    -- --------------------------------------------------------
    -- I-5 WEST COAST
    -- --------------------------------------------------------
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

    -- --------------------------------------------------------
    -- I-10 SOUTHERN
    -- --------------------------------------------------------
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

    -- --------------------------------------------------------
    -- I-20 SOUTHERN
    -- --------------------------------------------------------
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

    -- --------------------------------------------------------
    -- I-35 CENTRAL
    -- --------------------------------------------------------
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

    -- --------------------------------------------------------
    -- I-40
    -- --------------------------------------------------------
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

    -- --------------------------------------------------------
    -- I-55
    -- --------------------------------------------------------
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

    -- --------------------------------------------------------
    -- I-65
    -- --------------------------------------------------------
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

    -- --------------------------------------------------------
    -- I-70
    -- --------------------------------------------------------
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

    -- --------------------------------------------------------
    -- I-75
    -- --------------------------------------------------------
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

    -- --------------------------------------------------------
    -- I-80
    -- --------------------------------------------------------
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

    -- --------------------------------------------------------
    -- I-90
    -- --------------------------------------------------------
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

    -- --------------------------------------------------------
    -- I-95
    -- --------------------------------------------------------
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
--
-- If you have multiple tenants, each tenant receives its own
-- separate 72-record reference library.
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

Library
/
027_golden_route_seed.sql
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
--
-- This lets us distinguish:
--   reference = preloaded national freight corridor
--   company   = route saved/verified by your operation
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
-- Each corridor is expanded into six freight-type records:
--
-- heavy_haul
-- reefer
-- dry_van
-- flatbed
-- step_deck
-- specialized
--
-- This means the existing Freight Type filter in
-- route-planning.html can pull up relevant reference routes
-- immediately.
-- ============================================================

with corridor_seed as (

  select *
  from (
    values

    -- --------------------------------------------------------
    -- I-5 WEST COAST
    -- --------------------------------------------------------
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

    -- --------------------------------------------------------
    -- I-10 SOUTHERN
    -- --------------------------------------------------------
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

    -- --------------------------------------------------------
    -- I-20 SOUTHERN
    -- --------------------------------------------------------
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

    -- --------------------------------------------------------
    -- I-35 CENTRAL
    -- --------------------------------------------------------
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

    -- --------------------------------------------------------
    -- I-40
    -- --------------------------------------------------------
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

    -- --------------------------------------------------------
    -- I-55
    -- --------------------------------------------------------
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

    -- --------------------------------------------------------
    -- I-65
    -- --------------------------------------------------------
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

    -- --------------------------------------------------------
    -- I-70
    -- --------------------------------------------------------
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

    -- --------------------------------------------------------
    -- I-75
    -- --------------------------------------------------------
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

    -- --------------------------------------------------------
    -- I-80
    -- --------------------------------------------------------
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

    -- --------------------------------------------------------
    -- I-90
    -- --------------------------------------------------------
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

    -- --------------------------------------------------------
    -- I-95
    -- --------------------------------------------------------
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
--
-- If you have multiple tenants, each tenant receives its own
-- separate 72-record reference library.
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
