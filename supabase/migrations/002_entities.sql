-- ============================================================
-- 001_foundation.sql
-- Heavy Haul Dispatch Management System
-- Extensions, tenancy root, shared trigger function
-- ============================================================

-- gen_random_uuid() and digest() for the event hash chain
create extension if not exists pgcrypto;

-- fuzzy text matching for global search
create extension if not exists pg_trgm;


-- ------------------------------------------------------------
-- Tenancy root. Every table carries tenant_id so RLS policies
-- can use one shared pattern.
-- ------------------------------------------------------------
create table tenants (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  created_at  timestamptz not null default now()
);


-- ------------------------------------------------------------
-- Shared trigger function. Attached to every table that has an
-- updated_at column, at the end of each migration.
-- ------------------------------------------------------------
create or replace function set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;


-- ------------------------------------------------------------
-- Create your dispatch company. Change the name if you like.
-- ------------------------------------------------------------
insert into tenants (name) values ('Tin Can Dream Dispatch');
