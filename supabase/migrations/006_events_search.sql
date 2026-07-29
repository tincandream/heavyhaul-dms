-- ============================================================
-- 006_events_search.sql
-- The single activity stream, and global search
-- ============================================================

-- ------------------------------------------------------------
-- EVENTS
-- Every call, email, text, status change, upload, and note in
-- one table. Load timelines, broker history, and the global
-- activity feed are all this table filtered differently.
--
-- Becomes append-only with a hash chain in 009. The event_type
-- list is expanded there too (rest breaks, port of entry,
-- accident, repair completed, and the rest).
-- ------------------------------------------------------------
create table events (
  id            uuid primary key default gen_random_uuid(),
  tenant_id     uuid not null references tenants(id),
  entity_type   text not null
                check (entity_type in ('load','carrier','driver','broker',
                        'facility','permit','escort_assignment',
                        'escort_company','document','system')),
  entity_id     uuid not null,
  load_id       uuid references loads(id) on delete cascade,
  event_type    text not null
                check (event_type in ('call','email','sms','note','status_change',
                        'upload','permit_update','escort_update','appointment',
                        'check_call','issue','system')),
  direction     text check (direction in ('inbound','outbound','internal')),
  occurred_at   timestamptz not null default now(),
  actor         text,
  contact_id    uuid references contacts(id),
  subject       text,
  body          text,
  duration_sec  int,
  document_id   uuid references documents(id),
  metadata      jsonb default '{}'::jsonb,
  created_at    timestamptz not null default now()
);

create index idx_events_entity on events(entity_type, entity_id, occurred_at desc);
create index idx_events_load   on events(load_id, occurred_at desc);
create index idx_events_tenant_time on events(tenant_id, occurred_at desc);
create index idx_events_type   on events(tenant_id, event_type);
create index idx_events_body_trgm on events using gin (body gin_trgm_ops);


-- ------------------------------------------------------------
-- AUTO-LOG STATUS CHANGES
-- The first of several triggers that write timeline entries
-- without anyone remembering to. Living in the database means
-- it fires no matter where the change came from — the UI, a
-- bulk import, or you fixing something by hand at midnight.
-- ------------------------------------------------------------
create or replace function log_load_status_change()
returns trigger
language plpgsql
as $$
begin
  if new.status is distinct from old.status then
    insert into events (tenant_id, entity_type, entity_id, load_id,
                        event_type, direction, subject, body)
    values (new.tenant_id, 'load', new.id, new.id, 'status_change', 'internal',
            'Status changed',
            old.status || ' → ' || new.status);
  end if;
  return new;
end;
$$;

create trigger trg_load_status after update on loads
for each row execute function log_load_status_change();


-- ------------------------------------------------------------
-- GLOBAL SEARCH
-- One function across loads, carriers, brokers, facilities,
-- drivers, documents, and permits. Rewritten in 010 to read
-- the tenant from the session instead of taking it as an
-- argument — right now anyone could pass any tenant id.
-- ------------------------------------------------------------
create or replace function global_search(p_tenant uuid, p_query text)
returns table (entity_type text, entity_id uuid, title text,
               subtitle text, rank real)
language sql
stable
as $$
  select 'load'::text, l.id, l.load_number,
         coalesce(l.commodity,'') || ' · ' || l.status,
         similarity(l.load_number || ' ' || coalesce(l.commodity,''), p_query)
    from loads l
   where l.tenant_id = p_tenant
     and (l.load_number ilike '%'||p_query||'%'
       or l.broker_load_number ilike '%'||p_query||'%'
       or l.commodity ilike '%'||p_query||'%')

  union all
  select 'carrier'::text, c.id, c.legal_name,
         coalesce('MC ' || c.mc_number, ''),
         similarity(c.legal_name, p_query)
    from carriers c
   where c.tenant_id = p_tenant
     and (c.legal_name ilike '%'||p_query||'%'
       or c.dba_name   ilike '%'||p_query||'%'
       or c.mc_number  ilike '%'||p_query||'%'
       or c.dot_number ilike '%'||p_query||'%')

  union all
  select 'broker'::text, b.id, b.name,
         coalesce('MC ' || b.mc_number, ''),
         similarity(b.name, p_query)
    from brokers b
   where b.tenant_id = p_tenant
     and (b.name ilike '%'||p_query||'%' or b.mc_number ilike '%'||p_query||'%')

  union all
  select 'facility'::text, f.id, f.name,
         coalesce(f.city,'') || ', ' || coalesce(f.state,''),
         similarity(f.name, p_query)
    from facilities f
   where f.tenant_id = p_tenant and f.name ilike '%'||p_query||'%'

  union all
  select 'driver'::text, d.id, d.first_name || ' ' || d.last_name,
         coalesce(d.phone,''),
         similarity(d.first_name || ' ' || d.last_name, p_query)
    from drivers d
   where d.tenant_id = p_tenant
     and (d.first_name ilike '%'||p_query||'%'
       or d.last_name  ilike '%'||p_query||'%')

  union all
  select 'document'::text, dc.id, coalesce(dc.title, dc.filename), dc.doc_type,
         similarity(coalesce(dc.title,'') || ' ' || dc.filename, p_query)
    from documents dc
   where dc.tenant_id = p_tenant and dc.is_current
     and (dc.filename ilike '%'||p_query||'%'
       or dc.title    ilike '%'||p_query||'%'
       or dc.ocr_text ilike '%'||p_query||'%')

  union all
  select 'permit'::text, p.id,
         coalesce(p.permit_number, p.state || ' permit'),
         p.state || ' · ' || p.status,
         similarity(coalesce(p.permit_number,''), p_query)
    from permits p
   where p.tenant_id = p_tenant and p.permit_number ilike '%'||p_query||'%'

  order by 5 desc nulls last
  limit 50;
$$;
