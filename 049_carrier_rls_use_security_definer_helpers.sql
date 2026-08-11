-- 049_carrier_rls_use_security_definer_helpers.sql
-- Carriers policies must not query app_users directly: that subquery is
-- subject to app_users' own RLS. Use the SECURITY DEFINER helpers, which is
-- the pattern every other table in this schema already uses successfully.

drop policy if exists carrier_tenant_read   on public.carriers;
drop policy if exists carrier_tenant_insert on public.carriers;
drop policy if exists carrier_tenant_update on public.carriers;
drop policy if exists carrier_tenant_delete on public.carriers;

create policy carrier_tenant_read on public.carriers
  for select to authenticated
  using (tenant_id = current_tenant_id());

create policy carrier_tenant_insert on public.carriers
  for insert to authenticated
  with check (
    tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher'])
  );

create policy carrier_tenant_update on public.carriers
  for update to authenticated
  using (
    tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher'])
  )
  with check (
    tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher'])
  );

create policy carrier_tenant_delete on public.carriers
  for delete to authenticated
  using (
    tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher'])
  );
