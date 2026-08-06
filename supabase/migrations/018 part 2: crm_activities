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
