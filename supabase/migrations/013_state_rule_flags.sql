create or replace view v_load_red_flags
with (security_invoker = on) as
select
  l.id as load_id,
  l.load_number,
  array_remove(array[
    case when l.width_in is null or l.height_in is null
           or l.length_in is null            then 'Missing dimensions' end,
    case when l.weight_lb is null            then 'Missing weight' end,
    case when l.trailer_id is null
          and l.status <> 'quoted'           then 'No trailer assigned' end,
    case when l.driver_id is null
          and l.status <> 'quoted'           then 'No driver assigned' end,
    case when l.driver_hours_remaining_min is not null
          and l.driver_hours_remaining_min < 240
                                             then 'Driver under 4 hours HOS' end,

    -- NEW: route states with no rules on file
    case when exists (
      select 1 from load_legs lg
       where lg.load_id = l.id
         and not exists (select 1 from state_permit_rules r
                          where r.state = lg.state))
      then 'No permit rules on file for: ' || (
        select string_agg(distinct lg.state, ', ' order by lg.state)
          from load_legs lg
         where lg.load_id = l.id
           and not exists (select 1 from state_permit_rules r
                            where r.state = lg.state))
        || ' — verify manually' end,

    -- NEW: rules older than a year
    case when exists (
      select 1 from load_legs lg
      join state_permit_rules r on r.state = lg.state
       where lg.load_id = l.id
         and (r.verified_on is null or r.verified_on < current_date - 365))
      then 'Permit rules not verified in over a year' end,

    case when (coalesce(l.width_in,0)  > 102 or coalesce(l.height_in,0) > 162
            or coalesce(l.length_in,0) > 636 or coalesce(l.weight_lb,0) > 80000)
          and not exists (select 1 from permits p where p.load_id = l.id)
                                             then 'Oversize with no permit plan' end,
    case when exists (select 1 from permits p
                       where p.load_id = l.id and p.status = 'issued'
                         and not p.driver_has_permit)
                                             then 'Driver does not have issued permit' end,
    case when ps.has_window_conflict         then 'Permit window conflicts with travel date' end,
    case when exists (select 1 from escort_assignments e
                       where e.load_id = l.id
                         and e.status in ('needed','quoted')
                         and l.status not in ('quoted','booked'))
                                             then 'Escorts not arranged' end,
    case when exists (select 1 from escort_assignments e
                       where e.load_id = l.id
                         and e.status in ('confirmed','booked')
                         and not e.contacts_exchanged)
                                             then 'Escort and driver contacts not exchanged' end,
    case when l.rate_con_matches_agreement is false
                                             then 'Rate confirmation does not match agreement' end,
    case when c.requires_approval_before_booking
          and l.carrier_approved_at is null
          and l.status <> 'quoted'            then 'Carrier approval required and not obtained' end,
    case when c.min_load_revenue is not null
          and coalesce(l.linehaul_rate,0) + coalesce(l.fuel_surcharge,0)
              < c.min_load_revenue            then 'Below carrier minimum revenue' end,
    case when c.max_width_in is not null
          and coalesce(l.width_in,0) > c.max_width_in
                                             then 'Exceeds carrier maximum width' end,
    case when l.status in ('delivered','pod_pending')
          and not exists (select 1 from documents d
                          join document_links dl on dl.document_id = d.id
                          where dl.entity_type='load' and dl.entity_id = l.id
                            and d.doc_type='pod')
                                             then 'Delivered with no POD on file' end
  ], null) as flags
from loads l
left join carriers c on c.id = l.carrier_id
left join v_load_permit_status ps on ps.load_id = l.id
where l.archived_at is null;

grant select on v_load_red_flags to authenticated;
