-- 018_load_board.sql  (part 1: load_opportunities)
create table if not exists load_opportunities (
  id                 uuid primary key default gen_random_uuid(),
  tenant_id          uuid not null,
  company_id         uuid references companies(id) on delete set null,
  contact_id         uuid references company_contacts(id) on delete set null,
  source_type        text not null default 'phone'
                     check (source_type in ('email','portal','phone','text','referral',
                                            'repeat_lane','walk_in','other')),
  external_ref       text,

  origin_city text, origin_state text,
  dest_city   text, dest_state   text,
  pickup_date date,
  delivery_date date,
  miles       int,

  commodity          text,
  equipment_needed   text,
  length_ft numeric(6,2), width_ft numeric(6,2), height_ft numeric(6,2),
  weight_lbs         int,
  is_oversize        boolean default false,
  is_overweight      boolean default false,
  is_superload       boolean default false,

  posted_rate        numeric(10,2),
  quoted_rate        numeric(10,2),
  booked_rate        numeric(10,2),

  status             text not null default 'new'
                     check (status in ('new','reviewing','quoted','negotiating',
                                       'booked','lost','expired','declined')),
  lost_reason        text,
  load_id            uuid,
  first_seen_at      timestamptz default now(),
  closed_at          timestamptz,
  notes              text
);

create index if not exists idx_opp_tenant  on load_opportunities (tenant_id);
create index if not exists idx_opp_status   on load_opportunities (status, pickup_date);
create index if not exists idx_opp_company  on load_opportunities (company_id);

-- 018 part 2: crm_activities
create table if not exists crm_activities (
  id              uuid primary key default gen_random_uuid(),
  tenant_id       uuid not null,
  company_id      uuid not null references companies(id) on delete cascade,
  contact_id      uuid references company_contacts(id) on delete set null,
  activity_type   text not null default 'call'
                  check (activity_type in ('call','voicemail','email','text','meeting',
                                           'packet_sent','quote','follow_up')),
  direction       text check (direction in ('outbound','inbound')),
  outcome         text check (outcome in ('connected','no_answer','voicemail','gatekeeper',
                    'not_interested','callback_requested','info_sent','load_offered',
                    'booked','bad_number')),
  subject         text,
  body            text,
  next_action     text,
  next_action_due date,
  occurred_at     timestamptz default now(),
  created_at      timestamptz default now()
);

create index if not exists idx_crmact_tenant  on crm_activities (tenant_id);
create index if not exists idx_crmact_company on crm_activities (company_id, occurred_at desc);
create index if not exists idx_crmact_due     on crm_activities (next_action_due)
  where next_action_due is not null;

-- 018 part 3: RLS, auto-touch trigger, call queue view

-- ===== RLS on both new tables =====
alter table load_opportunities enable row level security;
alter table crm_activities     enable row level security;

create policy tenant_read on load_opportunities
  for select using (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']));
create policy tenant_insert on load_opportunities
  for insert with check (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']));
create policy tenant_update on load_opportunities
  for update using (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']))
  with check (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']));
create policy tenant_delete on load_opportunities
  for delete using (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']));

create policy tenant_read on crm_activities
  for select using (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']));
create policy tenant_insert on crm_activities
  for insert with check (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']));
create policy tenant_update on crm_activities
  for update using (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']))
  with check (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']));
create policy tenant_delete on crm_activities
  for delete using (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']));

-- ===== auto-touch: logging an activity updates the company's contact timing =====
create or replace function fn_touch_company() returns trigger as $$
begin
  update companies
     set last_contacted_at = new.occurred_at,
         next_touch_date   = coalesce(
           new.next_action_due,
           (new.occurred_at + (coalesce(follow_up_days,14) || ' days')::interval)::date),
         updated_at = now()
   where id = new.company_id;

  if new.contact_id is not null then
    update company_contacts
       set last_contacted_at = new.occurred_at
     where id = new.contact_id;
  end if;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_touch_company on crm_activities;
create trigger trg_touch_company
  after insert on crm_activities
  for each row execute function fn_touch_company();

-- ===== the call queue view =====
create or replace view v_call_queue as
select
  c.id            as company_id,
  c.legal_name,
  c.company_type,
  c.status,
  c.tier,
  c.main_phone,
  c.next_touch_date,
  c.last_contacted_at,
  c.sends_direct_freight,
  ct.id           as contact_id,
  ct.first_name,
  ct.last_name,
  coalesce(ct.direct_phone, ct.mobile, c.main_phone) as dial,
  ct.best_time_to_call
from companies c
left join company_contacts ct
       on ct.company_id = c.id and ct.is_primary and not ct.do_not_contact
where c.status not in ('do_not_use','on_hold')
  and (c.next_touch_date is null or c.next_touch_date <= current_date)
order by
  case c.status
    when 'pending_approval' then 1
    when 'packet_sent'      then 2
    when 'contacted'        then 3
    else 4
  end,
  c.next_touch_date nulls first;


