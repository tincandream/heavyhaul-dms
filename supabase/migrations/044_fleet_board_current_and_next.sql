-- ============================================================
-- 044_fleet_board_current_and_next.sql
-- Keep Fleet Board truck-centered, but expose:
--   1) current physical/active load
--   2) next booked/dispatched assignment
--
-- Existing v_fleet_board columns are preserved in the same order.
-- New next_* columns are appended at the end.
-- ============================================================

create or replace view public.v_fleet_board as

select
  t.id as truck_id,
  t.tenant_id,
  t.unit_number as truck_number,
  t.operational_status,
  t.out_of_service_reason,

  tr.id as trailer_id,
  tr.unit_number as trailer_number,
  tr.equipment_type as trailer_type,

  coalesce(l.driver_id, t.default_driver_id) as driver_id,
  coalesce(
    (dl.first_name || ' ' || dl.last_name),
    (dt.first_name || ' ' || dt.last_name)
  ) as driver_name,
  coalesce(dl.phone, dt.phone) as driver_phone,

  l.id as load_id,
  l.load_number,
  l.status as load_status,
  l.priority,
  l.hold_reason,
  l.hold_since,
  l.hold_note,

  case
    when l.id is null then t.operational_status
    when l.hold_reason is not null then l.hold_reason
    else l.status
  end as display_status,

  c.legal_name as carrier_name,
  b.name as broker_name,
  (fo.city || ', ' || fo.state::text) as origin,
  (fd.city || ', ' || fd.state::text) as destination,

  l.pickup_appt_start,
  l.delivery_appt_start,

  case
    when l.actual_pickup_at is null then l.pickup_appt_start
    else l.delivery_appt_start
  end as next_event_at,

  case
    when l.id is null then null::text
    when l.actual_pickup_at is null then 'Pickup'::text
    else 'Delivery'::text
  end as next_event_label,

  l.current_location_text,
  l.current_state,
  l.current_eta,
  l.last_check_in_at,

  round(
    extract(epoch from now() - l.last_check_in_at) / 60::numeric
  ) as check_in_age_min,

  l.driver_hours_remaining_min,

  l.width_in,
  l.height_in,
  l.length_in,
  l.weight_lb,
  l.is_superload,

  coalesce(ps.permits_total, 0::bigint) as permits_total,
  coalesce(ps.permits_issued, 0::bigint) as permits_issued,
  coalesce(ps.permits_open, 0::bigint) as permits_open,
  ps.has_window_conflict,
  ps.first_blocking_date,

  coalesce(esc.escorts_total, 0::bigint) as escorts_total,
  coalesce(esc.escorts_confirmed, 0::bigint) as escorts_confirmed,

  load_next_action(l.id) as next_action,

  case
    when l.hold_reason = 'breakdown' then 1
    when l.hold_reason is not null then 2
    when ps.has_window_conflict then 2
    when l.priority = 'critical' then 2
    when coalesce(ps.permits_open, 0::bigint) > 0
      and l.status <> all(array['quoted'::text, 'booked'::text]) then 3
    when l.last_check_in_at < (now() - interval '8 hours') then 4
    when l.id is not null then 5
    else 6
  end as attention_rank,

  -- ==========================================================
  -- NEXT ASSIGNMENT
  -- ==========================================================

  nl.id as next_load_id,
  nl.load_number as next_load_number,
  nl.broker_load_number as next_broker_load_number,
  nl.status as next_load_status,
  nl.priority as next_priority,

  nc.legal_name as next_carrier_name,
  nb.name as next_broker_name,

  coalesce(
    (ndl.first_name || ' ' || ndl.last_name),
    (dt.first_name || ' ' || dt.last_name)
  ) as next_driver_name,

  ntr.id as next_trailer_id,
  ntr.unit_number as next_trailer_number,
  ntr.equipment_type as next_trailer_type,

  (nfo.city || ', ' || nfo.state::text) as next_origin,
  (nfd.city || ', ' || nfd.state::text) as next_destination,

  nl.pickup_appt_start as next_pickup_appt_start,
  nl.delivery_appt_start as next_delivery_appt_start,

  nl.width_in as next_width_in,
  nl.height_in as next_height_in,
  nl.length_in as next_length_in,
  nl.weight_lb as next_weight_lb,
  nl.is_superload as next_is_superload,

  coalesce(nps.permits_total, 0::bigint) as next_permits_total,
  coalesce(nps.permits_issued, 0::bigint) as next_permits_issued,
  coalesce(nps.permits_open, 0::bigint) as next_permits_open,

  coalesce(nesc.escorts_total, 0::bigint) as next_escorts_total,
  coalesce(nesc.escorts_confirmed, 0::bigint) as next_escorts_confirmed

from public.equipment t

-- ------------------------------------------------------------
-- CURRENT LOAD:
-- physical movement / active execution statuses only.
-- "dispatched" is intentionally NOT here; it is treated as
-- upcoming until physical movement begins.
-- ------------------------------------------------------------
left join lateral (
  select lo.*
  from public.loads lo
  where lo.tractor_id = t.id
    and lo.status = any (
      array[
        'en_route_to_pickup'::text,
        'at_shipper'::text,
        'loading'::text,
        'loaded'::text,
        'in_transit'::text,
        'at_weigh_station'::text,
        'under_inspection'::text,
        'at_receiver'::text,
        'unloading'::text,
        'delivered'::text,
        'pod_pending'::text
      ]
    )
  order by
    case
      when lo.status = any(array['delivered'::text, 'pod_pending'::text])
        then 2
      else 1
    end,
    lo.pickup_appt_start nulls last,
    lo.created_at
  limit 1
) l on true

left join public.equipment tr on tr.id = l.trailer_id
left join public.drivers dl on dl.id = l.driver_id
left join public.drivers dt on dt.id = t.default_driver_id
left join public.carriers c on c.id = l.carrier_id
left join public.brokers b on b.id = l.broker_id
left join public.facilities fo on fo.id = l.origin_facility_id
left join public.facilities fd on fd.id = l.dest_facility_id
left join public.v_load_permit_status ps on ps.load_id = l.id

left join lateral (
  select
    count(*) as escorts_total,
    count(*) filter (
      where e.status = any(
        array['confirmed'::text, 'en_route'::text, 'completed'::text]
      )
    ) as escorts_confirmed
  from public.escort_assignments e
  where e.load_id = l.id
) esc on true

-- ------------------------------------------------------------
-- NEXT LOAD:
-- booked or dispatched future assignment for this tractor.
-- Exclude the current load id if the workflow ever overlaps.
-- ------------------------------------------------------------
left join lateral (
  select lo.*
  from public.loads lo
  where lo.tractor_id = t.id
    and lo.status = any (
      array[
        'booked'::text,
        'dispatched'::text
      ]
    )
    and (l.id is null or lo.id <> l.id)
  order by
    lo.pickup_appt_start nulls last,
    lo.created_at
  limit 1
) nl on true

left join public.equipment ntr on ntr.id = nl.trailer_id
left join public.drivers ndl on ndl.id = nl.driver_id
left join public.carriers nc on nc.id = nl.carrier_id
left join public.brokers nb on nb.id = nl.broker_id
left join public.facilities nfo on nfo.id = nl.origin_facility_id
left join public.facilities nfd on nfd.id = nl.dest_facility_id
left join public.v_load_permit_status nps on nps.load_id = nl.id

left join lateral (
  select
    count(*) as escorts_total,
    count(*) filter (
      where e.status = any(
        array['confirmed'::text, 'en_route'::text, 'completed'::text]
      )
    ) as escorts_confirmed
  from public.escort_assignments e
  where e.load_id = nl.id
) nesc on true

where
  t.equipment_type = 'tractor'
  and t.status = 'active';


-- Verification: TRN-101 should show LD-2002 as current and LD-2003 as next.
select
  truck_number,
  load_number as current_load,
  load_status as current_status,
  next_load_number,
  next_load_status,
  next_origin,
  next_destination,
  next_permits_total,
  next_permits_issued
from public.v_fleet_board
where truck_number = 'TRN-101';
