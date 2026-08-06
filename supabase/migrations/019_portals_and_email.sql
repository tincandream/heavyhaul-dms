-- 019 part 1: broker_portals
create table if not exists broker_portals (
  id                 uuid primary key default gen_random_uuid(),
  tenant_id          uuid not null,
  company_id         uuid not null references companies(id) on delete cascade,
  portal_name        text not null,
  portal_url         text not null,
  platform           text,
  username           text,
  credential_ref     text,      -- pointer to your password manager, NEVER the password
  access_status      text default 'pending'
                     check (access_status in ('pending','active','locked','expired','revoked')),
  posts_oversize     boolean default false,
  check_frequency    text default 'daily'
                     check (check_frequency in ('hourly','twice_daily','daily','weekly','as_needed')),
  best_check_time    text,
  last_checked_at    timestamptz,
  next_check_at      timestamptz,
  loads_found_count  int default 0,
  usefulness_score   int check (usefulness_score between 1 and 5),
  notes              text,
  created_at         timestamptz default now()
);

create index if not exists idx_portals_tenant on broker_portals (tenant_id);
create index if not exists idx_portals_next   on broker_portals (next_check_at);
create index if not exists idx_portals_status on broker_portals (access_status);


-- 019 part 2: load_email_feeds
create table if not exists load_email_feeds (
  id                  uuid primary key default gen_random_uuid(),
  tenant_id           uuid not null,
  company_id          uuid references companies(id) on delete cascade,
  feed_name           text not null,
  sender_email        text,
  sender_domain       text,
  subscription_status text default 'active'
                      check (subscription_status in ('active','paused','unsubscribed','bouncing')),
  typical_send_time   time,
  frequency           text,
  contains_oversize   boolean default false,
  format              text check (format in ('html_table','plain_text','pdf_attachment',
                                             'csv_attachment','spreadsheet_link','mixed')),
  gmail_label         text,      -- the filter/label you route it to
  parse_notes         text,      -- where the equipment/dims columns live
  avg_loads_per_email int,
  last_received_at    timestamptz,
  created_at          timestamptz default now()
);

create index if not exists idx_feeds_tenant on load_email_feeds (tenant_id);
create index if not exists idx_feeds_company on load_email_feeds (company_id);


-- 019 part 3: load_email_receipts
create table if not exists load_email_receipts (
  id              uuid primary key default gen_random_uuid(),
  tenant_id       uuid not null,
  feed_id         uuid not null references load_email_feeds(id) on delete cascade,
  company_id      uuid references companies(id) on delete cascade,
  received_at     timestamptz not null default now(),
  subject         text,
  loads_listed    int,
  oversize_count  int,
  reviewed        boolean default false,
  reviewed_at     timestamptz,
  notes           text
);

create index if not exists idx_receipts_tenant on load_email_receipts (tenant_id);
create index if not exists idx_receipts_feed    on load_email_receipts (feed_id);
create index if not exists idx_receipts_unrev   on load_email_receipts (reviewed)
  where not reviewed;


  -- 019 part 4: RLS for broker_portals, load_email_feeds, load_email_receipts
alter table broker_portals        enable row level security;
alter table load_email_feeds      enable row level security;
alter table load_email_receipts   enable row level security;

-- broker_portals
create policy tenant_read on broker_portals
  for select using (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']));
create policy tenant_insert on broker_portals
  for insert with check (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']));
create policy tenant_update on broker_portals
  for update using (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']))
  with check (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']));
create policy tenant_delete on broker_portals
  for delete using (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']));

-- load_email_feeds
create policy tenant_read on load_email_feeds
  for select using (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']));
create policy tenant_insert on load_email_feeds
  for insert with check (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']));
create policy tenant_update on load_email_feeds
  for update using (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']))
  with check (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']));
create policy tenant_delete on load_email_feeds
  for delete using (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']));

-- load_email_receipts
create policy tenant_read on load_email_receipts
  for select using (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']));
create policy tenant_insert on load_email_receipts
  for insert with check (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']));
create policy tenant_update on load_email_receipts
  for update using (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']))
  with check (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']));
create policy tenant_delete on load_email_receipts
  for delete using (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']));
