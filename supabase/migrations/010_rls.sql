-- ------------------------------------------------------------
-- BASE TABLE GRANTS
-- Supabase normally sets these up automatically, but they are
-- attached to the schema — so `drop schema public cascade`
-- strips them and the new schema does not inherit them.
-- Without these, every query fails with "permission denied for
-- table X" even though RLS policies are correct.
--
-- These grants only say the role MAY attempt to read a table.
-- RLS policies still decide which rows come back. Both layers
-- are required.
--
-- Note: no DELETE anywhere. Soft delete via archived_at only.
-- ------------------------------------------------------------
grant usage on schema public to anon, authenticated;

grant select, insert, update on all tables in schema public to authenticated;
grant select on all tables in schema public to anon;

grant usage, select on all sequences in schema public to authenticated;
grant execute on all functions in schema public to authenticated;

alter default privileges in schema public
  grant select, insert, update on tables to authenticated;
alter default privileges in schema public
  grant usage, select on sequences to authenticated;

-- ============================================================
-- 010_rls.sql
-- Tenant isolation, role permissions, view security,
-- revoked deletes, storage policies
-- ============================================================

-- ------------------------------------------------------------
-- WHO AM I
-- security definer is mandatory. Without it, these functions
-- query app_users, RLS fires on app_users, which calls these
-- functions again — infinite recursion, and every query dies.
-- ------------------------------------------------------------
create or replace function current_tenant_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select tenant_id from app_users
   where auth_uid = auth.uid() and status = 'active'
   limit 1;
$$;

revoke all on function current_tenant_id() from public;
grant execute on function current_tenant_id() to authenticated;

create or replace function current_user_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select role from app_users
   where auth_uid = auth.uid() and status = 'active'
   limit 1;
$$;

revoke all on function current_user_role() from public;
grant execute on function current_user_role() to authenticated;

-- Replace the 009 stub with the real implementation
create or replace function current_user_role_safe()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select role from app_users where auth_uid = auth.uid() limit 1),
    'owner');
$$;


-- ------------------------------------------------------------
-- APP_USERS — its own policy. A dispatcher must not be able
-- to promote themselves to owner.
-- ------------------------------------------------------------
alter table app_users enable row level security;

create policy app_users_read on app_users
  for select to authenticated
  using (tenant_id = current_tenant_id());

create policy app_users_admin_write on app_users
  for insert to authenticated
  with check (tenant_id = current_tenant_id()
              and current_user_role() in ('owner','admin'));

create policy app_users_admin_update on app_users
  for update to authenticated
  using (tenant_id = current_tenant_id()
         and current_user_role() in ('owner','admin'))
  with check (tenant_id = current_tenant_id());


-- ------------------------------------------------------------
-- EVERY OTHER TENANT TABLE
-- Read for anyone signed in; write only for dispatcher and up.
-- Viewers are genuinely read-only.
-- ------------------------------------------------------------
do $do$
declare t text;
begin
  foreach t in array array[
    'carriers','carrier_lanes','drivers','equipment','brokers','facilities',
    'escort_companies','permit_services','contacts','documents','document_links',
    'tags','taggings','favorites','loads','load_legs','load_charges',
    'permits','escort_assignments','reminders','check_ins'
  ]
  loop
    execute format('alter table %I enable row level security', t);

    execute format(
      'create policy tenant_read on %I for select to authenticated
       using (tenant_id = current_tenant_id())', t);

    execute format(
      'create policy tenant_insert on %I for insert to authenticated
       with check (tenant_id = current_tenant_id()
                   and current_user_role() in (''owner'',''admin'',''dispatcher''))', t);

    execute format(
      'create policy tenant_update on %I for update to authenticated
       using (tenant_id = current_tenant_id()
              and current_user_role() in (''owner'',''admin'',''dispatcher''))
       with check (tenant_id = current_tenant_id())', t);
  end loop;
end $do$;


-- ------------------------------------------------------------
-- EVENTS — read and insert only, never update or delete
-- ------------------------------------------------------------
alter table events enable row level security;

create policy events_read on events
  for select to authenticated
  using (tenant_id = current_tenant_id());

create policy events_insert on events
  for insert to authenticated
  with check (tenant_id = current_tenant_id());


-- ------------------------------------------------------------
-- TENANTS and reference data
-- ------------------------------------------------------------
alter table tenants enable row level security;
create policy tenants_read on tenants
  for select to authenticated
  using (id = current_tenant_id());

alter table state_permit_rules enable row level security;
create policy rules_read on state_permit_rules
  for select to authenticated using (true);
create policy rules_write on state_permit_rules
  for insert to authenticated
  with check (current_user_role() in ('owner','admin','dispatcher'));
create policy rules_update on state_permit_rules
  for update to authenticated
  using (current_user_role() in ('owner','admin','dispatcher'));

alter table load_status_transitions enable row level security;
create policy transitions_read on load_status_transitions
  for select to authenticated using (true);


-- ------------------------------------------------------------
-- NO DELETES, ANYWHERE
-- There is no path from a browser to actual data loss.
-- A misclick cannot destroy a rate confirmation.
-- ------------------------------------------------------------
do $do$
declare t text;
begin
  foreach t in array array[
    'tenants','carriers','carrier_lanes','drivers','equipment','brokers',
    'facilities','escort_companies','permit_services','contacts','documents',
    'document_links','tags','taggings','favorites','loads','load_legs',
    'load_charges','permits','escort_assignments','events','reminders',
    'check_ins','app_users','state_permit_rules','load_status_transitions'
  ]
  loop
    execute format('revoke delete on %I from authenticated, anon', t);
  end loop;
end $do$;


-- ------------------------------------------------------------
-- VIEWS MUST RESPECT RLS
-- Postgres runs a view as its OWNER by default, which would
-- return every tenant's rows. This is easy to miss and would
-- silently leak data.
-- ------------------------------------------------------------
alter view v_expiring_documents  set (security_invoker = on);
alter view v_load_permit_status  set (security_invoker = on);
alter view v_load_margin         set (security_invoker = on);
alter view v_dispatch_calendar   set (security_invoker = on);
alter view v_load_board          set (security_invoker = on);
alter view v_fleet_board         set (security_invoker = on);


-- ------------------------------------------------------------
-- GLOBAL SEARCH — read the tenant from the session instead of
-- accepting it as an argument. The old signature let anyone
-- pass any tenant id.
-- ------------------------------------------------------------
drop function if exists global_search(uuid, text);

create or replace function global_search(p_query text)
returns table (entity_type text, entity_id uuid, title text,
               subtitle text, rank real)
language sql
stable
security invoker
as $$
  select 'load'::text, l.id, l.load_number,
         coalesce(l.commodity,'') || ' · ' || l.status,
         similarity(l.load_number || ' ' || coalesce(l.commodity,''), p_query)
    from loads l
   where l.archived_at is null
     and (l.load_number ilike '%'||p_query||'%'
       or l.broker_load_number ilike '%'||p_query||'%'
       or l.commodity ilike '%'||p_query||'%')
  union all
  select 'carrier'::text, c.id, c.legal_name,
         coalesce('MC ' || c.mc_number, ''), similarity(c.legal_name, p_query)
    from carriers c
   where c.archived_at is null
     and (c.legal_name ilike '%'||p_query||'%'
       or c.dba_name   ilike '%'||p_query||'%'
       or c.mc_number  ilike '%'||p_query||'%'
       or c.dot_number ilike '%'||p_query||'%')
  union all
  select 'broker'::text, b.id, b.name,
         coalesce('MC ' || b.mc_number, ''), similarity(b.name, p_query)
    from brokers b
   where b.archived_at is null
     and (b.name ilike '%'||p_query||'%' or b.mc_number ilike '%'||p_query||'%')
  union all
  select 'facility'::text, f.id, f.name,
         coalesce(f.city,'') || ', ' || coalesce(f.state,''),
         similarity(f.name, p_query)
    from facilities f
   where f.archived_at is null and f.name ilike '%'||p_query||'%'
  union all
  select 'driver'::text, d.id, d.first_name || ' ' || d.last_name,
         coalesce(d.phone,''),
         similarity(d.first_name || ' ' || d.last_name, p_query)
    from drivers d
   where d.archived_at is null
     and (d.first_name ilike '%'||p_query||'%'
       or d.last_name  ilike '%'||p_query||'%')
  union all
  select 'document'::text, dc.id, coalesce(dc.title, dc.filename), dc.doc_type,
         similarity(coalesce(dc.title,'') || ' ' || dc.filename, p_query)
    from documents dc
   where dc.is_current and dc.archived_at is null
     and (dc.filename ilike '%'||p_query||'%'
       or dc.title    ilike '%'||p_query||'%'
       or dc.ocr_text ilike '%'||p_query||'%')
  union all
  select 'permit'::text, p.id,
         coalesce(p.permit_number, p.state || ' permit'),
         p.state || ' · ' || p.status,
         similarity(coalesce(p.permit_number,''), p_query)
    from permits p
   where p.permit_number ilike '%'||p_query||'%'
  order by 5 desc nulls last
  limit 50;
$$;

grant execute on function global_search(text) to authenticated;
