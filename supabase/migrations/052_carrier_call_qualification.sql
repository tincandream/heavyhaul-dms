052_carrier_call_qualification.sql
Code
call-queue-carrier-qualification.html
HTML
im on 051 in supabase.

Got it — then do not use 031. We need to keep your migration numbering in sequence.

Since you’re currently on 051, this carrier-call migration should be 052.

The SQL content itself is still fine; only the filename/sequence number needs to change:

052_carrier_call_qualification.sql

So your order becomes:

051_...
052_carrier_call_qualification.sql

You can either rename the file before committing it, or just create a new migration file named 052_carrier_call_qualification.sql and paste the SQL into that.

After you run 052 in Supabase and it succeeds, then update call-queue.html.

Download the SQL as 052

Just rename that downloaded file to:

052_carrier_call_qualification.sql

Then run it in Supabase.

031_carrier_call_qualification.sql
Code

© Mapbox Terms© OpenStreetMap
Library
/
031_carrier_call_qualification.sql
-- ============================================================
-- 031_carrier_call_qualification.sql
-- Adds carrier qualification fields to CRM call history.
-- Safe additive migration: no existing columns are deleted or renamed.
-- ============================================================

alter table public.crm_activities
  add column if not exists contact_role text,
  add column if not exists equipment text,
  add column if not exists fleet_size integer,
  add column if not exists trucks_needing_support integer,
  add column if not exists preferred_lanes text,
  add column if not exists preferred_freight text,
  add column if not exists freight_sources text[] not null default '{}'::text[],
  add column if not exists has_direct_customers boolean,
  add column if not exists has_dedicated_freight boolean,
  add column if not exists independent_dispatch_use text,
  add column if not exists dispatch_need text;

alter table public.crm_activities
  drop constraint if exists crm_activities_fleet_size_check;

alter table public.crm_activities
  add constraint crm_activities_fleet_size_check
  check (fleet_size is null or fleet_size >= 0);

alter table public.crm_activities
  drop constraint if exists crm_activities_trucks_needing_support_check;

alter table public.crm_activities
  add constraint crm_activities_trucks_needing_support_check
  check (trucks_needing_support is null or trucks_needing_support >= 0);

create index if not exists idx_crm_activities_company_occurred
  on public.crm_activities (company_id, occurred_at desc);

create index if not exists idx_crm_activities_carrier_dispatch
  on public.crm_activities (tenant_id, independent_dispatch_use)
  where independent_dispatch_use is not null;
