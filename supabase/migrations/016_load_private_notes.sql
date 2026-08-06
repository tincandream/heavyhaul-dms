-- 016_load_private_notes.sql
create table if not exists load_private_notes (
  id          uuid primary key default gen_random_uuid(),
  tenant_id   uuid not null,
  load_id     uuid not null references loads(id) on delete cascade,
  body        text not null,
  pinned      boolean default false,
  created_by  uuid references app_users(id) on delete set null,
  created_at  timestamptz default now(),
  updated_at  timestamptz default now()
);
create index on load_private_notes (load_id, pinned desc, created_at desc);

alter table load_private_notes enable row level security;

create policy "tenant access" on load_private_notes
  for all
  using (tenant_id = /* your tenant expression */)
  with check (tenant_id = /* your tenant expression */);
