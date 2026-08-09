-- ============================================================
-- 035_sourcing_events.sql
-- Heavy Haul Command
--
-- Structured sourcing activity for the Welcome-page
-- Sourcing Timeline.
--
-- Safe to rerun.
-- ============================================================

create extension if not exists pgcrypto;


-- ============================================================
-- 1. SOURCING EVENTS TABLE
-- ============================================================

create table if not exists public.sourcing_events (

  id uuid primary key default gen_random_uuid(),

  tenant_id uuid not null
    references public.tenants(id)
    on delete cascade,

  load_id uuid
    references public.loads(id)
    on delete set null,

  opportunity_id uuid,

  event_type text not null,

  title text not null,

  detail text,

  broker_name text,

  carrier_name text,

  contact_name text,

  lane_origin text,

  lane_destination text,

  rate_amount numeric,

  follow_up_at timestamptz,

  created_by uuid
    references public.app_users(id),

  created_at timestamptz not null default now()

);


-- ============================================================
-- 2. EVENT TYPE CONSTRAINT
-- ============================================================

alter table public.sourcing_events
  drop constraint if exists sourcing_events_event_type_check;

alter table public.sourcing_events
  add constraint sourcing_events_event_type_check
  check (
    event_type in (
      'opportunity_added',
      'opportunity_reviewed',
      'broker_contacted',
      'carrier_contacted',
      'follow_up_scheduled',
      'quote_prepared',
      'quote_sent',
      'rate_negotiated',
      'load_booked',
      'load_passed',
      'load_rejected',
      'lane_reviewed',
      'email_received',
      'email_processed',
      'call_completed',
      'note'
    )
  );


-- ============================================================
-- 3. INDEXES
-- ============================================================

create index if not exists sourcing_events_tenant_created_idx
  on public.sourcing_events (tenant_id, created_at desc);

create index if not exists sourcing_events_load_idx
  on public.sourcing_events (load_id);

create index if not exists sourcing_events_type_idx
  on public.sourcing_events (tenant_id, event_type);

create index if not exists sourcing_events_followup_idx
  on public.sourcing_events (tenant_id, follow_up_at);


-- ============================================================
-- 4. ROW LEVEL SECURITY
-- ============================================================

alter table public.sourcing_events
  enable row level security;

drop policy if exists sourcing_events_tenant_access
  on public.sourcing_events;

create policy sourcing_events_tenant_access
on public.sourcing_events
for all
using (
  exists (
    select 1
    from public.app_users au
    where au.auth_uid = auth.uid()
      and au.tenant_id = sourcing_events.tenant_id
  )
)
with check (
  exists (
    select 1
    from public.app_users au
    where au.auth_uid = auth.uid()
      and au.tenant_id = sourcing_events.tenant_id
  )
);


-- ============================================================
-- 5. VERIFICATION
-- ============================================================

select
  column_name,
  data_type
from information_schema.columns
where table_schema = 'public'
  and table_name = 'sourcing_events'
order by ordinal_position;


select
  conname as constraint_name,
  pg_get_constraintdef(oid) as definition
from pg_constraint
where conrelid = 'public.sourcing_events'::regclass
order by conname;
