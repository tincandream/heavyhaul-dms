-- 024_document_links.sql
create table if not exists document_links (
  id           uuid primary key default gen_random_uuid(),
  tenant_id    uuid not null,
  document_id  uuid not null references documents(id) on delete cascade,
  entity_type  text not null check (entity_type in ('load','permit','escort','company','opportunity')),
  entity_id    uuid not null,
  created_at   timestamptz default now()
);

create index if not exists idx_doclinks_tenant on document_links (tenant_id);
create index if not exists idx_doclinks_doc    on document_links (document_id);
create index if not exists idx_doclinks_entity on document_links (entity_type, entity_id);

alter table document_links enable row level security;

create policy tenant_read on document_links
  for select using (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']));
create policy tenant_insert on document_links
  for insert with check (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']));
create policy tenant_update on document_links
  for update using (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']))
  with check (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']));
create policy tenant_delete on document_links
  for delete using (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']));

    alter table documents enable row level security;

create policy tenant_read on documents
  for select using (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']));
create policy tenant_insert on documents
  for insert with check (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']));
create policy tenant_update on documents
  for update using (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']))
  with check (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']));
create policy tenant_delete on documents
  for delete using (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']));
