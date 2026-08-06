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


