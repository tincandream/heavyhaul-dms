-- 025_document_templates.sql
alter table documents add column if not exists is_template boolean default false;
create index if not exists idx_documents_template on documents (is_template) where is_template;
