-- ============================================================
-- 047_fix_training_password_functions.sql
--
-- Fix pgcrypto function schema resolution.
-- Supabase has crypt() and gen_salt() in the extensions schema.
-- ============================================================
select public.set_training_password(
  'e9dee1c9-7fc8-4caa-ab63-44328eaf532d'::uuid,
  'TestTraining'
);

-- ============================================================
-- 1. SET / CHANGE TRAINING PASSWORD
-- ============================================================

create or replace function public.set_training_password(
  p_tenant_id uuid,
  p_password text
)
returns void
language plpgsql
security definer
set search_path = public
as $$

begin

  if p_tenant_id is null then
    raise exception 'Tenant ID is required.';
  end if;


  if p_password is null
     or length(trim(p_password)) < 8 then

    raise exception
      'Training password must be at least 8 characters.';

  end if;


  insert into public.training_mode_settings (
    tenant_id,
    password_hash,
    created_at,
    updated_at
  )

  values (
    p_tenant_id,

    extensions.crypt(
      p_password,
      extensions.gen_salt('bf')
    ),

    now(),
    now()
  )

  on conflict (tenant_id)

  do update
  set
    password_hash =
      extensions.crypt(
        p_password,
        extensions.gen_salt('bf')
      ),

    updated_at = now();

end;
$$;



-- ============================================================
-- 2. UNLOCK TRAINING MODE
-- ============================================================

create or replace function public.unlock_training_mode(
  p_password text,
  p_minutes integer default 240
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$

declare

  v_auth_uid uuid;
  v_tenant_id uuid;
  v_hash text;
  v_minutes integer;
  v_expires timestamptz;

begin

  v_auth_uid =
    auth.uid();


  if v_auth_uid is null then
    raise exception 'You must be signed in.';
  end if;


  select au.tenant_id
  into v_tenant_id

  from public.app_users au

  where au.auth_uid =
        v_auth_uid

    and coalesce(
      au.status,
      'active'
    ) = 'active'

  limit 1;


  if v_tenant_id is null then

    raise exception
      'Application user profile not found.';

  end if;


  select s.password_hash
  into v_hash

  from public.training_mode_settings s

  where s.tenant_id =
        v_tenant_id;


  if v_hash is null then

    raise exception
      'Training Mode password has not been configured.';

  end if;


  if p_password is null
     or extensions.crypt(
       p_password,
       v_hash
     ) <> v_hash then

    raise exception
      'Incorrect Training Mode password.';

  end if;


  v_minutes =
    greatest(
      15,
      least(
        coalesce(
          p_minutes,
          240
        ),
        480
      )
    );


  v_expires =
    now()
    +
    make_interval(
      mins => v_minutes
    );


  insert into public.training_mode_sessions (
    auth_uid,
    tenant_id,
    enabled_at,
    expires_at
  )

  values (
    v_auth_uid,
    v_tenant_id,
    now(),
    v_expires
  )

  on conflict (auth_uid)

  do update
  set
    tenant_id =
      excluded.tenant_id,

    enabled_at =
      excluded.enabled_at,

    expires_at =
      excluded.expires_at;


  return
    jsonb_build_object(
      'active',
      true,

      'tenant_id',
      v_tenant_id,

      'expires_at',
      v_expires
    );

end;
$$;



-- ============================================================
-- 3. PASSWORD-PROTECTED RESET
-- ============================================================

create or replace function public.reset_current_training_data(
  p_password text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$

declare

  v_auth_uid uuid;
  v_tenant_id uuid;
  v_hash text;

begin

  v_auth_uid =
    auth.uid();


  if v_auth_uid is null then

    raise exception
      'You must be signed in.';

  end if;


  select au.tenant_id
  into v_tenant_id

  from public.app_users au

  where au.auth_uid =
        v_auth_uid

    and coalesce(
      au.status,
      'active'
    ) = 'active'

  limit 1;


  if v_tenant_id is null then

    raise exception
      'Application user profile not found.';

  end if;


  select s.password_hash
  into v_hash

  from public.training_mode_settings s

  where s.tenant_id =
        v_tenant_id;


  if v_hash is null then

    raise exception
      'Training Mode password has not been configured.';

  end if;


  if p_password is null
     or extensions.crypt(
       p_password,
       v_hash
     ) <> v_hash then

    raise exception
      'Incorrect Training Mode password.';

  end if;


  perform public.reset_training_data(
    v_tenant_id
  );


  delete
  from public.training_mode_sessions

  where auth_uid =
        v_auth_uid;


  return
    jsonb_build_object(
      'reset',
      true,

      'training_mode_active',
      false
    );

end;
$$;



-- ============================================================
-- 4. PERMISSIONS
-- ============================================================

revoke all
on function public.set_training_password(uuid, text)
from public;

revoke all
on function public.set_training_password(uuid, text)
from anon;

revoke all
on function public.set_training_password(uuid, text)
from authenticated;


revoke all
on function public.unlock_training_mode(text, integer)
from public;

grant execute
on function public.unlock_training_mode(text, integer)
to authenticated;


revoke all
on function public.reset_current_training_data(text)
from public;

grant execute
on function public.reset_current_training_data(text)
to authenticated;
