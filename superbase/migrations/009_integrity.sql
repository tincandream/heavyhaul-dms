-- ============================================================
-- 009_integrity.sql
-- Tamper-evident event log, immutable documents, soft delete,
-- status machine, validation constraints, optimistic locking
--
-- MUST run before the first event row is inserted.
-- ============================================================

-- ------------------------------------------------------------
-- Expanded event and document type lists
-- ------------------------------------------------------------
alter table events drop constraint events_event_type_check;
alter table events add constraint events_event_type_check check (event_type in (
  'load_created','load_assigned','rate_con_received','driver_assigned',
  'truck_assigned','dispatched','arrived_shipper','loading_started',
  'pickup_completed','departed_shipper','fuel_stop','rest_break',
  'break_30_minute','reset_10_hour','escort_confirmed','escort_joined',
  'escort_changed','escort_released','state_entered','weigh_station',
  'port_of_entry','inspection','permit_applied','permit_approved',
  'permit_revision','weather_delay','traffic_delay','road_closure',
  'mechanical_breakdown','repair_completed','accident','hold_started',
  'hold_cleared','check_call','appointment_updated','arrived_receiver',
  'unloading_started','unloading_completed','delivery_completed',
  'pod_uploaded','load_closed','invoice_sent','payment_received',
  'call','email','sms','note','status_change','upload',
  'permit_update','escort_update','appointment','issue','system'));

alter table events add column user_id uuid references app_users(id);
alter table events add column is_manual boolean not null default false;
alter table events add column is_milestone boolean not null default false;
alter table events add column corrects_event_id uuid references events(id);


-- ------------------------------------------------------------
-- HASH CHAIN
-- Each event stores a hash of its own contents plus the
-- previous event's hash. Alter any row and every hash after
-- it stops matching. You cannot quietly backdate a delivery.
-- ------------------------------------------------------------
create sequence events_seq;

alter table events add column seq       bigint;
alter table events add column prev_hash text;
alter table events add column row_hash  text;

create or replace function events_seal()
returns trigger
language plpgsql
as $$
declare v_prev text;
begin
  -- serialize inserts per tenant so the chain cannot fork
  perform pg_advisory_xact_lock(hashtext(new.tenant_id::text));

  select row_hash into v_prev
    from events
   where tenant_id = new.tenant_id
   order by seq desc
   limit 1;

  new.seq       := nextval('events_seq');
  new.prev_hash := coalesce(v_prev, repeat('0', 64));
  new.row_hash  := encode(digest(
      new.prev_hash                        || '|' ||
      new.seq                              || '|' ||
      new.tenant_id                        || '|' ||
      new.entity_type                      || '|' ||
      new.entity_id                        || '|' ||
      new.event_type                       || '|' ||
      coalesce(new.occurred_at::text, '')  || '|' ||
      coalesce(new.subject, '')            || '|' ||
      coalesce(new.body, '')               || '|' ||
      coalesce(new.user_id::text, ''),
    'sha256'), 'hex');

  return new;
end;
$$;

create trigger trg_events_seal before insert on events
for each row execute function events_seal();


-- ------------------------------------------------------------
-- APPEND-ONLY ENFORCEMENT
-- Mistakes are corrected by inserting a new event that points
-- at the wrong one via corrects_event_id. Nobody trusts a
-- ledger with an eraser.
-- ------------------------------------------------------------
create or replace function block_mutation()
returns trigger
language plpgsql
as $$
begin
  raise exception 'Table % is append-only (attempted %)', TG_TABLE_NAME, TG_OP;
end;
$$;

create trigger trg_events_no_update before update on events
for each row execute function block_mutation();

create trigger trg_events_no_delete before delete on events
for each row execute function block_mutation();


-- ------------------------------------------------------------
-- CHAIN VERIFICATION
-- Returns rows only if something has been tampered with.
-- Empty result = intact.
-- ------------------------------------------------------------
create or replace function verify_event_chain(p_tenant uuid)
returns table (broken_at bigint, event_id uuid, occurred_at timestamptz)
language plpgsql
stable
as $$
declare
  r record;
  v_expected text := repeat('0', 64);
  v_calc text;
begin
  for r in select * from events where tenant_id = p_tenant order by seq loop
    v_calc := encode(digest(
      v_expected || '|' || r.seq || '|' || r.tenant_id || '|' || r.entity_type
      || '|' || r.entity_id || '|' || r.event_type
      || '|' || coalesce(r.occurred_at::text,'') || '|' || coalesce(r.subject,'')
      || '|' || coalesce(r.body,'') || '|' || coalesce(r.user_id::text,''),
      'sha256'), 'hex');

    if v_calc <> r.row_hash or r.prev_hash <> v_expected then
      broken_at := r.seq; event_id := r.id; occurred_at := r.occurred_at;
      return next;
    end if;

    v_expected := r.row_hash;
  end loop;
end;
$$;


-- ------------------------------------------------------------
-- SOFT DELETE
-- Nothing is ever destroyed. "Delete" in the UI writes
-- archived_at. DELETE grants are revoked in 010.
-- ------------------------------------------------------------
alter table loads      add column archived_at timestamptz,
                       add column archived_by uuid references app_users(id);
alter table carriers   add column archived_at timestamptz,
                       add column archived_by uuid references app_users(id);
alter table brokers    add column archived_at timestamptz,
                       add column archived_by uuid references app_users(id);
alter table drivers    add column archived_at timestamptz,
                       add column archived_by uuid references app_users(id);
alter table equipment  add column archived_at timestamptz,
                       add column archived_by uuid references app_users(id);
alter table documents  add column archived_at timestamptz,
                       add column archived_by uuid references app_users(id);
alter table facilities add column archived_at timestamptz,
                       add column archived_by uuid references app_users(id);


-- ------------------------------------------------------------
-- DOCUMENT IMMUTABILITY
-- Metadata stays editable. The file and its identity don't.
-- ------------------------------------------------------------
create or replace function documents_immutable()
returns trigger
language plpgsql
as $$
begin
  if new.sha256      is distinct from old.sha256
  or new.storage_key is distinct from old.storage_key
  or new.byte_size   is distinct from old.byte_size then
    raise exception 'Document identity is immutable — upload a new version instead';
  end if;
  return new;
end;
$$;

create trigger trg_documents_immutable before update on documents
for each row execute function documents_immutable();


-- ------------------------------------------------------------
-- STATUS MACHINE
-- Prevents a load that is 'paid' but never 'delivered'.
-- ------------------------------------------------------------
create table load_status_transitions (
  from_status text not null,
  to_status   text not null,
  primary key (from_status, to_status)
);

insert into load_status_transitions (from_status, to_status) values
 ('quoted','booked'),
 ('booked','permits_pending'),  ('booked','dispatched'),
 ('permits_pending','dispatched'),
 ('dispatched','en_route_to_pickup'),
 ('en_route_to_pickup','at_shipper'),
 ('at_shipper','loading'),
 ('loading','loaded'),
 ('loaded','in_transit'),
 ('in_transit','at_weigh_station'), ('at_weigh_station','in_transit'),
 ('in_transit','under_inspection'), ('under_inspection','in_transit'),
 ('in_transit','at_receiver'),
 ('at_receiver','unloading'),
 ('unloading','delivered'),
 ('delivered','pod_pending'), ('delivered','paperwork'),
 ('pod_pending','paperwork'),
 ('paperwork','invoiced'),
 ('invoiced','paid');

create or replace function enforce_status_transition()
returns trigger
language plpgsql
as $$
begin
  if new.status = old.status then return new; end if;

  -- cancellation is always reachable
  if new.status in ('cancelled','tonu') then return new; end if;

  if not exists (
    select 1 from load_status_transitions
     where from_status = old.status and to_status = new.status
  ) then
    -- owners and admins may override; the override is logged
    if coalesce(current_user_role_safe(), 'owner') in ('owner','admin') then
      insert into events (tenant_id, entity_type, entity_id, load_id,
                          event_type, direction, subject, body)
      values (new.tenant_id, 'load', new.id, new.id, 'system', 'internal',
              'Status override',
              old.status || ' → ' || new.status || ' (outside normal workflow)');
      return new;
    end if;
    raise exception 'Invalid status change: % → %', old.status, new.status;
  end if;

  return new;
end;
$$;

-- Placeholder so the trigger works before 010 defines the real
-- role function. 010 replaces this with the RLS-aware version.
create or replace function current_user_role_safe()
returns text
language sql
stable
as $$ select 'owner'::text; $$;

create trigger trg_load_status_machine before update on loads
for each row execute function enforce_status_transition();


-- ------------------------------------------------------------
-- VALIDATION CONSTRAINTS
-- ------------------------------------------------------------
alter table loads add constraint chk_dims check (
  (width_in  is null or width_in  between 1 and 480) and
  (height_in is null or height_in between 1 and 300) and
  (length_in is null or length_in between 1 and 1800) and
  (weight_lb is null or weight_lb between 1 and 2000000));

alter table loads add constraint chk_appt_order check (
  pickup_appt_start is null or delivery_appt_start is null
  or delivery_appt_start >= pickup_appt_start);

alter table loads add constraint chk_actuals check (
  actual_pickup_at is null or actual_delivery_at is null
  or actual_delivery_at >= actual_pickup_at);

alter table loads add constraint chk_hold_pair check (
  (hold_reason is null and hold_since is null)
  or (hold_reason is not null and hold_since is not null));

alter table loads add constraint chk_money check (
  coalesce(linehaul_rate,0) >= 0
  and coalesce(fuel_surcharge,0) >= 0
  and (total_miles is null or total_miles > 0));

alter table permits add constraint chk_permit_window check (
  valid_from is null or valid_to is null or valid_to >= valid_from);

alter table permits add constraint chk_issued_has_number check (
  status <> 'issued' or permit_number is not null);

alter table load_legs add constraint chk_leg_dates check (
  planned_entry_date is null or planned_exit_date is null
  or planned_exit_date >= planned_entry_date);

alter table escort_assignments add constraint chk_escort_window check (
  scheduled_start is null or scheduled_end is null
  or scheduled_end >= scheduled_start);


-- ------------------------------------------------------------
-- OPTIMISTIC LOCKING
-- Two dispatchers editing one load: the stale write is
-- rejected instead of silently overwriting.
-- ------------------------------------------------------------
alter table loads add column lock_version int not null default 0;

create or replace function bump_lock_version()
returns trigger
language plpgsql
as $$
begin
  new.lock_version := old.lock_version + 1;
  return new;
end;
$$;

create trigger trg_loads_lock before update on loads
for each row execute function bump_lock_version();
