-- 020_opportunity_broker_name.sql
alter table load_opportunities
  add column if not exists broker_name text;
