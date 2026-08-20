-- ============================================================
-- 055_load_email_sources.sql
-- HEAVY HAUL COMMAND
-- SOURCING — LOAD EMAIL SOURCES
-- ============================================================

create table if not exists public.load_email_sources (

  id uuid primary key default gen_random_uuid(),

  tenant_id uuid not null,

  broker_name text not null,

  email_address text,

  frequency text
    check (
      frequency is null
      or frequency in (
        'Multiple Daily',
        'Daily',
        'Weekdays',
        'Weekly',
        'Occasional'
      )
    ),

  status text not null default 'active'
    check (
      status in (
        'active',
        'watch',
        'inactive'
      )
    ),

  freight_lanes text,

  last_received_at timestamptz,

  portal_url text,

  notes text,

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
  idx_load_email_sources_tenant
on public.load_email_sources (
  tenant_id
);


create index if not exists
  idx_load_email_sources_status
on public.load_email_sources (
  tenant_id,
  status
);


create index if not exists
  idx_load_email_sources_broker
on public.load_email_sources (
  tenant_id,
  broker_name
);


-- ============================================================
-- UPDATED_AT TRIGGER FUNCTION
-- ============================================================

create or replace function public.set_load_email_sources_updated_at()
returns trigger
language plpgsql
as $$
begin

  new.updated_at = now();

  return new;

end;
$$;


drop trigger if exists
  trg_load_email_sources_updated_at
on public.load_email_sources;


create trigger trg_load_email_sources_updated_at

before update
on public.load_email_sources

for each row

execute function
  public.set_load_email_sources_updated_at();


-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

alter table public.load_email_sources
enable row level security;


-- ------------------------------------------------------------
-- SELECT
-- ------------------------------------------------------------

drop policy if exists
  "load_email_sources_select"
on public.load_email_sources;


create policy
  "load_email_sources_select"

on public.load_email_sources

for select

to authenticated

using (

  tenant_id in (

    select au.tenant_id

    from public.app_users au

    where
      au.auth_uid = auth.uid()

  )

);


-- ------------------------------------------------------------
-- INSERT
-- ------------------------------------------------------------

drop policy if exists
  "load_email_sources_insert"
on public.load_email_sources;


create policy
  "load_email_sources_insert"

on public.load_email_sources

for insert

to authenticated

with check (

  tenant_id in (

    select au.tenant_id

    from public.app_users au

    where
      au.auth_uid = auth.uid()

  )

);


-- ------------------------------------------------------------
-- UPDATE
-- ------------------------------------------------------------

drop policy if exists
  "load_email_sources_update"
on public.load_email_sources;


create policy
  "load_email_sources_update"

on public.load_email_sources

for update

to authenticated

using (

  tenant_id in (

    select au.tenant_id

    from public.app_users au

    where
      au.auth_uid = auth.uid()

  )

)

with check (

  tenant_id in (

    select au.tenant_id

    from public.app_users au

    where
      au.auth_uid = auth.uid()

  )

);


-- ------------------------------------------------------------
-- DELETE
-- ------------------------------------------------------------

drop policy if exists
  "load_email_sources_delete"
on public.load_email_sources;


create policy
  "load_email_sources_delete"

on public.load_email_sources

for delete

to authenticated

using (

  tenant_id in (

    select au.tenant_id

    from public.app_users au

    where
      au.auth_uid = auth.uid()

  )

);


-- ============================================================
-- GRANTS
-- ============================================================

grant select, insert, update, delete
on public.load_email_sources
to authenticated;


-- ============================================================
-- VERIFY
-- ============================================================

select
  column_name,
  data_type

from information_schema.columns

where
  table_schema = 'public'
  and table_name = 'load_email_sources'

order by ordinal_position;
