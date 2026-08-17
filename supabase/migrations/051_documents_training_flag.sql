-- 051_documents_training_flag.sql
alter table public.documents
  add column if not exists is_training boolean not null default false;

drop trigger if exists trg_training_flag_documents on public.documents;

create trigger trg_training_flag_documents
before insert on public.documents
for each row execute function public.apply_protected_training_flag();
