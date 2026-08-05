-- ============================================================
-- 014_event_types.sql
-- Adds event types the app writes but 006 didn't include:
--   charge_added, charge_removed  (Expenses tab)
--   check_in                      (check-in logging)
-- Replaces the events_event_type_check constraint in full.
-- ============================================================

alter table events drop constraint events_event_type_check;

alter table events add constraint events_event_type_check
  check (event_type = any (array[
    'load_created','load_assigned','rate_con_received','driver_assigned',
    'truck_assigned','dispatched','arrived_shipper','loading_started',
    'pickup_completed','departed_shipper','fuel_stop','rest_break',
    'break_30_minute','reset_10_hour','escort_confirmed','escort_joined',
    'escort_changed','escort_released','state_entered','weigh_station',
    'port_of_entry','inspection','permit_applied','permit_approved',
    'permit_revision','weather_delay','traffic_delay','road_closure',
    'mechanical_breakdown','repair_completed','accident','hold_started',
    'hold_cleared','check_call','appointment_updated','arrived_receiver',
    'unloading_started','unloading_completed','delivery_completed',
    'pod_uploaded','load_closed','invoice_sent','payment_received',
    'call','email','sms','note','status_change','upload','permit_update',
    'escort_update','appointment','issue','system',
    'charge_added','charge_removed','check_in'
  ]));
