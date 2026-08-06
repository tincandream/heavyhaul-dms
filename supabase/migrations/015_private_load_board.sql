-- 015_private_load_board.sql

alter table companies
  add column if not exists sends_direct_freight  boolean default false,
  add column if not exists direct_freight_notes  text,
  add column if not exists freight_source_type   text
    check (freight_source_type in ('direct_shipper','broker_reseller','co_broker','mixed','unknown'))
    default 'unknown',
  add column if not exists has_portal            boolean default false,
  add column if not exists sends_load_emails     boolean default false,
  add column if not exists email_list_subscribed boolean default false,
  add column if not exists email_frequency       text
    check (email_frequency in ('realtime','multiple_daily','daily','weekly','sporadic','none')),
  add column if not exists avg_loads_per_week    int,
  add column if not exists first_load_booked_at  date,
  add column if not exists last_load_booked_at   date,
  add column if not exists loads_booked_count    int default 0;

create index on companies (sends_direct_freight) where sends_direct_freight;
create index on companies (has_portal) where has_portal;
