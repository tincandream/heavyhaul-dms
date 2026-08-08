-- 022_feed_broker_name.sql
alter table load_email_feeds add column if not exists broker_name text;
alter table load_email_feeds alter column company_id drop not null;
