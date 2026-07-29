-- ============================================================
-- 003_documents.sql
-- One row per physical file. Stored once, linked many times.
-- ============================================================

-- ------------------------------------------------------------
-- DOCUMENTS
-- sha256 is unique per tenant: re-uploading a file you already
-- have creates a new LINK, never a second copy.
-- Insurance, W-9, CDL, medical cards are all just doc_types
-- with an expires_on date — no separate tables for each.
-- ------------------------------------------------------------
create table documents (
  id                uuid primary key default gen_random_uuid(),
  tenant_id         uuid not null references tenants(id),
  sha256            text not null,
  storage_key       text not null,
  filename          text not null,
  mime_type         text,
  byte_size         bigint,
  doc_type          text not null
                    check (doc_type in (
                      'rate_confirmation','bol','pod','permit','escort_confirmation',
                      'invoice','insurance_coi','w9','operating_authority',
                      'registration','inspection_report','scale_ticket','photo',
                      'email','receipt','carrier_packet','broker_packet',
                      'route_survey','bridge_analysis','lease_agreement',
                      'cdl','medical_card','contract','other')),
  title             text,
  issued_on         date,
  expires_on        date,
  version_group_id  uuid not null default gen_random_uuid(),
  version_no        int not null default 1,
  is_current        boolean not null default true,
  page_count        int,
  ocr_text          text,
  uploaded_by       text,
  uploaded_at       timestamptz not null default now(),
  notes             text,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

-- The deduplication guarantee
create unique index idx_documents_hash on documents(tenant_id, sha256);

-- Exactly one current version per version chain
create unique index idx_documents_current on documents(version_group_id)
  where is_current;

create index idx_documents_tenant on documents(tenant_id);
create index idx_documents_type on documents(tenant_id, doc_type);
create index idx_documents_expiry on documents(tenant_id, expires_on)
  where expires_on is not null and is_current;
create index idx_documents_name_trgm on documents using gin (filename gin_trgm_ops);


-- ------------------------------------------------------------
-- DOCUMENT LINKS
-- The anti-duplication table. One document, many owners.
-- ------------------------------------------------------------
create table document_links (
  id           uuid primary key default gen_random_uuid(),
  tenant_id    uuid not null references tenants(id),
  document_id  uuid not null references documents(id) on delete cascade,
  entity_type  text not null
               check (entity_type in ('carrier','driver','equipment','broker',
                       'facility','load','permit','escort_assignment',
                       'escort_company','permit_service','invoice','event')),
  entity_id    uuid not null,
  relation     text not null default 'attached'
               check (relation in ('attached','primary','reference','packet_item')),
  created_at   timestamptz not null default now()
);
create unique index idx_doclinks_unique
  on document_links(document_id, entity_type, entity_id);
create index idx_doclinks_entity on document_links(entity_type, entity_id);
create index idx_doclinks_tenant on document_links(tenant_id);


-- ------------------------------------------------------------
-- TAGS (generic — taggable across any entity type)
-- ------------------------------------------------------------
create table tags (
  id         uuid primary key default gen_random_uuid(),
  tenant_id  uuid not null references tenants(id),
  name       text not null,
  color      text default 'gray',
  created_at timestamptz not null default now()
);
create unique index idx_tags_name on tags(tenant_id, lower(name));

create table taggings (
  id           uuid primary key default gen_random_uuid(),
  tenant_id    uuid not null references tenants(id),
  tag_id       uuid not null references tags(id) on delete cascade,
  entity_type  text not null,
  entity_id    uuid not null,
  created_at   timestamptz not null default now()
);
create unique index idx_taggings_unique on taggings(tag_id, entity_type, entity_id);
create index idx_taggings_entity on taggings(entity_type, entity_id);


-- ------------------------------------------------------------
-- FAVORITES
-- ------------------------------------------------------------
create table favorites (
  id           uuid primary key default gen_random_uuid(),
  tenant_id    uuid not null references tenants(id),
  user_ref     text not null,
  entity_type  text not null,
  entity_id    uuid not null,
  created_at   timestamptz not null default now()
);
create unique index idx_favorites_unique
  on favorites(user_ref, entity_type, entity_id);


-- ------------------------------------------------------------
-- SUPERSEDE: replace a document with a new version.
-- The new version inherits every link the old one had, so a
-- revised rate con appears everywhere the original did.
-- ------------------------------------------------------------
create or replace function supersede_document(p_old uuid, p_new uuid)
returns void
language plpgsql
as $$
declare
  v_group uuid;
  v_next  int;
begin
  select version_group_id, version_no + 1
    into v_group, v_next
    from documents where id = p_old;

  if v_group is null then
    raise exception 'Original document % not found', p_old;
  end if;

  update documents set is_current = false where id = p_old;

  update documents
     set version_group_id = v_group,
         version_no       = v_next,
         is_current       = true
   where id = p_new;

  insert into document_links (tenant_id, document_id, entity_type, entity_id, relation)
  select tenant_id, p_new, entity_type, entity_id, relation
    from document_links
   where document_id = p_old
  on conflict do nothing;
end;
$$;


-- ------------------------------------------------------------
-- updated_at trigger
-- ------------------------------------------------------------
create trigger trg_documents_updated before update on documents
for each row execute function set_updated_at();
