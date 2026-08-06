-- 017_crm_core.sql
-- The spine of the load board: who you work with, and who to call.

-- ============ COMPANIES (brokers + carriers) ============
create table if not exists companies (
  id                uuid primary key default gen_random_uuid(),
  tenant_id         uuid not null,
  company_type      text not null default 'broker'
                    check (company_type in ('broker','carrier','shipper','both')),
  legal_name        text not null,
  dba_name          text,
  mc_number         text,
  dot_number        text,
  main_phone        text,
  main_email        text,
  website           text,
  city              text,
  state             text,

  -- pipeline
  status            text not null default 'lead'
                    check (status in ('lead','contacted','packet_sent','pending_approval',
                                      'active','on_hold','do_not_use')),
  tier              text check (tier in ('A','B','C')),
  source            text,

  -- the load-board flags that matter
  sends_direct_freight  boolean default false,
  sends_load_emails     boolean default false,
  has_portal            boolean default false,

  -- cadence
  follow_up_days    int default 14,
  last_contacted_at timestamptz,
  next_touch_date   date,

  notes             text,
  created_at        timestamptz default now(),
  updated_at        timestamptz default now()
);

create index if not exists idx_companies_tenant  on companies (tenant_id);
create index if not exists idx_companies_status  on companies (status);
create index if not exists idx_companies_type    on companies (company_type);
create index if not exists idx_companies_touch   on companies (next_touch_date);

-- ============ COMPANY CONTACTS ============
create table if not exists company_contacts (
  id                uuid primary key default gen_random_uuid(),
  tenant_id         uuid not null,
  company_id        uuid not null references companies(id) on delete cascade,
  first_name        text not null,
  last_name         text,
  title             text,
  role              text check (role in ('dispatch','sales','ops','accounting','permits',
                                         'safety','owner','after_hours','other')),
  direct_phone      text,
  mobile            text,
  email             text,
  best_time_to_call text,
  is_primary        boolean default false,
  do_not_contact    boolean default false,
  personal_notes    text,
  last_contacted_at timestamptz,
  created_at        timestamptz default now()
);

create index if not exists idx_contacts_tenant  on company_contacts (tenant_id);
create index if not exists idx_contacts_company on company_contacts (company_id);

-- ============ RLS ============
alter table companies        enable row level security;
alter table company_contacts enable row level security;

-- companies
create policy tenant_read on companies
  for select using (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']));
create policy tenant_insert on companies
  for insert with check (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']));
create policy tenant_update on companies
  for update using (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']))
  with check (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']));
create policy tenant_delete on companies
  for delete using (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']));

-- company_contacts
create policy tenant_read on company_contacts
  for select using (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']));
create policy tenant_insert on company_contacts
  for insert with check (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']));
create policy tenant_update on company_contacts
  for update using (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']))
  with check (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']));
create policy tenant_delete on company_contacts
  for delete using (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']));
