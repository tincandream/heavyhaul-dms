-- ============================================================
-- 045_training_data_reset.sql
-- FINAL
-- ============================================================

alter table public.loads
  add column if not exists is_training boolean not null default false;

alter table public.load_opportunities
  add column if not exists is_training boolean not null default false;

alter table public.carriers
  add column if not exists is_training boolean not null default false;

alter table public.drivers
  add column if not exists is_training boolean not null default false;

alter table public.equipment
  add column if not exists is_training boolean not null default false;

alter table public.brokers
  add column if not exists is_training boolean not null default false;

alter table public.facilities
  add column if not exists is_training boolean not null default false;


-- Remove old no-argument version if it exists.
drop function if exists public.reset_training_data();


create or replace function public.reset_training_data(
  p_tenant_id uuid
)
returns void
language plpgsql
security invoker
set search_path = public
as $$

begin

  if p_tenant_id is null then
    raise exception 'Tenant ID is required.';
  end if;


  -- ----------------------------------------------------------
  -- Preserve load/audit history, but remove it from operations.
  -- ----------------------------------------------------------

  update public.loads
  set
    archived_at = coalesce(archived_at, now()),
    route_planning_hidden = true,

    driver_id = null,
    tractor_id = null,
    trailer_id = null,

    carrier_id = null,
    broker_id = null,
    origin_facility_id = null,
    dest_facility_id = null,

    updated_at = now()

  where tenant_id = p_tenant_id
    and is_training = true;


  -- ----------------------------------------------------------
  -- Archive test documents rather than deleting them.
  -- public.events may reference documents.
  -- ----------------------------------------------------------

  update public.documents d
  set
    archived_at = coalesce(d.archived_at, now())

  where coalesce(d.is_template, false) = false
    and d.id in (

      select dl.document_id
      from public.document_links dl
      where dl.entity_id in (
        select id
        from public.loads
        where tenant_id = p_tenant_id
          and is_training = true
      )

      union

      select dl.document_id
      from public.document_links dl
      where dl.entity_id in (
        select id
        from public.load_opportunities
        where tenant_id = p_tenant_id
          and is_training = true
      )

    );


  -- ----------------------------------------------------------
  -- Operational child records
  -- ----------------------------------------------------------

  delete from public.check_ins
  where load_id in (
    select id from public.loads
    where tenant_id = p_tenant_id
      and is_training = true
  );


  delete from public.accessorials
  where load_id in (
    select id from public.loads
    where tenant_id = p_tenant_id
      and is_training = true
  );


  delete from public.load_charges
  where load_id in (
    select id from public.loads
    where tenant_id = p_tenant_id
      and is_training = true
  );


  delete from public.load_checklist_items
  where load_id in (
    select id from public.loads
    where tenant_id = p_tenant_id
      and is_training = true
  );


  delete from public.load_private_notes
  where load_id in (
    select id from public.loads
    where tenant_id = p_tenant_id
      and is_training = true
  );


  delete from public.load_assembly_meta
  where load_id in (
    select id from public.loads
    where tenant_id = p_tenant_id
      and is_training = true
  );


  delete from public.reminders
  where load_id in (
    select id from public.loads
    where tenant_id = p_tenant_id
      and is_training = true
  );


  -- ----------------------------------------------------------
  -- Sourcing history tied to training work
  -- ----------------------------------------------------------

  delete from public.sourcing_events
  where
    load_id in (
      select id from public.loads
      where tenant_id = p_tenant_id
        and is_training = true
    )
    or
    opportunity_id in (
      select id from public.load_opportunities
      where tenant_id = p_tenant_id
        and is_training = true
    );


  -- ----------------------------------------------------------
  -- Route state points
  -- ----------------------------------------------------------

  delete from public.route_state_points rsp
  where rsp.review_id in (

    select rsr.id
    from public.route_state_reviews rsr

    where rsr.tenant_id = p_tenant_id
      and (

        rsr.load_id in (
          select id from public.loads
          where tenant_id = p_tenant_id
            and is_training = true
        )

        or

        rsr.opportunity_id in (
          select id from public.load_opportunities
          where tenant_id = p_tenant_id
            and is_training = true
        )

      )
  );


  -- ----------------------------------------------------------
  -- State reviews
  -- ----------------------------------------------------------

  delete from public.route_state_reviews rsr
  where rsr.tenant_id = p_tenant_id
    and (

      rsr.load_id in (
        select id from public.loads
        where tenant_id = p_tenant_id
          and is_training = true
      )

      or

      rsr.opportunity_id in (
        select id from public.load_opportunities
        where tenant_id = p_tenant_id
          and is_training = true
      )

    );


  -- ----------------------------------------------------------
  -- Route plans
  -- ----------------------------------------------------------

  delete from public.route_plans rp
  where rp.tenant_id = p_tenant_id
    and (

      rp.load_id in (
        select id from public.loads
        where tenant_id = p_tenant_id
          and is_training = true
      )

      or

      rp.opportunity_id in (
        select id from public.load_opportunities
        where tenant_id = p_tenant_id
          and is_training = true
      )

    );


  -- ----------------------------------------------------------
  -- Permits / Escorts
  -- ----------------------------------------------------------

  delete from public.permits
  where tenant_id = p_tenant_id
    and load_id in (
      select id from public.loads
      where tenant_id = p_tenant_id
        and is_training = true
    );


  delete from public.escort_assignments
  where tenant_id = p_tenant_id
    and load_id in (
      select id from public.loads
      where tenant_id = p_tenant_id
        and is_training = true
    );


  -- ----------------------------------------------------------
  -- Document links
  -- ----------------------------------------------------------

  delete from public.document_links
  where
    entity_id in (
      select id from public.loads
      where tenant_id = p_tenant_id
        and is_training = true
    )
    or
    entity_id in (
      select id from public.load_opportunities
      where tenant_id = p_tenant_id
        and is_training = true
    );


  -- ----------------------------------------------------------
  -- Close / hide test opportunities
  -- ----------------------------------------------------------

  update public.load_opportunities
  set
    route_planning_hidden = true,
    closed_at = coalesce(closed_at, now()),
    load_id = null

  where tenant_id = p_tenant_id
    and is_training = true;


  -- ----------------------------------------------------------
  -- Remove fleet records from active use
  -- ----------------------------------------------------------

  update public.equipment
  set
    status = 'inactive',
    default_driver_id = null,
    updated_at = now()

  where tenant_id = p_tenant_id
    and is_training = true;


  update public.drivers
  set
    archived_at = coalesce(archived_at, now()),
    updated_at = now()

  where tenant_id = p_tenant_id
    and is_training = true;


  update public.carriers
  set
    archived_at = coalesce(archived_at, now()),
    updated_at = now()

  where tenant_id = p_tenant_id
    and is_training = true;


  update public.brokers
  set
    archived_at = coalesce(archived_at, now()),
    updated_at = now()

  where tenant_id = p_tenant_id
    and is_training = true;


  update public.facilities
  set
    archived_at = coalesce(archived_at, now()),
    updated_at = now()

  where tenant_id = p_tenant_id
    and is_training = true;

end;
$$;


comment on function public.reset_training_data(uuid)
is
'Resets training records for a tenant while preserving append-only audit events.';


-- Raw reset is not available directly from the public website.
revoke all on function public.reset_training_data(uuid) from public;
revoke all on function public.reset_training_data(uuid) from anon;
revoke all on function public.reset_training_data(uuid) from authenticated;
