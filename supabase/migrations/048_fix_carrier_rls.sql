-- ============================================================
-- 048_fix_carrier_rls.sql
-- Heavy Haul Command
--
-- Replace helper-function carrier RLS checks with direct
-- app_users tenant/role checks.
-- ============================================================


alter table public.carriers
  enable row level security;


-- ============================================================
-- REMOVE OLD POLICIES
-- ============================================================

drop policy if exists tenant_insert
  on public.carriers;

drop policy if exists tenant_read
  on public.carriers;

drop policy if exists tenant_update
  on public.carriers;


-- ============================================================
-- READ
-- ============================================================

create policy carrier_tenant_read
on public.carriers
for select
to authenticated
using (

  exists (

    select 1

    from public.app_users au

    where au.auth_uid = auth.uid()

      and au.tenant_id =
          carriers.tenant_id

      and au.status =
          'active'

  )

);


-- ============================================================
-- INSERT
-- ============================================================

create policy carrier_tenant_insert
on public.carriers
for insert
to authenticated
with check (

  exists (

    select 1

    from public.app_users au

    where au.auth_uid = auth.uid()

      and au.tenant_id =
          carriers.tenant_id

      and au.status =
          'active'

      and au.role in (
        'owner',
        'admin',
        'dispatcher'
      )

  )

);


-- ============================================================
-- UPDATE
-- ============================================================

create policy carrier_tenant_update
on public.carriers
for update
to authenticated
using (

  exists (

    select 1

    from public.app_users au

    where au.auth_uid = auth.uid()

      and au.tenant_id =
          carriers.tenant_id

      and au.status =
          'active'

      and au.role in (
        'owner',
        'admin',
        'dispatcher'
      )

  )

)
with check (

  exists (

    select 1

    from public.app_users au

    where au.auth_uid = auth.uid()

      and au.tenant_id =
          carriers.tenant_id

      and au.status =
          'active'

      and au.role in (
        'owner',
        'admin',
        'dispatcher'
      )

  )

);


-- ============================================================
-- VERIFY
-- ============================================================

select
  policyname,
  cmd,
  roles,
  qual,
  with_check
from pg_policies
where schemaname = 'public'
  and tablename = 'carriers'
order by policyname;
