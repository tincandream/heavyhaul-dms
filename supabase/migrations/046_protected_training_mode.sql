-- ============================================================
-- 046_protected_training_mode.sql
--
-- PASSWORD-PROTECTED TRAINING MODE
--
-- Normal mode:
--   New operational records are ALWAYS is_training = false.
--
-- Training mode:
--   User must unlock Training Mode with a separate password.
--   New operational records are automatically marked
--   is_training = true.
--
-- The password itself is never stored in the frontend.
-- Only a bcrypt hash is stored in Supabase.
-- ============================================================


-- ============================================================
-- 1. PASSWORD HASHING
-- ============================================================

create extension if not exists pgcrypto;



-- ============================================================
-- 2. TRAINING MODE SETTINGS
-- One password hash per tenant.
-- ============================================================

create table if not exists public.training_mode_settings (

  tenant_id uuid primary key
    references public.tenants(id)
    on delete cascade,

  password_hash text not null,

  created_at timestamptz
    not null
    default now(),

  updated_at timestamptz
    not null
    default now()

);



-- ============================================================
-- 3. ACTIVE TRAINING SESSIONS
-- One active session per signed-in user.
-- ============================================================

create table if not exists public.training_mode_sessions (

  auth_uid uuid primary key,

  tenant_id uuid not null
    references public.tenants(id)
    on delete cascade,

  enabled_at timestamptz
    not null
    default now(),

  expires_at timestamptz
    not null

);


create index if not exists
training_mode_sessions_tenant_idx
on public.training_mode_sessions(
  tenant_id
);



-- ============================================================
-- 4. PROTECT TRAINING TABLES
-- Browser access will happen through RPC functions.
-- ============================================================

alter table public.training_mode_settings
enable row level security;


alter table public.training_mode_sessions
enable row level security;



-- ============================================================
-- 5. SET / CHANGE TRAINING PASSWORD
--
-- IMPORTANT:
-- Run this from the Supabase SQL Editor only.
--
-- We explicitly prevent anon/authenticated browser users
-- from executing this function.
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

    raise exception
      'Tenant ID is required.';

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

    crypt(
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
      crypt(
        p_password,
        extensions.gen_salt('bf')
      ),

    updated_at =
      now();


end;

$$;



revoke all
on function public.set_training_password(
  uuid,
  text
)
from public;


revoke all
on function public.set_training_password(
  uuid,
  text
)
from anon;


revoke all
on function public.set_training_password(
  uuid,
  text
)
from authenticated;



-- ============================================================
-- 6. UNLOCK TRAINING MODE
--
-- Default session = 4 hours.
--
-- Minimum = 15 minutes.
-- Maximum = 8 hours.
-- ============================================================

create or replace function public.unlock_training_mode(

  p_password text,

  p_minutes integer
    default 240

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

    raise exception
      'You must be signed in.';

  end if;



  select
    au.tenant_id

  into
    v_tenant_id

  from
    public.app_users au

  where
    au.auth_uid =
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



  select
    s.password_hash

  into
    v_hash

  from
    public.training_mode_settings s

  where
    s.tenant_id =
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



revoke all
on function public.unlock_training_mode(
  text,
  integer
)
from public;


grant execute
on function public.unlock_training_mode(
  text,
  integer
)
to authenticated;



-- ============================================================
-- 7. CHECK WHETHER TRAINING MODE IS ACTIVE
-- ============================================================

create or replace function public.training_mode_is_active()

returns boolean

language sql

stable

security definer

set search_path = public

as $$


  select exists (

    select 1

    from
      public.training_mode_sessions s

    join
      public.app_users au

      on au.auth_uid =
         s.auth_uid

      and au.tenant_id =
          s.tenant_id


    where
      s.auth_uid =
        auth.uid()

      and s.expires_at >
          now()

      and coalesce(
        au.status,
        'active'
      ) = 'active'

  );


$$;



revoke all
on function public.training_mode_is_active()
from public;


grant execute
on function public.training_mode_is_active()
to authenticated;



-- ============================================================
-- 8. TRAINING MODE STATUS
--
-- This will later power the visible:
--
--     TRAINING MODE
--
-- banner in the application.
-- ============================================================

create or replace function public.get_training_mode_status()

returns jsonb

language plpgsql

stable

security definer

set search_path = public

as $$


declare

  v_auth_uid uuid;

  v_tenant_id uuid;

  v_expires timestamptz;


begin


  v_auth_uid =
    auth.uid();



  if v_auth_uid is null then

    return
      jsonb_build_object(

        'active',
        false,

        'expires_at',
        null

      );

  end if;



  select

    s.tenant_id,

    s.expires_at

  into

    v_tenant_id,

    v_expires

  from
    public.training_mode_sessions s

  where
    s.auth_uid =
      v_auth_uid

    and s.expires_at >
        now()

  limit 1;



  return
    jsonb_build_object(

      'active',
      v_expires is not null,

      'tenant_id',
      v_tenant_id,

      'expires_at',
      v_expires

    );


end;

$$;



revoke all
on function public.get_training_mode_status()
from public;


grant execute
on function public.get_training_mode_status()
to authenticated;



-- ============================================================
-- 9. EXIT TRAINING MODE
-- ============================================================

create or replace function public.disable_training_mode()

returns void

language sql

security definer

set search_path = public

as $$


  delete
  from public.training_mode_sessions

  where auth_uid =
    auth.uid();


$$;



revoke all
on function public.disable_training_mode()
from public;


grant execute
on function public.disable_training_mode()
to authenticated;



-- ============================================================
-- 10. AUTOMATIC TRAINING FLAG
--
-- THIS IS THE MAIN SAFEGUARD.
--
-- Training Mode OFF:
--     is_training = false
--
-- Training Mode ON:
--     is_training = true
--
-- Even if JavaScript mistakenly sends:
--
--     is_training: true
--
-- the database overrides it.
-- ============================================================

create or replace function public.apply_protected_training_flag()

returns trigger

language plpgsql

security definer

set search_path = public

as $$


begin


  new.is_training =
    public.training_mode_is_active();


  return new;


end;

$$;



-- ============================================================
-- 11. LOAD TRIGGER
-- ============================================================

drop trigger if exists
trg_training_flag_loads
on public.loads;


create trigger
trg_training_flag_loads

before insert
on public.loads

for each row

execute function
public.apply_protected_training_flag();



-- ============================================================
-- 12. OPPORTUNITY TRIGGER
-- ============================================================

drop trigger if exists
trg_training_flag_opportunities
on public.load_opportunities;


create trigger
trg_training_flag_opportunities

before insert
on public.load_opportunities

for each row

execute function
public.apply_protected_training_flag();



-- ============================================================
-- 13. CARRIER TRIGGER
-- ============================================================

drop trigger if exists
trg_training_flag_carriers
on public.carriers;


create trigger
trg_training_flag_carriers

before insert
on public.carriers

for each row

execute function
public.apply_protected_training_flag();



-- ============================================================
-- 14. DRIVER TRIGGER
-- ============================================================

drop trigger if exists
trg_training_flag_drivers
on public.drivers;


create trigger
trg_training_flag_drivers

before insert
on public.drivers

for each row

execute function
public.apply_protected_training_flag();



-- ============================================================
-- 15. EQUIPMENT TRIGGER
-- ============================================================

drop trigger if exists
trg_training_flag_equipment
on public.equipment;


create trigger
trg_training_flag_equipment

before insert
on public.equipment

for each row

execute function
public.apply_protected_training_flag();



-- ============================================================
-- 16. BROKER TRIGGER
-- ============================================================

drop trigger if exists
trg_training_flag_brokers
on public.brokers;


create trigger
trg_training_flag_brokers

before insert
on public.brokers

for each row

execute function
public.apply_protected_training_flag();



-- ============================================================
-- 17. FACILITY TRIGGER
-- ============================================================

drop trigger if exists
trg_training_flag_facilities
on public.facilities;


create trigger
trg_training_flag_facilities

before insert
on public.facilities

for each row

execute function
public.apply_protected_training_flag();



-- ============================================================
-- 18. PASSWORD-PROTECTED TRAINING RESET
--
-- Reset requires entering the Training Mode password AGAIN.
--
-- This prevents an accidental click on a Reset button.
--
-- Training Mode automatically shuts off after reset.
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



  select
    au.tenant_id

  into
    v_tenant_id

  from
    public.app_users au

  where
    au.auth_uid =
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



  select
    s.password_hash

  into
    v_hash

  from
    public.training_mode_settings s

  where
    s.tenant_id =
      v_tenant_id;



  if v_hash is null then

    raise exception
      'Training Mode password has not been configured.';

  end if;



  if p_password is null
     or crypt(
       p_password,
       v_hash
     ) <> v_hash then

    raise exception
      'Incorrect Training Mode password.';

  end if;



  perform
    public.reset_training_data(
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



revoke all
on function public.reset_current_training_data(text)
from public;


grant execute
on function public.reset_current_training_data(text)
to authenticated;



-- ============================================================
-- 19. CLEAN UP EXPIRED SESSIONS
-- ============================================================

delete
from public.training_mode_sessions

where expires_at <= now();
