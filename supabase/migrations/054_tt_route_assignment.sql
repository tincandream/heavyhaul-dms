-- ============================================================
-- 054_tt_route_assignment.sql
-- HEAVY HAUL COMMAND
-- TT TRAINING ROUTE ASSIGNMENT
-- ============================================================

-- Training load:
-- Broker: ABC Logistics
-- Broker Load #: TT-ABC-260811-01
-- Internal Load: LD-2009
-- Little Rock, AR -> Memphis, TN
-- Equipment: RGN
--
-- This migration is safe to run more than once.
-- It will not create a duplicate Route Plan for the load.
-- ============================================================


INSERT INTO public.route_plans (
    tenant_id,
    load_id,
    opportunity_id,

    route_name,
    freight_type,
    equipment_type,

    origin,
    destination,
    states,
    waypoints,

    loaded_miles,

    pickup_at,
    delivery_at,

    parking_staging,
    fuel_service_notes,
    route_notes,

    google_maps_url,
    workflow_status
)

SELECT
    l.tenant_id,
    l.id,
    NULL,

    'TT — Little Rock AR → Memphis TN | RGN',
    'heavy_haul',
    'RG-212 · Rgn',

    'Hugg & Hall Equipment Co., 7201 Scott Hamilton Drive, Little Rock, AR, 72209',
    'Thompson Machinery, 1245 Getwell Road, Memphis, TN, 38111',

    ARRAY['AR', 'TN']::text[],
    ARRAY[]::text[],

    137,

    '2026-08-18 00:00:00',
    '2026-08-19 00:00:00',

    NULL,
    NULL,

    'TT TRAINING ROUTE — ABC Logistics excavator move from Little Rock, AR to Memphis, TN. Review heavy-haul routing, state requirements, permits, restrictions, staging, fuel/service and final dispatch routing before marking Ready for State Rules.',

    NULL,
    'in_progress'

FROM public.loads l

WHERE
    l.id = '8ecebe8d-910c-4d38-8cdc-241688c42a19'
    AND l.tenant_id = 'e9dee1c9-7fc8-4caa-ab63-44328eaf532d'

    AND NOT EXISTS (
        SELECT 1
        FROM public.route_plans rp
        WHERE
            rp.tenant_id = l.tenant_id
            AND rp.load_id = l.id
    );
