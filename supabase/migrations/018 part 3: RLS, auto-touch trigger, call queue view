-- 018 part 3: RLS, auto-touch trigger, call queue view

-- ===== RLS on both new tables =====
alter table load_opportunities enable row level security;
alter table crm_activities     enable row level security;

create policy tenant_read on load_opportunities
  for select using (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']));
create policy tenant_insert on load_opportunities
  for insert with check (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']));
create policy tenant_update on load_opportunities
  for update using (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']))
  with check (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']));
create policy tenant_delete on load_opportunities
  for delete using (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']));

create policy tenant_read on crm_activities
  for select using (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']));
create policy tenant_insert on crm_activities
  for insert with check (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']));
create policy tenant_update on crm_activities
  for update using (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']))
  with check (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']));
create policy tenant_delete on crm_activities
  for delete using (tenant_id = current_tenant_id()
    and current_user_role() = any (array['owner','admin','dispatcher']));

-- ===== auto-touch: logging an activity updates the company's contact timing =====
create or replace function fn_touch_company() returns trigger as $$
begin
  update companies
     set last_contacted_at = new.occurred_at,
         next_touch_date   = coalesce(
           new.next_action_due,
           (new.occurred_at + (coalesce(follow_up_days,14) || ' days')::interval)::date),
         updated_at = now()
   where id = new.company_id;

  if new.contact_id is not null then
    update company_contacts
       set last_contacted_at = new.occurred_at
     where id = new.contact_id;
  end if;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_touch_company on crm_activities;
create trigger trg_touch_company
  after insert on crm_activities
  for each row execute function fn_touch_company();

-- ===== the call queue view =====
create or replace view v_call_queue as
select
  c.id            as company_id,
  c.legal_name,
  c.company_type,
  c.status,
  c.tier,
  c.main_phone,
  c.next_touch_date,
  c.last_contacted_at,
  c.sends_direct_freight,
  ct.id           as contact_id,
  ct.first_name,
  ct.last_name,
  coalesce(ct.direct_phone, ct.mobile, c.main_phone) as dial,
  ct.best_time_to_call
from companies c
left join company_contacts ct
       on ct.company_id = c.id and ct.is_primary and not ct.do_not_contact
where c.status not in ('do_not_use','on_hold')
  and (c.next_touch_date is null or c.next_touch_date <= current_date)
order by
  case c.status
    when 'pending_approval' then 1
    when 'packet_sent'      then 2
    when 'contacted'        then 3
    else 4
  end,
  c.next_touch_date nulls first;
