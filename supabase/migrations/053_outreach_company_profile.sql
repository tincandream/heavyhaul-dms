-- ============================================================
-- 053_outreach_company_profile.sql
-- Adds missing company/contact profile fields used by the
-- expanded Call Queue / Outreach CRM.
-- Safe additive migration.
-- ============================================================

alter table public.companies
  add column if not exists address_line1 text,
  add column if not exists postal_code text;

alter table public.company_contacts
  add column if not exists contact_role text,
  add column if not exists email text;

create index if not exists idx_company_contacts_company_primary
  on public.company_contacts (company_id, is_primary);

create index if not exists idx_crm_activities_company_history
  on public.crm_activities (company_id, occurred_at desc);
