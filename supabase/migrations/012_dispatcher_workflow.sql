-- ============================================================
-- 012_dispatcher_workflow.sql
-- Fields and structures drawn from the dispatch manual:
-- carrier preferences, permit/escort ownership contacts,
-- accessorial terms, and the compliance checklist
-- ============================================================

-- ------------------------------------------------------------
-- CARRIER PREFERENCES
-- From the onboarding scripts. These drive load screening —
-- without them you are checking a paper note every time.
-- ------------------------------------------------------------
alter table carriers add column min_load_revenue numeric(10,2);
alter table carriers add column target_rate_per_mile numeric(6,2);
alter table carriers add column max_width_in int;
alter table carriers add column max_height_in int;
alter table carriers add column max_weight_lb int;
alter table carriers add column trailer_capacity_tons int;
alter table carriers add column freight_preferred text[] default '{}';
alter table carriers add column freight_refused text[] default '{}';
alter table carriers add column preferred_states char(2)[] default '{}';
alter table carriers add column avoided_states char(2)[] default '{}';
alter table carriers add column uses_factoring boolean;
alter table carriers add column factoring_company text;
alter table carriers add column accepts_quickpay boolean;
alter table carriers add column max_payment_terms_days int;
alter table carriers add column requires_approval_before_booking
  boolean not null default true;
alter table carriers add column permit_responsibility_default text
  check (permit_responsibility_default in
    ('carrier','permit_service','broker','dispatcher','varies'));
alter table carriers add column escort_responsibility_default text
  check (escort_responsibility_default in
    ('carrier','escort_company','broker','dispatcher','permit_service','varies'));
alter table carriers add column preferred_permit_service_id
  uuid references permit_services(id);
alter table carriers add column preferred_escort_company_id
  uuid references escort_companies(id);


-- ------------------------------------------------------------
-- WHO TO CALL
-- Responsibility already exists. What was missing is the phone
-- number that responsibility implies.
-- ------------------------------------------------------------
alter table loads add column permit_contact_company text;
alter table loads add column permit_contact_name text;
alter table loads add column permit_contact_phone text;
alter table loads add column permit_contact_email text;

alter table loads add column escort_contact_company text;
alter table loads add column escort_contact_name text;
alter table loads add column escort_contact_phone text;


-- ------------------------------------------------------------
-- ACCESSORIAL TERMS as negotiated on the call
-- ------------------------------------------------------------
alter table loads add column detention_free_hours numeric(4,1);
alter table loads add column detention_rate_per_hour numeric(10,2);
alter table loads add column layover_rate numeric(10,2);
alter table loads add column layover_requires_approval boolean default true;
alter table loads add column tonu_rate numeric(10,2);
alter table loads add column accessorial_notes text;
alter table loads add column rate_con_matches_agreement boolean;
alter table loads add column carrier_approved_at timestamptz;
alter table loads add column carrier_approved_by text;


-- ------------------------------------------------------------
-- ESCORT MEETING DETAILS
-- From the coordination checklist.
-- ------------------------------------------------------------
alter table escort_assignments add column meeting_location text;
alter table escort_assignments add column meeting_time timestamptz;
alter table escort_assignments add column contacts_exchanged boolean
  not null default false;
alter table escort_assignments add column confirmed_day_before boolean
  not null default false;


-- ------------------------------------------------------------
-- PERMIT CONDITIONS worth monitoring, as structured flags
-- rather than buried in free text. These are the ones you
-- proactively call the driver about.
-- ------------------------------------------------------------
alter table permits add column daylight_only boolean not null default false;
alter table permits add column wind_limit_mph int;
alter table permits add column curfew_notes text;
alter table permits add column weekend_travel_allowed boolean;
alter table permits add column holiday_travel_allowed boolean;
alter table permits add column driver_has_permit boolean not null default false;
alter table permits add column driver_briefed_at timestamptz;


-- ------------------------------------------------------------
-- CHECKLIST TEMPLATE — edit these rows to change the checklist
-- for all future loads. Existing loads keep what they were
-- generated with, so history stays honest.
-- ------------------------------------------------------------
create table checklist_templates (
  id            uuid primary key default gen_random_uuid(),
  phase         text not null
                check (phase in ('before_booking','before_dispatch','before_pickup',
                        'en_route','before_delivery','after_delivery','oversize')),
  seq           int not null,
  item          text not null,
  oversize_only boolean not null default false,
  active        boolean not null default true
);
create unique index idx_checklist_tmpl on checklist_templates(phase, seq);

insert into checklist_templates (phase, seq, item, oversize_only) values
 ('before_booking', 1,'Carrier has the correct equipment', false),
 ('before_booking', 2,'Trailer capacity matches the load', false),
 ('before_booking', 3,'Load dimensions obtained', false),
 ('before_booking', 4,'Gross weight obtained', false),
 ('before_booking', 5,'Pickup and delivery appointments confirmed', false),
 ('before_booking', 6,'Permit responsibility confirmed', false),
 ('before_booking', 7,'Escort responsibility confirmed', false),
 ('before_booking', 8,'Payment terms reviewed', false),
 ('before_booking', 9,'Detention, layover and TONU terms reviewed', false),
 ('before_booking',10,'Rate confirmation reviewed against agreement', false),
 ('before_booking',11,'Carrier approved the load', false),

 ('before_dispatch',1,'Driver has accepted the load', false),
 ('before_dispatch',2,'Driver has sufficient hours of service', false),
 ('before_dispatch',3,'Driver has pickup information', false),
 ('before_dispatch',4,'Driver has shipper contact information', false),
 ('before_dispatch',5,'Driver has permit information', true),
 ('before_dispatch',6,'Driver understands special instructions', false),
 ('before_dispatch',7,'Driver has broker load number', false),

 ('before_pickup',1,'Pickup appointment confirmed with shipper', false),
 ('before_pickup',2,'Freight expected to be ready', false),
 ('before_pickup',3,'Site requirements communicated (PPE, gate, check-in)', false),
 ('before_pickup',4,'Loading instructions communicated', false),

 ('en_route',1,'Pickup confirmed', false),
 ('en_route',2,'Permits received by driver', true),
 ('en_route',3,'Escort coordination confirmed', true),
 ('en_route',4,'Driver following the permitted route', true),
 ('en_route',5,'Significant delays communicated to broker', false),

 ('before_delivery',1,'Delivery appointment confirmed', false),
 ('before_delivery',2,'Receiver check-in instructions confirmed', false),
 ('before_delivery',3,'Unloading requirements confirmed', false),
 ('before_delivery',4,'Broker notified of any schedule change', false),

 ('after_delivery',1,'Delivery completed', false),
 ('after_delivery',2,'Signed POD obtained', false),
 ('after_delivery',3,'BOL obtained', false),
 ('after_delivery',4,'Scale tickets or delivery receipts obtained', false),
 ('after_delivery',5,'Photos obtained if requested', false),
 ('after_delivery',6,'Paperwork submitted to broker', false),

 ('oversize',1,'Permit received before travel', true),
 ('oversize',2,'Driver understands permit restrictions', true),
 ('oversize',3,'Correct permitted route will be followed', true),
 ('oversize',4,'Escort requirements confirmed', true),
 ('oversize',5,'Travel-day and travel-hour restrictions reviewed', true),
 ('oversize',6,'Curfew, holiday and weekend restrictions reviewed', true),
 ('oversize',7,'Bridge, tunnel and construction restrictions reviewed', true),
 ('oversize',8,'Utility or police escort requirements confirmed', true);


create table load_checklist_items (
  id         uuid primary key default gen_random_uuid(),
  tenant_id  uuid not null references tenants(id),
  load_id    uuid not null references loads(id) on delete cascade,
  phase      text not null,
  seq        int not null,
  item       text not null,
  done_at    timestamptz,
  done_by    uuid references app_users(id),
  not_applicable boolean not null default false,
  note       text,
  created_at timestamptz not null default now()
);
create unique index idx_lci_unique on load_checklist_items(load_id, phase, seq);
create index idx_lci_load on load_checklist_items(load_id);

create or replace function generate_load_checklist(p_load_id uuid)
returns int
language plpgsql
as $$
declare v_load loads%rowtype; v_oversize boolean; n int;
begin
  select * into v_load from loads where id = p_load_id;
  if not found then raise exception 'Load % not found', p_load_id; end if;

  v_oversize := coalesce(v_load.width_in,0)  > 102
             or coalesce(v_load.height_in,0) > 162
             or coalesce(v_load.length_in,0) > 636
             or coalesce(v_load.weight_lb,0) > 80000;

  insert into load_checklist_items (tenant_id, load_id, phase, seq, item)
  select v_load.tenant_id, p_load_id, t.phase, t.seq, t.item
    from checklist_templates t
   where t.active
     and (v_oversize or not t.oversize_only)
  on conflict do nothing;

  get diagnostics n = row_count;
  return n;
end;
$$;


create or replace view v_load_red_flags
with (security_invoker = on) as
select
  l.id as load_id,
  l.load_number,
  array_remove(array[
    case when l.width_in is null or l.height_in is null
           or l.length_in is null            then 'Missing dimensions' end,
    case when l.weight_lb is null            then 'Missing weight' end,
    case when l.trailer_id is null
          and l.status <> 'quoted'           then 'No trailer assigned' end,
    case when l.driver_id is null
          and l.status <> 'quoted'           then 'No driver assigned' end,
    case when l.driver_hours_remaining_min is not null
          and l.driver_hours_remaining_min < 240
                                             then 'Driver under 4 hours HOS' end,
    case when (coalesce(l.width_in,0)  > 102 or coalesce(l.height_in,0) > 162
            or coalesce(l.length_in,0) > 636 or coalesce(l.weight_lb,0) > 80000)
          and not exists (select 1 from permits p where p.load_id = l.id)
                                             then 'Oversize with no permit plan' end,
    case when exists (select 1 from permits p
                       where p.load_id = l.id and p.status = 'issued'
                         and not p.driver_has_permit)
                                             then 'Driver does not have issued permit' end,
    case when ps.has_window_conflict         then 'Permit window conflicts with travel date' end,
    case when exists (select 1 from escort_assignments e
                       where e.load_id = l.id
                         and e.status in ('needed','quoted')
                         and l.status not in ('quoted','booked'))
                                             then 'Escorts not arranged' end,
    case when exists (select 1 from escort_assignments e
                       where e.load_id = l.id
                         and e.status in ('confirmed','booked')
                         and not e.contacts_exchanged)
                                             then 'Escort and driver contacts not exchanged' end,
    case when l.rate_con_matches_agreement is false
                                             then 'Rate confirmation does not match agreement' end,
    case when c.requires_approval_before_booking
          and l.carrier_approved_at is null
          and l.status not in ('quoted')      then 'Carrier approval required and not obtained' end,
    case when c.min_load_revenue is not null
          and coalesce(l.linehaul_rate,0) + coalesce(l.fuel_surcharge,0)
              < c.min_load_revenue            then 'Below carrier minimum revenue' end,
    case when c.max_width_in is not null
          and coalesce(l.width_in,0) > c.max_width_in
                                             then 'Exceeds carrier maximum width' end,
    case when l.status in ('delivered','pod_pending')
          and not exists (select 1 from documents d
                          join document_links dl on dl.document_id = d.id
                          where dl.entity_type='load' and dl.entity_id = l.id
                            and d.doc_type='pod')
                                             then 'Delivered with no POD on file' end
  ], null) as flags
from loads l
left join carriers c on c.id = l.carrier_id
left join v_load_permit_status ps on ps.load_id = l.id
where l.archived_at is null;

alter table carriers add column min_load_revenue numeric(10,2);
alter table carriers add column target_rate_per_mile numeric(6,2);
alter table carriers add column max_width_in int;
alter table carriers add column max_height_in int;
alter table carriers add column max_weight_lb int;
alter table carriers add column trailer_capacity_tons int;
alter table carriers add column freight_preferred text[] default '{}';
alter table carriers add column freight_refused text[] default '{}';
alter table carriers add column preferred_states char(2)[] default '{}';
alter table carriers add column avoided_states char(2)[] default '{}';
alter table carriers add column uses_factoring boolean;
alter table carriers add column factoring_company text;
alter table carriers add column accepts_quickpay boolean;
alter table carriers add column max_payment_terms_days int;
alter table carriers add column requires_approval_before_booking boolean not null default true;
alter table carriers add column permit_responsibility_default text
  check (permit_responsibility_default in ('carrier','permit_service','broker','dispatcher','varies'));
alter table carriers add column escort_responsibility_default text
  check (escort_responsibility_default in ('carrier','escort_company','broker','dispatcher','permit_service','varies'));
alter table carriers add column preferred_permit_service_id uuid references permit_services(id);
alter table carriers add column preferred_escort_company_id uuid references escort_companies(id);

alter table loads add column permit_contact_company text;
alter table loads add column permit_contact_name text;
alter table loads add column permit_contact_phone text;
alter table loads add column permit_contact_email text;
alter table loads add column escort_contact_company text;
alter table loads add column escort_contact_name text;
alter table loads add column escort_contact_phone text;
alter table loads add column detention_free_hours numeric(4,1);
alter table loads add column detention_rate_per_hour numeric(10,2);
alter table loads add column layover_rate numeric(10,2);
alter table loads add column layover_requires_approval boolean default true;
alter table loads add column tonu_rate numeric(10,2);
alter table loads add column accessorial_notes text;
alter table loads add column rate_con_matches_agreement boolean;
alter table loads add column carrier_approved_at timestamptz;
alter table loads add column carrier_approved_by text;

alter table escort_assignments add column meeting_location text;
alter table escort_assignments add column meeting_time timestamptz;
alter table escort_assignments add column contacts_exchanged boolean not null default false;
alter table escort_assignments add column confirmed_day_before boolean not null default false;

alter table permits add column daylight_only boolean not null default false;
alter table permits add column wind_limit_mph int;
alter table permits add column curfew_notes text;
alter table permits add column weekend_travel_allowed boolean;
alter table permits add column holiday_travel_allowed boolean;
alter table permits add column driver_has_permit boolean not null default false;
alter table permits add column driver_briefed_at timestamptz;



create or replace function generate_load_checklist(p_load_id uuid)
returns int
language plpgsql
as $$
declare v_load loads%rowtype; v_oversize boolean; n int;
begin
  select * into v_load from loads where id = p_load_id;
  if not found then raise exception 'Load % not found', p_load_id; end if;

  v_oversize := coalesce(v_load.width_in,0)  > 102
             or coalesce(v_load.height_in,0) > 162
             or coalesce(v_load.length_in,0) > 636
             or coalesce(v_load.weight_lb,0) > 80000;

  insert into load_checklist_items (tenant_id, load_id, phase, seq, item)
  select v_load.tenant_id, p_load_id, t.phase, t.seq, t.item
    from checklist_templates t
   where t.active
     and (v_oversize or not t.oversize_only)
  on conflict do nothing;

  get diagnostics n = row_count;
  return n;
end;
$$;

grant execute on function generate_load_checklist(uuid) to authenticated;

create or replace view v_load_red_flags
with (security_invoker = on) as
select
  l.id as load_id,
  l.load_number,
  array_remove(array[
    case when l.width_in is null or l.height_in is null
           or l.length_in is null            then 'Missing dimensions' end,
    case when l.weight_lb is null            then 'Missing weight' end,
    case when l.trailer_id is null
          and l.status <> 'quoted'           then 'No trailer assigned' end,
    case when l.driver_id is null
          and l.status <> 'quoted'           then 'No driver assigned' end,
    case when l.driver_hours_remaining_min is not null
          and l.driver_hours_remaining_min < 240
                                             then 'Driver under 4 hours HOS' end,
    case when (coalesce(l.width_in,0)  > 102 or coalesce(l.height_in,0) > 162
            or coalesce(l.length_in,0) > 636 or coalesce(l.weight_lb,0) > 80000)
          and not exists (select 1 from permits p where p.load_id = l.id)
                                             then 'Oversize with no permit plan' end,
    case when exists (select 1 from permits p
                       where p.load_id = l.id and p.status = 'issued'
                         and not p.driver_has_permit)
                                             then 'Driver does not have issued permit' end,
    case when ps.has_window_conflict         then 'Permit window conflicts with travel date' end,
    case when exists (select 1 from escort_assignments e
                       where e.load_id = l.id
                         and e.status in ('needed','quoted')
                         and l.status not in ('quoted','booked'))
                                             then 'Escorts not arranged' end,
    case when exists (select 1 from escort_assignments e
                       where e.load_id = l.id
                         and e.status in ('confirmed','booked')
                         and not e.contacts_exchanged)
                                             then 'Escort and driver contacts not exchanged' end,
    case when l.rate_con_matches_agreement is false
                                             then 'Rate confirmation does not match agreement' end,
    case when c.requires_approval_before_booking
          and l.carrier_approved_at is null
          and l.status <> 'quoted'            then 'Carrier approval required and not obtained' end,
    case when c.min_load_revenue is not null
          and coalesce(l.linehaul_rate,0) + coalesce(l.fuel_surcharge,0)
              < c.min_load_revenue            then 'Below carrier minimum revenue' end,
    case when c.max_width_in is not null
          and coalesce(l.width_in,0) > c.max_width_in
                                             then 'Exceeds carrier maximum width' end,
    case when l.status in ('delivered','pod_pending')
          and not exists (select 1 from documents d
                          join document_links dl on dl.document_id = d.id
                          where dl.entity_type='load' and dl.entity_id = l.id
                            and d.doc_type='pod')
                                             then 'Delivered with no POD on file' end
  ], null) as flags
from loads l
left join carriers c on c.id = l.carrier_id
left join v_load_permit_status ps on ps.load_id = l.id
where l.archived_at is null;

grant select on v_load_red_flags to authenticated;
