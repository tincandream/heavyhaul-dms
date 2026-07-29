-- ============================================================
-- 005_permits_escorts.sql
-- State rules, per-state permits, escort assignments
-- ============================================================

-- ------------------------------------------------------------
-- STATE PERMIT RULES — reference data, not tenant-specific.
-- Deliberately seeded EMPTY. You add each state yourself,
-- verified against that state's permit office, the first time
-- you run a load through it. Never trust numbers you didn't
-- confirm — a wrong threshold here means a ticketed truck.
-- ------------------------------------------------------------
create table state_permit_rules (
  state                char(2) primary key,
  office_name          text,
  office_phone         text,
  portal_url           text,
  office_hours         text,
  max_legal_width_in   int default 102,
  max_legal_height_in  int default 162,
  max_legal_length_in  int default 636,
  max_legal_weight_lb  int default 80000,
  escort_width_in      int,
  escort_length_in     int,
  high_pole_height_in  int,
  police_width_in      int,
  superload_width_in   int,
  superload_weight_lb  int,
  travel_time_notes    text,
  holiday_restrictions text,
  notes                text,
  verified_on          date,
  updated_at           timestamptz not null default now()
);


-- ------------------------------------------------------------
-- PERMITS
-- load_leg_id is the true parent; load_id is denormalized so
-- the load workspace doesn't join through legs on every render.
-- ------------------------------------------------------------
create table permits (
  id                       uuid primary key default gen_random_uuid(),
  tenant_id                uuid not null references tenants(id),
  load_id                  uuid not null references loads(id) on delete cascade,
  load_leg_id              uuid references load_legs(id) on delete cascade,
  state                    char(2) not null,
  permit_number            text,
  issuing_authority        text,
  permit_service_id        uuid references permit_services(id),
  status                   text not null default 'needed'
                           check (status in ('not_required','needed','applied',
                                   'pending','issued','rejected','expired',
                                   'amended','cancelled')),
  applied_at               timestamptz,
  issued_at                timestamptz,
  valid_from               date,
  valid_to                 date,
  fee                      numeric(10,2),
  service_fee              numeric(10,2),
  route_restrictions       text,
  travel_time_restrictions text,
  escort_front             boolean not null default false,
  escort_rear              boolean not null default false,
  escort_police            boolean not null default false,
  escort_high_pole         boolean not null default false,
  document_id              uuid references documents(id),
  notes                    text,
  created_at               timestamptz not null default now(),
  updated_at               timestamptz not null default now()
);
create index idx_permits_load   on permits(load_id);
create index idx_permits_leg    on permits(load_leg_id);
create index idx_permits_tenant on permits(tenant_id);
create index idx_permits_status on permits(tenant_id, status);
create index idx_permits_validity on permits(tenant_id, valid_to)
  where status = 'issued';
create unique index idx_permits_number on permits(tenant_id, state, permit_number)
  where permit_number is not null;


-- ------------------------------------------------------------
-- ESCORT ASSIGNMENTS
-- quoted vs confirmed vs actual, so you can see which escort
-- companies quote low and bill high.
-- ------------------------------------------------------------
create table escort_assignments (
  id                uuid primary key default gen_random_uuid(),
  tenant_id         uuid not null references tenants(id),
  load_id           uuid not null references loads(id) on delete cascade,
  load_leg_id       uuid references load_legs(id) on delete cascade,
  escort_company_id uuid references escort_companies(id),
  role              text not null
                    check (role in ('front','rear','high_pole','police','steer','chase')),
  status            text not null default 'needed'
                    check (status in ('needed','quoted','booked','confirmed',
                            'en_route','completed','cancelled','no_show')),
  quoted_rate       numeric(10,2),
  confirmed_rate    numeric(10,2),
  actual_cost       numeric(10,2),
  driver_name       text,
  driver_phone      text,
  vehicle_info      text,
  scheduled_start   timestamptz,
  scheduled_end     timestamptz,
  document_id       uuid references documents(id),
  notes             text,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);
create index idx_escorts_load     on escort_assignments(load_id);
create index idx_escorts_leg      on escort_assignments(load_leg_id);
create index idx_escorts_tenant   on escort_assignments(tenant_id);
create index idx_escorts_schedule on escort_assignments(tenant_id, scheduled_start);
create index idx_escorts_company  on escort_assignments(escort_company_id);


-- ------------------------------------------------------------
-- GENERATE PERMIT REQUIREMENTS
-- Reads the load's dimensions against each leg's state rules
-- and creates the permit and escort rows that are required.
-- Skips any state you haven't entered rules for yet.
-- ------------------------------------------------------------
create or replace function generate_permit_requirements(p_load_id uuid)
returns int
language plpgsql
as $$
declare
  v_load         loads%rowtype;
  v_leg          load_legs%rowtype;
  v_rule         state_permit_rules%rowtype;
  v_created      int := 0;
  v_needs_front  boolean;
  v_needs_rear   boolean;
  v_needs_pole   boolean;
  v_needs_police boolean;
begin
  select * into v_load from loads where id = p_load_id;
  if not found then
    raise exception 'Load % not found', p_load_id;
  end if;

  for v_leg in
    select * from load_legs where load_id = p_load_id order by seq
  loop
    select * into v_rule from state_permit_rules where state = v_leg.state;
    if not found then
      continue;  -- no rules entered for this state yet
    end if;

    if coalesce(v_load.width_in,0)  > v_rule.max_legal_width_in
    or coalesce(v_load.height_in,0) > v_rule.max_legal_height_in
    or coalesce(v_load.length_in,0) > v_rule.max_legal_length_in
    or coalesce(v_load.weight_lb,0) > v_rule.max_legal_weight_lb then

      v_needs_front := v_rule.escort_width_in is not null
                       and coalesce(v_load.width_in,0) >= v_rule.escort_width_in;

      v_needs_rear  := v_needs_front
                       or (v_rule.escort_length_in is not null
                           and coalesce(v_load.length_in,0) >= v_rule.escort_length_in);

      v_needs_pole  := v_rule.high_pole_height_in is not null
                       and coalesce(v_load.height_in,0) >= v_rule.high_pole_height_in;

      v_needs_police := v_rule.police_width_in is not null
                        and coalesce(v_load.width_in,0) >= v_rule.police_width_in;

      insert into permits (tenant_id, load_id, load_leg_id, state, status,
                           escort_front, escort_rear, escort_high_pole, escort_police)
      values (v_load.tenant_id, p_load_id, v_leg.id, v_leg.state, 'needed',
              v_needs_front, v_needs_rear, v_needs_pole, v_needs_police);
      v_created := v_created + 1;

      if v_needs_front then
        insert into escort_assignments (tenant_id, load_id, load_leg_id, role, status)
        values (v_load.tenant_id, p_load_id, v_leg.id, 'front', 'needed');
      end if;
      if v_needs_rear then
        insert into escort_assignments (tenant_id, load_id, load_leg_id, role, status)
        values (v_load.tenant_id, p_load_id, v_leg.id, 'rear', 'needed');
      end if;
      if v_needs_pole then
        insert into escort_assignments (tenant_id, load_id, load_leg_id, role, status)
        values (v_load.tenant_id, p_load_id, v_leg.id, 'high_pole', 'needed');
      end if;
      if v_needs_police then
        insert into escort_assignments (tenant_id, load_id, load_leg_id, role, status)
        values (v_load.tenant_id, p_load_id, v_leg.id, 'police', 'needed');
      end if;

      if v_rule.superload_width_in is not null
         and (coalesce(v_load.width_in,0) >= v_rule.superload_width_in
              or coalesce(v_load.weight_lb,0)
                 >= coalesce(v_rule.superload_weight_lb, 999999999)) then
        update loads
           set is_superload = true, requires_route_survey = true
         where id = p_load_id;
      end if;
    end if;
  end loop;

  return v_created;
end;
$$;


-- ------------------------------------------------------------
-- updated_at triggers
-- ------------------------------------------------------------
create trigger trg_permits_updated before update on permits
for each row execute function set_updated_at();

create trigger trg_escorts_updated before update on escort_assignments
for each row execute function set_updated_at();

create trigger trg_state_rules_updated before update on state_permit_rules
for each row execute function set_updated_at();
