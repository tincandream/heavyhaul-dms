-- ============================================================
-- 028_accessorials.sql
-- Heavy Haul Command
-- Load Accessorials / Detention Tracking
-- ============================================================

create extension if not exists pgcrypto;


-- ============================================================
-- ACCESSORIALS
--
-- Tracks additional load-related charges:
-- detention, layover, TONU, lumper, driver assist,
-- extra stop, redelivery, storage, permits/escorts,
-- and other charges.
-- ============================================================

create table if not exists public.accessorials (

  id uuid
    primary key
    default gen_random_uuid(),

  tenant_id uuid
    not null,

  load_id uuid
    not null,

  accessorial_type text
    not null,

  status text
    not null
    default 'pending',

  location_type text,

  facility_name text,

  description text,


  -- ==========================================================
  -- DETENTION / TIME INFORMATION
  -- ==========================================================

  appointment_at timestamptz,

  arrived_at timestamptz,

  checked_in_at timestamptz,

  service_started_at timestamptz,

  released_at timestamptz,

  free_minutes integer
    default 120,

  total_minutes integer,

  billable_minutes integer,


  -- ==========================================================
  -- CHARGE INFORMATION
  -- ==========================================================

  rate_type text
    default 'hourly',

  rate_amount numeric(12,2),

  quantity numeric(12,2),

  requested_amount numeric(12,2),

  approved_amount numeric(12,2),

  paid_amount numeric(12,2),


  -- ==========================================================
  -- BROKER / CUSTOMER COMMUNICATION
  -- ==========================================================

  notification_required boolean
    default false,

  broker_notified_at timestamptz,

  notified_contact text,

  approval_reference text,

  denial_reason text,


  -- ==========================================================
  -- DOCUMENTATION
  -- ==========================================================

  bol_documented boolean
    default false,

  pod_documented boolean
    default false,

  rate_confirmation_documented boolean
    default false,

  facility_times_documented boolean
    default false,

  communication_documented boolean
    default false,

  supporting_notes text,


  -- ==========================================================
  -- PAYMENT / BILLING
  -- ==========================================================

  invoice_number text,

  invoiced_at timestamptz,

  approved_at timestamptz,

  paid_at timestamptz,


  created_at timestamptz
    not null
    default now(),

  updated_at timestamptz
    not null
    default now()

);


-- ============================================================
-- INDEXES
-- ============================================================

create index if not exists
  accessorials_tenant_idx

on public.accessorials (
  tenant_id
);


create index if not exists
  accessorials_load_idx

on public.accessorials (
  load_id
);


create index if not exists
  accessorials_status_idx

on public.accessorials (
  tenant_id,
  status
);


create index if not exists
  accessorials_type_idx

on public.accessorials (
  tenant_id,
  accessorial_type
);



-- ============================================================
-- UPDATED_AT TRIGGER
-- Uses the function we already created in migration 026.
-- ============================================================

drop trigger if exists
  accessorials_set_updated_at

on public.accessorials;


create trigger
  accessorials_set_updated_at

before update
on public.accessorials

for each row

execute function
  public.heavyhaul_set_updated_at();



-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

alter table
  public.accessorials
enable row level security;



-- ============================================================
-- TENANT SECURITY POLICY
-- ============================================================

drop policy if exists
  accessorials_tenant_access

on public.accessorials;


create policy
  accessorials_tenant_access

on public.accessorials

for all

using (

  exists (

    select 1

    from public.app_users au

    where
      au.auth_uid = auth.uid()

      and
      au.tenant_id =
        accessorials.tenant_id

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
        accessorials.tenant_id

  )

);



-- ============================================================
-- VERIFICATION
-- ============================================================

select count(*)
from public.accessorials;
