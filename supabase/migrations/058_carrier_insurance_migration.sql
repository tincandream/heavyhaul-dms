-- 058_carrier_insurance_migration.sql

alter table public.carrier_profiles
  add column if not exists insurance_company text,
  add column if not exists insurance_policy_number text,
  add column if not exists auto_liability_limit numeric(14,2),
  add column if not exists cargo_limit numeric(14,2),
  add column if not exists general_liability_limit numeric(14,2),
  add column if not exists insurance_effective_date date,
  add column if not exists insurance_expiration_date date,
  add column if not exists coi_on_file boolean,
  add column if not exists insurance_notes text;

create index if not exists idx_carrier_profiles_insurance_expiration
  on public.carrier_profiles (insurance_expiration_date);
