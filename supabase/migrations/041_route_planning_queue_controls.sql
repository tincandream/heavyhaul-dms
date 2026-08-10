-- ============================================================
-- 041_route_planning_queue_controls.sql
-- Heavy Haul Command
-- Route Planning queue visibility controls
-- ============================================================

alter table public.loads
  add column if not exists route_planning_hidden boolean
  not null default false;

create index if not exists loads_route_planning_queue_idx
  on public.loads (tenant_id, route_planning_hidden, updated_at desc);

comment on column public.loads.route_planning_hidden is
  'When true, hides this load from the active Route Planning queue without deleting the load or its saved route plan.';
