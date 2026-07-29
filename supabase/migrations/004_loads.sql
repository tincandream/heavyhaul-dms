-- ============================================================
-- 004_loads.sql
-- Loads, their state-by-state route legs, and the money ledger
-- ============================================================

-- ------------------------------------------------------------
-- LOADS
-- Dimensions are stored in inches and pounds, whole numbers.
-- Decimal feet ("13.5 ft") causes rounding arguments with
-- permit offices — 162 inches is unambiguous.
-- ------------------------------------------------------------
create table loads (
  id                    uuid primary key default gen_random_uuid(),
  tenant_id             uuid not null references tenants(id),
  load_number           text not null,
  broker_load_number    text,

  carrier_id            uuid references carriers(id),
  broker_id             uuid references brokers(id),
  driver_id             uuid references drivers(id),
  tractor_id            uuid references equipment(id),
  trailer_id            uuid references equipment(id),
  origin_facility_id    uuid references facilities(id),
  dest_facility_id      uuid references facilities(id),

  commodity             text,
  commodity_value       numeric(12,2),
  piece_count           int default 1,

  length_in             int,
  width_in              int,
  height_in             int,
  weight_lb             int,
  overhang_front_in     int default 0,
  overhang_rear_in      int default 0,
  axle_count            int,
  axle_spacings         text,
  is_superload          boolean not null default false,
  requires_route_survey boolean not null default false,

  linehaul_rate         numeric(12,2),
  fuel_surcharge        numeric(12,2) default 0,

  pickup_appt_start     timestamptz,
  pickup_appt_end       timestamptz,
  delivery_appt_start   timestamptz,
  delivery_appt_end     timestamptz,
  actual_pickup_at      timestamptz,
  actual_delivery_at    timestamptz,

  status                text not null default 'quoted'
                        check (status in ('quoted','booked','permits_pending',
                                'dispatched','at_pickup','loaded','in_transit',
                                'at_delivery','delivered','paperwork','invoiced',
                                'paid','cancelled','tonu')),
  notes                 text,
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now()
);

create unique index idx_loads_number on loads(tenant_id, load_number);
create index idx_loads_status   on loads(tenant_id, status);
create index idx_loads_carrier  on loads(carrier_id);
create index idx_loads_broker   on loads(broker_id);
create index idx_loads_driver   on loads(driver_id);
create index idx_loads_tractor  on loads(tractor_id);
create index idx_loads_pickup   on loads(tenant_id, pickup_appt_start);
create index idx_loads_delivery on loads(tenant_id, delivery_appt_start);


-- ------------------------------------------------------------
-- LOAD LEGS — one row per state crossed, in travel order.
-- This is the spine of the whole permit system. A Memphis to
-- Denver run is one load but four permits, each with its own
-- number, validity window, and escort requirements.
-- ------------------------------------------------------------
create table load_legs (
  id                 uuid primary key default gen_random_uuid(),
  tenant_id          uuid not null references tenants(id),
  load_id            uuid not null references loads(id) on delete cascade,
  seq                int not null,
  state              char(2) not null,
  entry_point        text,
  exit_point         text,
  miles              int,
  planned_entry_date date,
  planned_exit_date  date,
  actual_entry_at    timestamptz,
  notes              text,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now()
);
create unique index idx_legs_seq on load_legs(load_id, seq);
create index idx_legs_state on load_legs(tenant_id, state);
create index idx_legs_load  on load_legs(load_id);


-- ------------------------------------------------------------
-- LOAD CHARGES — revenue and cost in one ledger.
-- Adding a new accessorial type never needs a schema change,
-- and margin becomes a single sum instead of a dozen columns.
-- ------------------------------------------------------------
create table load_charges (
  id           uuid primary key default gen_random_uuid(),
  tenant_id    uuid not null references tenants(id),
  load_id      uuid not null references loads(id) on delete cascade,
  kind         text not null check (kind in ('revenue','cost')),
  category     text not null
               check (category in ('linehaul','fuel','detention','layover','tarp',
                       'permit_fee','permit_service_fee','escort','pilot_car',
                       'police','driver_pay','fuel_purchase','tolls','lumper',
                       'repair','other')),
  description  text,
  amount       numeric(12,2) not null,
  billable     boolean not null default true,
  incurred_on  date default current_date,
  created_at   timestamptz not null default now()
);
create index idx_charges_load on load_charges(load_id);
create index idx_charges_tenant on load_charges(tenant_id);


-- ------------------------------------------------------------
-- updated_at triggers
-- ------------------------------------------------------------
create trigger trg_loads_updated before update on loads
for each row execute function set_updated_at();

create trigger trg_load_legs_updated before update on load_legs
for each row execute function set_updated_at();
