-- ============================================================
-- 040_route_workflow_queue.sql
-- Heavy Haul Command
-- Persistent Route Planning queue status
-- ============================================================

alter table public.route_plans
  add column if not exists workflow_status text not null default 'in_progress';

alter table public.route_plans
  drop constraint if exists route_plans_workflow_status_check;

alter table public.route_plans
  add constraint route_plans_workflow_status_check
  check (workflow_status in ('in_progress','ready_for_state_review','returned_for_revision'));

create index if not exists route_plans_workflow_status_idx
  on public.route_plans (tenant_id, workflow_status);

-- One working route plan per load. Manual route plans may still have load_id = null.
create unique index if not exists route_plans_one_per_load_idx
  on public.route_plans (load_id)
  where load_id is not null;
