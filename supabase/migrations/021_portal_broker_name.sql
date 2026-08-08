-- 021_portal_broker_name.sql
alter table broker_portals
  add column if not exists broker_name text,
  alter column company_id drop not null;
