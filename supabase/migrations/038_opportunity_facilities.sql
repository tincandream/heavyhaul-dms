-- ============================================================
-- 038_opportunity_facilities.sql
-- Pickup and delivery facility details live directly on the
-- broker-load opportunity.
-- Safe to rerun.
-- ============================================================

alter table public.load_opportunities
  add column if not exists pickup_facility_name text,
  add column if not exists pickup_address text,
  add column if not exists pickup_zip text,
  add column if not exists pickup_contact_name text,
  add column if not exists pickup_phone text,
  add column if not exists pickup_hours text,
  add column if not exists pickup_instructions text,
  add column if not exists delivery_facility_name text,
  add column if not exists delivery_date date,
  add column if not exists delivery_address text,
  add column if not exists delivery_zip text,
  add column if not exists delivery_contact_name text,
  add column if not exists delivery_phone text,
  add column if not exists delivery_hours text,
  add column if not exists delivery_instructions text;

select column_name, data_type
from information_schema.columns
where table_schema='public'
  and table_name='load_opportunities'
  and column_name in (
    'pickup_facility_name','pickup_address','pickup_zip',
    'pickup_contact_name','pickup_phone','pickup_hours','pickup_instructions',
    'delivery_facility_name','delivery_date','delivery_address','delivery_zip',
    'delivery_contact_name','delivery_phone','delivery_hours','delivery_instructions'
  )
order by column_name;
