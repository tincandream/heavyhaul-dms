-- ============================================================
-- 036_sourcing_followups_to_calendar.sql
-- Heavy Haul Command
-- ============================================================

alter table public.calendar_events
  add column if not exists sourcing_event_id uuid;

create unique index if not exists calendar_events_sourcing_event_unique
  on public.calendar_events (sourcing_event_id)
  where sourcing_event_id is not null;

create or replace function public.sync_sourcing_followup_to_calendar()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  calendar_title text;
  calendar_notes text;
begin
  if new.follow_up_at is null then
    delete from public.calendar_events
    where sourcing_event_id = new.id;
    return new;
  end if;

  calendar_title :=
    case new.event_type
      when 'follow_up_scheduled' then 'Sourcing Follow-up'
      when 'broker_contacted' then 'Broker Follow-up'
      when 'carrier_contacted' then 'Carrier Follow-up'
      when 'quote_prepared' then 'Quote Follow-up'
      when 'quote_sent' then 'Quote Follow-up'
      when 'rate_negotiated' then 'Rate Follow-up'
      when 'call_completed' then 'Call Follow-up'
      else 'Sourcing Follow-up'
    end;

  if new.broker_name is not null then
    calendar_title := calendar_title || ' — ' || new.broker_name;
  elsif new.carrier_name is not null then
    calendar_title := calendar_title || ' — ' || new.carrier_name;
  elsif new.contact_name is not null then
    calendar_title := calendar_title || ' — ' || new.contact_name;
  elsif new.title is not null then
    calendar_title := calendar_title || ' — ' || new.title;
  end if;

  calendar_notes :=
    concat_ws(
      E'\n',
      new.title,
      new.detail,
      case
        when new.lane_origin is not null
          or new.lane_destination is not null
        then concat_ws(' → ', new.lane_origin, new.lane_destination)
        else null
      end,
      case
        when new.rate_amount is not null
        then 'Rate: $' || trim(to_char(new.rate_amount, 'FM9999999990.00'))
        else null
      end
    );

  insert into public.calendar_events (
    tenant_id,
    load_id,
    sourcing_event_id,
    title,
    event_type,
    starts_at,
    notes,
    completed
  )
  values (
    new.tenant_id,
    new.load_id,
    new.id,
    calendar_title,
    'sourcing',
    new.follow_up_at,
    nullif(calendar_notes, ''),
    false
  )
  on conflict (sourcing_event_id)
  where sourcing_event_id is not null
  do update set
    tenant_id = excluded.tenant_id,
    load_id = excluded.load_id,
    title = excluded.title,
    event_type = excluded.event_type,
    starts_at = excluded.starts_at,
    notes = excluded.notes,
    completed = false,
    completed_at = null,
    updated_at = now();

  return new;
end;
$$;

drop trigger if exists sourcing_followup_calendar_sync
  on public.sourcing_events;

create trigger sourcing_followup_calendar_sync
after insert or update of
  follow_up_at,
  title,
  detail,
  broker_name,
  carrier_name,
  contact_name,
  lane_origin,
  lane_destination,
  rate_amount,
  load_id
on public.sourcing_events
for each row
execute function public.sync_sourcing_followup_to_calendar();

insert into public.calendar_events (
  tenant_id,
  load_id,
  sourcing_event_id,
  title,
  event_type,
  starts_at,
  notes,
  completed
)
select
  se.tenant_id,
  se.load_id,
  se.id,
  case
    when se.broker_name is not null
      then 'Sourcing Follow-up — ' || se.broker_name
    when se.carrier_name is not null
      then 'Sourcing Follow-up — ' || se.carrier_name
    when se.contact_name is not null
      then 'Sourcing Follow-up — ' || se.contact_name
    else 'Sourcing Follow-up — ' || se.title
  end,
  'sourcing',
  se.follow_up_at,
  concat_ws(
    E'\n',
    se.title,
    se.detail,
    case
      when se.lane_origin is not null
        or se.lane_destination is not null
      then concat_ws(' → ', se.lane_origin, se.lane_destination)
      else null
    end
  ),
  false
from public.sourcing_events se
where se.follow_up_at is not null
on conflict (sourcing_event_id)
where sourcing_event_id is not null
do nothing;

select
  column_name,
  data_type
from information_schema.columns
where table_schema = 'public'
  and table_name = 'calendar_events'
  and column_name = 'sourcing_event_id';

select
  count(*) as sourcing_followups_on_calendar
from public.calendar_events
where sourcing_event_id is not null;
