-- ============================================================
-- 034_calendar_events.sql
-- Heavy Haul Command
--
-- Manual calendar events / reminders.
-- Auto-generated calendar items (pickup, delivery, permits,
-- escorts, etc.) continue to come from their source tables.
--
-- Safe to rerun.
-- ============================================================


create extension if not exists pgcrypto;


-- ============================================================
-- 1. CALENDAR EVENTS TABLE
-- ============================================================

create table if not exists public.calendar_events (

  id uuid primary key default gen_random_uuid(),

  tenant_id uuid not null
    references public.tenants(id)
    on delete cascade,

  load_id uuid
    references public.loads(id)
    on delete cascade,

  title text not null,

  event_type text not null default 'custom',

  starts_at timestamptz not null,

  ends_at timestamptz,

  all_day boolean not null default false,

  notes text,

  completed boolean not null default false,

  completed_at timestamptz,

  created_by uuid
    references public.app_users(id),

  created_at timestamptz not null default now(),

  updated_at timestamptz not null default now()

);


-- ============================================================
-- 2. EVENT TYPE CONSTRAINT
-- ============================================================

alter table public.calendar_events
  drop constraint if exists calendar_events_event_type_check;

alter table public.calendar_events
  add constraint calendar_events_event_type_check
  check (
    event_type in (
      'custom',
      'followup',
      'accessorial',
      'invoice',
      'payment',
      'pickup',
      'delivery',
      'permit',
      'escort',
      'broker_call',
      'carrier_call',
      'driver_call',
      'document',
      'sourcing'
    )
  );


-- ============================================================
-- 3. DATE PAIR / COMPLETION CHECKS
-- ============================================================

alter table public.calendar_events
  drop constraint if exists calendar_events_end_after_start_check;

alter table public.calendar_events
  add constraint calendar_events_end_after_start_check
  check (
    ends_at is null
    or ends_at >= starts_at
  );


alter table public.calendar_events
  drop constraint if exists calendar_events_completed_pair_check;

alter table public.calendar_events
  add constraint calendar_events_completed_pair_check
  check (
    (completed = false and completed_at is null)
    or
    (completed = true)
  );


-- ============================================================
-- 4. INDEXES
-- ============================================================

create index if not exists calendar_events_tenant_idx
  on public.calendar_events (tenant_id);

create index if not exists calendar_events_start_idx
  on public.calendar_events (tenant_id, starts_at);

create index if not exists calendar_events_load_idx
  on public.calendar_events (load_id);

create index if not exists calendar_events_type_idx
  on public.calendar_events (tenant_id, event_type);

create index if not exists calendar_events_open_idx
  on public.calendar_events (tenant_id, completed, starts_at);


-- ============================================================
-- 5. UPDATED_AT TRIGGER
-- ============================================================

create or replace function public.calendar_events_set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;


drop trigger if exists calendar_events_set_updated_at
  on public.calendar_events;

create trigger calendar_events_set_updated_at
before update on public.calendar_events
for each row
execute function public.calendar_events_set_updated_at();


-- ============================================================
-- 6. AUTO-SET COMPLETED_AT
-- ============================================================

create or replace function public.calendar_events_set_completed_at()
returns trigger
language plpgsql
as $$
begin

  if new.completed = true
     and old.completed = false
     and new.completed_at is null then

    new.completed_at = now();

  end if;


  if new.completed = false then

    new.completed_at = null;

  end if;


  return new;

end;
$$;


drop trigger if exists calendar_events_set_completed_at
  on public.calendar_events;

create trigger calendar_events_set_completed_at
before update on public.calendar_events
for each row
execute function public.calendar_events_set_completed_at();


-- ============================================================
-- 7. ROW LEVEL SECURITY
-- ============================================================

alter table public.calendar_events
  enable row level security;


drop policy if exists calendar_events_tenant_access
  on public.calendar_events;


create policy calendar_events_tenant_access
on public.calendar_events
for all
using (
  exists (
    select 1
    from public.app_users au
    where au.auth_uid = auth.uid()
      and au.tenant_id = calendar_events.tenant_id
  )
)
with check (
  exists (
    select 1
    from public.app_users au
    where au.auth_uid = auth.uid()
      and au.tenant_id = calendar_events.tenant_id
  )
);


-- ============================================================
-- 8. VERIFICATION
-- ============================================================

select
  column_name,
  data_type
from information_schema.columns
where table_schema = 'public'
  and table_name = 'calendar_events'
order by ordinal_position;


select
  conname as constraint_name,
  pg_get_constraintdef(oid) as definition
from pg_constraint
where conrelid = 'public.calendar_events'::regclass
order by conname;
