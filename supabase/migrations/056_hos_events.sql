-- ============================================================
-- 056_hos_events.sql
-- HEAVY HAUL COMMAND
-- Dispatcher HOS Event Tracker
-- ============================================================
--
-- PURPOSE
-- Stores dispatcher-side HOS events for each load.
--
-- This does NOT replace:
--   - the driver's ELD
--   - load_calculations
--   - the existing HOS calculator
--
-- It gives Workspace a persistent HOS event history so it can
-- track baseline hours, updates, breaks, and off-duty periods.
-- ============================================================


-- ============================================================
-- 1. HOS EVENTS TABLE
-- ============================================================

create table if not exists public.hos_events (

    id uuid primary key
        default gen_random_uuid(),

    tenant_id uuid not null,

    load_id uuid not null
        references public.loads(id)
        on delete cascade,

    -- Type of HOS event being recorded.
    event_type text not null
        check (
            event_type in (
                'baseline',
                'hours_update',
                'break_completed',
                'off_duty',
                'back_on_duty'
            )
        ),

    -- Time the HOS event actually occurred.
    occurred_at timestamptz not null
        default now(),

    -- ========================================================
    -- DRIVER / ELD REPORTED VALUES
    -- ========================================================

    drive_remaining_hours numeric(6,2),

    window_remaining_hours numeric(6,2),

    cycle_remaining_hours numeric(6,2),

    driving_since_break_hours numeric(6,2),

    -- ========================================================
    -- BREAK / REST INFORMATION
    -- ========================================================

    -- Length of a completed qualifying break.
    break_minutes integer,

    -- Length of an off-duty/rest period when applicable.
    off_duty_minutes integer,

    -- Dispatcher notes.
    note text,

    created_at timestamptz not null
        default now()
);


-- ============================================================
-- 2. INDEXES
-- ============================================================

-- Fast lookup of a load's HOS history.
create index if not exists
    hos_events_load_time_idx
on public.hos_events (
    load_id,
    occurred_at desc
);


-- Fast tenant filtering.
create index if not exists
    hos_events_tenant_idx
on public.hos_events (
    tenant_id
);


-- ============================================================
-- 3. ROW LEVEL SECURITY
-- ============================================================

alter table public.hos_events
enable row level security;


-- Make this section safe if the migration is accidentally
-- executed again.

drop policy if exists
    "hos_events_tenant_access"
on public.hos_events;


create policy
    "hos_events_tenant_access"
on public.hos_events
for all
using (
    tenant_id = public.current_tenant_id()
)
with check (
    tenant_id = public.current_tenant_id()
);


-- ============================================================
-- END 056_hos_events.sql
-- ============================================================
