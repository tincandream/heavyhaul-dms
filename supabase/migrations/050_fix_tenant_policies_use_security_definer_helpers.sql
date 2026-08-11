-- 050_fix_tenant_policies_use_security_definer_helpers.sql
-- Same defect as 048/049: these policies query app_users directly inside the
-- policy, which subjects the subquery to app_users' own RLS. Replace with the
-- SECURITY DEFINER helper, matching the rest of the schema.
--
-- Also tightens role from {public} to {authenticated}, and picks up the
-- status = 'active' check that current_tenant_id() already enforces.

do $$
declare
  t text;
begin
  foreach t in array array[
    'route_plans',
    'golden_routes',
    'accessorials',
    'sourcing_events',
    'load_assembly_meta',
    'carrier_profiles',
    'route_state_reviews',
    'route_state_points'
  ]
  loop
    execute format(
      'drop policy if exists %I on public.%I',
      t || '_tenant_access', t
    );

    execute format(
      'create policy %I on public.%I
         for all to authenticated
         using (tenant_id = current_tenant_id())
         with check (tenant_id = current_tenant_id())',
      t || '_tenant_access', t
    );
  end loop;
end $$;
