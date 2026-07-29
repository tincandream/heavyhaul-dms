-- ============================================================
-- 008_fleet_board.sql
-- Users, the expanded status model, check-ins, Fleet Board
-- ============================================================

-- ------------------------------------------------------------
-- APP USERS
-- Links a Supabase Auth login to a tenant and a role.
-- Every RLS policy in 010 reads this table. Until your own
-- row exists with auth_uid set, every query returns empty.
-- ------------------------------------------------------------
create table app_users (
  id          uuid primary key default gen_random_uuid(),
  tenant_id   uuid not null references tenants(id),
  full_name   text not null,
  email       text not null,
  phone       text,
  role        text not null default 'dispatcher'
              check (role in ('owner','admin','dispatcher','viewer','driver')),
  auth_uid    uuid,
  status      text not null default 'active'
              check (status in ('active','inactive')),
  created_at  timestamptz not null default now()
);
create unique index idx_app_users_email on app_users(tenant_id, lower(email));
create unique index idx_app_users_auth  on app_users(auth_uid)
  where auth_uid is not null;


-- ------------------------------------------------------------
-- EQUIPMENT: home driver and operational state
-- Drivers stay on the same truck for months. The load carries
-- the exception when they don't — no assignment-history table
-- needed until you actually have a reason for one.
-- ------------------------------------------------------------
alter table equipment add column default_driver_id uuid references drivers(id);
alter table equipment add column home_base_facility_id uuid references facilities(id);
alter table equipment add column operational_status text not null default 'available'
  check (operational_status in ('available','assigned','out_of_service',
                                'in_maintenance','reserved'));
alter table equipment add column out_of_service_reason text;


-- ------------------------------------------------------------
-- LOADS: full lifecycle status
-- ------------------------------------------------------------
alter table loads drop constraint loads_status_check;
alter table loads add constraint loads_status_check check (status in (
  'quoted','booked','permits_pending','dispatched','en_route_to_pickup',
  'at_shipper','loading','loaded','in_transit','at_weigh_station',
  'under_inspection','at_receiver','unloading','delivered','pod_pending',
  'paperwork','invoiced','paid','cancelled','tonu'));


-- ------------------------------------------------------------
-- LOADS: holds — orthogonal to status, always reversible.
-- A breakdown doesn't destroy the fact that the load was
-- in_transit. Clear the hold and it resumes where it was.
-- ------------------------------------------------------------
alter table loads add column hold_reason text check (hold_reason in (
  'awaiting_permits','awaiting_escort','breakdown','weather','traffic',
  'road_closure','hos_shutdown','detention_shipper','detention_receiver',
  'curfew','holiday_restriction','other'));
alter table loads add column hold_since timestamptz;
alter table loads add column hold_note text;
alter table loads add column hold_expected_clear_at timestamptz;


-- ------------------------------------------------------------
-- LOADS: General Information panel fields
-- ------------------------------------------------------------
alter table loads add column dispatcher_id uuid references app_users(id);
alter table loads add column customer_reference text;
alter table loads add column purchase_order text;
alter table loads add column total_miles int;
alter table loads add column rate_per_mile numeric(10,2)
  generated always as (
    round((coalesce(linehaul_rate,0) + coalesce(fuel_surcharge,0))
          / nullif(total_miles,0), 2)) stored;
alter table loads add column priority text not null default 'normal'
  check (priority in ('critical','high','normal','low'));
alter table loads add column next_action_override text;
alter table loads add column next_action_due timestamptz;
alter table loads add column permit_responsibility text not null default 'dispatcher'
  check (permit_responsibility in ('dispatcher','carrier','broker','shipper','permit_service'));
alter table loads add column escort_responsibility text not null default 'dispatcher'
  check (escort_responsibility in ('dispatcher','carrier','broker','shipper','escort_company'));


-- ------------------------------------------------------------
-- LOADS: current position, written by the check-in trigger.
-- Denormalized so the Fleet Board reads one row per truck
-- instead of scanning check-in history on every render.
-- ------------------------------------------------------------
alter table loads add column current_location_text text;
alter table loads add column current_state char(2);
alter table loads add column current_lat numeric(9,6);
alter table loads add column current_lng numeric(9,6);
alter table loads add column last_check_in_at timestamptz;
alter table loads add column current_eta timestamptz;
alter table loads add column eta_updated_at timestamptz;
alter table loads add column driver_hours_remaining_min int;
alter table loads add column hours_updated_at timestamptz;

create index idx_loads_priority on loads(tenant_id, priority)
  where priority in ('critical','high');
create index idx_loads_hold on loads(tenant_id, hold_reason)
  where hold_reason is not null;


-- ------------------------------------------------------------
-- One active load per truck. Prevents a truck appearing twice
-- on the board. Delivered/POD-pending are excluded so you can
-- dispatch the next load while paperwork is still open.
-- ------------------------------------------------------------
create unique index idx_one_active_load_per_truck on loads (tractor_id)
  where status in ('dispatched','en_route_to_pickup','at_shipper','loading',
                   'loaded','in_transit','at_weigh_station','under_inspection',
                   'at_receiver','unloading');


-- ------------------------------------------------------------
-- CHECK-INS
-- ------------------------------------------------------------
create table check_ins (
  id                uuid primary key default gen_random_uuid(),
  tenant_id         uuid not null references tenants(id),
  load_id           uuid not null references loads(id) on delete cascade,
  driver_id         uuid references drivers(id),
  occurred_at       timestamptz not null default now(),
  location_text     text,
  state             char(2),
  latitude          numeric(9,6),
  longitude         numeric(9,6),
  odometer          int,
  eta               timestamptz,
  hos_remaining_min int,
  fuel_level_pct    int,
  source            text not null default 'dispatcher'
                    check (source in ('dispatcher','driver_sms','driver_app','eld','manual')),
  note              text,
  created_by        uuid references app_users(id),
  created_at        timestamptz not null default now()
);
create index idx_checkins_load on check_ins(load_id, occurred_at desc);
create index idx_checkins_tenant on check_ins(tenant_id, occurred_at desc);


-- ------------------------------------------------------------
-- Apply a check-in: update the load's live position and write
-- a timeline entry. The occurred_at guard stops a backdated
-- check-in from overwriting newer information.
-- ------------------------------------------------------------
create or replace function apply_check_in()
returns trigger
language plpgsql
as $$
begin
  update loads set
    current_location_text = coalesce(new.location_text, current_location_text),
    current_state         = coalesce(new.state, current_state),
    current_lat           = coalesce(new.latitude, current_lat),
    current_lng           = coalesce(new.longitude, current_lng),
    current_eta           = coalesce(new.eta, current_eta),
    eta_updated_at        = case when new.eta is not null
                                 then now() else eta_updated_at end,
    driver_hours_remaining_min = coalesce(new.hos_remaining_min,
                                          driver_hours_remaining_min),
    hours_updated_at      = case when new.hos_remaining_min is not null
                                 then now() else hours_updated_at end,
    last_check_in_at      = new.occurred_at
  where id = new.load_id
    and (last_check_in_at is null or last_check_in_at <= new.occurred_at);

  insert into events (tenant_id, entity_type, entity_id, load_id, event_type,
                      direction, occurred_at, subject, body)
  values (new.tenant_id, 'load', new.load_id, new.load_id, 'check_call', 'inbound',
          new.occurred_at, 'Check-in',
          coalesce(new.location_text,'')
          || case when new.eta is not null
                  then ' · ETA ' || to_char(new.eta, 'MM/DD HH12:MIam')
                  else '' end);
  return new;
end;
$$;

create trigger trg_check_in after insert on check_ins
for each row execute function apply_check_in();


-- ------------------------------------------------------------
-- Auto-associate an uploaded document with everything the
-- load already knows: carrier, broker, driver, truck, trailer.
-- One file, six links, zero copies.
-- ------------------------------------------------------------
create or replace function link_document_to_load(p_document_id uuid, p_load_id uuid)
returns int
language plpgsql
as $$
declare v_load loads%rowtype; n int;
begin
  select * into v_load from loads where id = p_load_id;
  if not found then
    raise exception 'Load % not found', p_load_id;
  end if;

  insert into document_links (tenant_id, document_id, entity_type, entity_id, relation)
  select v_load.tenant_id, p_document_id, x.etype, x.eid,
         case when x.etype = 'load' then 'primary' else 'reference' end
    from (values
      ('load'::text,  v_load.id),
      ('carrier',     v_load.carrier_id),
      ('broker',      v_load.broker_id),
      ('driver',      v_load.driver_id),
      ('equipment',   v_load.tractor_id),
      ('equipment',   v_load.trailer_id)
    ) as x(etype, eid)
   where x.eid is not null
  on conflict do nothing;

  get diagnostics n = row_count;
  return n;
end;
$$;


-- ------------------------------------------------------------
-- NEXT REQUIRED ACTION — derived, not typed.
-- A typed field goes stale the moment the permit comes through,
-- and then the board is lying to you.
-- ------------------------------------------------------------
create or replace function load_next_action(p_load_id uuid)
returns text
language sql
stable
as $$
  select coalesce(
    (select next_action_override from loads
      where id = p_load_id and next_action_override is not null),
    (select 'Resolve ' || replace(hold_reason,'_',' ') from loads
      where id = p_load_id and hold_reason is not null),
    (select 'File ' || state || ' permit' from permits
      where load_id = p_load_id and status in ('needed','rejected')
      order by (select planned_entry_date from load_legs lg where lg.id = load_leg_id)
        nulls last
      limit 1),
    (select 'Book ' || replace(role,'_',' ') || ' escort' from escort_assignments
      where load_id = p_load_id and status in ('needed','quoted')
      limit 1),
    (select 'Upload POD' from loads
      where id = p_load_id and status in ('delivered','pod_pending')),
    (select 'Check in with driver' from loads
      where id = p_load_id
        and last_check_in_at < now() - interval '8 hours'),
    'On track');
$$;


-- ------------------------------------------------------------
-- FLEET BOARD
-- One row per tractor. The lateral join guarantees exactly one
-- load per truck, preferring the one that's actually moving
-- over one sitting in POD-pending.
-- ------------------------------------------------------------
create view v_fleet_board as
select
  t.id            as truck_id,
  t.tenant_id,
  t.unit_number   as truck_number,
  t.operational_status,
  t.out_of_service_reason,

  tr.id           as trailer_id,
  tr.unit_number  as trailer_number,
  tr.equipment_type as trailer_type,

  coalesce(l.driver_id, t.default_driver_id) as driver_id,
  coalesce(dl.first_name || ' ' || dl.last_name,
           dt.first_name || ' ' || dt.last_name) as driver_name,
  coalesce(dl.phone, dt.phone) as driver_phone,

  l.id            as load_id,
  l.load_number,
  l.status        as load_status,
  l.priority,
  l.hold_reason,
  l.hold_since,
  l.hold_note,

  case
    when l.id is null              then t.operational_status
    when l.hold_reason is not null then l.hold_reason
    else l.status
  end as display_status,

  c.legal_name    as carrier_name,
  b.name          as broker_name,
  fo.city || ', ' || fo.state as origin,
  fd.city || ', ' || fd.state as destination,

  l.pickup_appt_start,
  l.delivery_appt_start,
  case when l.actual_pickup_at is null
       then l.pickup_appt_start else l.delivery_appt_start end as next_event_at,
  case when l.id is null then null
       when l.actual_pickup_at is null then 'Pickup' else 'Delivery' end as next_event_label,

  l.current_location_text,
  l.current_state,
  l.current_eta,
  l.last_check_in_at,
  round(extract(epoch from (now() - l.last_check_in_at)) / 60) as check_in_age_min,
  l.driver_hours_remaining_min,

  l.width_in, l.height_in, l.length_in, l.weight_lb, l.is_superload,

  coalesce(ps.permits_total, 0)  as permits_total,
  coalesce(ps.permits_issued, 0) as permits_issued,
  coalesce(ps.permits_open, 0)   as permits_open,
  ps.has_window_conflict,
  ps.first_blocking_date,

  coalesce(esc.escorts_total, 0)     as escorts_total,
  coalesce(esc.escorts_confirmed, 0) as escorts_confirmed,

  load_next_action(l.id) as next_action,

  case
    when l.hold_reason = 'breakdown'                     then 1
    when l.hold_reason is not null                       then 2
    when ps.has_window_conflict                          then 2
    when l.priority = 'critical'                         then 2
    when coalesce(ps.permits_open,0) > 0
         and l.status not in ('quoted','booked')         then 3
    when l.last_check_in_at < now() - interval '8 hours' then 4
    when l.id is not null                                then 5
    else 6
  end as attention_rank

from equipment t
left join lateral (
  select * from loads lo
   where lo.tractor_id = t.id
     and lo.status in ('dispatched','en_route_to_pickup','at_shipper','loading',
                       'loaded','in_transit','at_weigh_station','under_inspection',
                       'at_receiver','unloading','delivered','pod_pending')
   order by case when lo.status in ('delivered','pod_pending') then 2 else 1 end,
            lo.pickup_appt_start
   limit 1
) l on true
left join equipment  tr on tr.id = l.trailer_id
left join drivers    dl on dl.id = l.driver_id
left join drivers    dt on dt.id = t.default_driver_id
left join carriers   c  on c.id  = l.carrier_id
left join brokers    b  on b.id  = l.broker_id
left join facilities fo on fo.id = l.origin_facility_id
left join facilities fd on fd.id = l.dest_facility_id
left join v_load_permit_status ps on ps.load_id = l.id
left join lateral (
  select count(*) as escorts_total,
         count(*) filter (where status in ('confirmed','en_route','completed'))
           as escorts_confirmed
    from escort_assignments e where e.load_id = l.id
) esc on true
where t.equipment_type = 'tractor'
  and t.status = 'active';
