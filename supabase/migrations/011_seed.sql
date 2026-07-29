do $seed$
declare
  v_tenant   uuid;
  v_carrier  uuid;
  v_b_tql    uuid;
  v_b_mercer uuid;
  v_f_mem    uuid;
  v_f_den    uuid;
  v_f_lr     uuid;
  v_f_yard   uuid;
  v_d_ricky  uuid;
  v_d_mona   uuid;
  v_d_del    uuid;
  v_d_junior uuid;
  v_t104 uuid; v_t112 uuid; v_t118 uuid; v_t121 uuid;
  v_r104 uuid; v_r112 uuid; v_r118 uuid; v_r121 uuid;
  v_l2841 uuid; v_l2847 uuid; v_l2839 uuid; v_l2852 uuid;
begin
  select id into v_tenant from tenants limit 1;

  insert into carriers (tenant_id, legal_name, dba_name, mc_number, dot_number,
                        phone, city, state, status, escort_preferences)
  values (v_tenant, 'Redland Heavy Transport LLC', 'Redland Heavy',
          'MC-884201', '2916440', '501-555-0142', 'Little Rock', 'AR', 'active',
          'Prefers Wasatch for high pole work west of KS')
  returning id into v_carrier;

  insert into brokers (tenant_id, name, mc_number, phone, email,
                       payment_terms_days, quickpay_available, quickpay_fee_pct,
                       quickpay_days, status)
  values (v_tenant, 'TQL', 'MC-460013', '800-555-0100', 'dispatch@example-tql.com',
          30, true, 3.00, 2, 'active')
  returning id into v_b_tql;

  insert into brokers (tenant_id, name, mc_number, phone, email,
                       payment_terms_days, quickpay_available, status)
  values (v_tenant, 'Mercer Freight Group', 'MC-118742', '888-555-0177',
          'loads@example-mercer.com', 21, false, 'active')
  returning id into v_b_mercer;

  insert into facilities (tenant_id, name, role_hint, address_line1, city, state,
                          postal_code, appointment_required, loading_equipment,
                          hours_notes)
  values (v_tenant, 'Delta Machinery Yard', 'shipper', '4400 Getwell Rd',
          'Memphis', 'TN', '38118', true, '{crane,forklift}',
          'Mon-Fri 6a-4p, no weekend loading')
  returning id into v_f_mem;

  insert into facilities (tenant_id, name, role_hint, address_line1, city, state,
                          postal_code, appointment_required, loading_equipment)
  values (v_tenant, 'Front Range Equipment', 'receiver', '8801 E 96th Ave',
          'Denver', 'CO', '80229', true, '{crane}')
  returning id into v_f_den;

  insert into facilities (tenant_id, name, role_hint, address_line1, city, state,
                          postal_code, appointment_required)
  values (v_tenant, 'Arkansas Steel Works', 'both', '1200 Industrial Dr',
          'Little Rock', 'AR', '72202', false)
  returning id into v_f_lr;

  insert into facilities (tenant_id, name, role_hint, city, state, postal_code)
  values (v_tenant, 'Redland Yard - Arlington', 'yard', 'Arlington', 'TN', '38002')
  returning id into v_f_yard;

  insert into drivers (tenant_id, carrier_id, first_name, last_name, phone,
                       cdl_number, cdl_state, endorsements, oversize_experienced, status)
  values (v_tenant, v_carrier, 'Ricky', 'Dale', '901-555-0188',
          'D4472119', 'TN', '{T,X}', true, 'active')
  returning id into v_d_ricky;

  insert into drivers (tenant_id, carrier_id, first_name, last_name, phone,
                       cdl_number, cdl_state, endorsements, oversize_experienced, status)
  values (v_tenant, v_carrier, 'Mona', 'Reyes', '501-555-0231',
          'A9920417', 'AR', '{T}', true, 'active')
  returning id into v_d_mona;

  insert into drivers (tenant_id, carrier_id, first_name, last_name, phone,
                       cdl_number, cdl_state, oversize_experienced, status)
  values (v_tenant, v_carrier, 'Del', 'Hooper', '870-555-0164',
          'A7781206', 'AR', true, 'active')
  returning id into v_d_del;

  insert into drivers (tenant_id, carrier_id, first_name, last_name, phone,
                       cdl_number, cdl_state, oversize_experienced, status)
  values (v_tenant, v_carrier, 'Junior', 'Watts', '318-555-0119',
          'L3390882', 'LA', false, 'active')
  returning id into v_d_junior;

  insert into equipment (tenant_id, carrier_id, unit_number, equipment_type, make,
                         model, year, axle_count, empty_weight_lb,
                         default_driver_id, operational_status, status)
  values (v_tenant, v_carrier, 'T-104', 'tractor', 'Peterbilt', '389', 2021,
          3, 21400, v_d_ricky, 'assigned', 'active')
  returning id into v_t104;

  insert into equipment (tenant_id, carrier_id, unit_number, equipment_type, make,
                         model, year, axle_count, empty_weight_lb,
                         default_driver_id, operational_status, status)
  values (v_tenant, v_carrier, 'T-112', 'tractor', 'Kenworth', 'W900', 2019,
          3, 20800, v_d_mona, 'assigned', 'active')
  returning id into v_t112;

  insert into equipment (tenant_id, carrier_id, unit_number, equipment_type, make,
                         model, year, axle_count, empty_weight_lb,
                         default_driver_id, home_base_facility_id,
                         operational_status, status)
  values (v_tenant, v_carrier, 'T-118', 'tractor', 'Peterbilt', '567', 2022,
          3, 22100, v_d_del, v_f_yard, 'available', 'active')
  returning id into v_t118;

  insert into equipment (tenant_id, carrier_id, unit_number, equipment_type, make,
                         model, year, axle_count, empty_weight_lb,
                         default_driver_id, operational_status, status)
  values (v_tenant, v_carrier, 'T-121', 'tractor', 'Freightliner', 'Coronado', 2018,
          3, 20200, v_d_junior, 'assigned', 'active')
  returning id into v_t121;

  insert into equipment (tenant_id, carrier_id, unit_number, equipment_type, make,
                         year, axle_count, deck_length_in, deck_height_in,
                         empty_weight_lb, max_payload_lb, status)
  values (v_tenant, v_carrier, 'R-204', 'rgn', 'Trail King', 2020,
          9, 312, 22, 34000, 150000, 'active')
  returning id into v_r104;

  insert into equipment (tenant_id, carrier_id, unit_number, equipment_type, make,
                         year, axle_count, deck_length_in, deck_height_in,
                         empty_weight_lb, max_payload_lb, status)
  values (v_tenant, v_carrier, 'R-211', 'step_deck', 'Fontaine', 2017,
          2, 636, 40, 12800, 48000, 'active')
  returning id into v_r112;

  insert into equipment (tenant_id, carrier_id, unit_number, equipment_type, make,
                         year, axle_count, deck_length_in, deck_height_in,
                         empty_weight_lb, max_payload_lb, status)
  values (v_tenant, v_carrier, 'R-218', 'lowboy', 'XL Specialized', 2021,
          8, 288, 20, 31000, 120000, 'active')
  returning id into v_r118;

  insert into equipment (tenant_id, carrier_id, unit_number, equipment_type, make,
                         year, axle_count, deck_length_in, deck_height_in,
                         empty_weight_lb, max_payload_lb, status)
  values (v_tenant, v_carrier, 'R-221', 'double_drop', 'Talbert', 2016,
          3, 348, 24, 15600, 60000, 'active')
  returning id into v_r121;

  insert into loads (tenant_id, load_number, broker_load_number, carrier_id, broker_id,
                     driver_id, tractor_id, trailer_id,
                     origin_facility_id, dest_facility_id,
                     commodity, piece_count,
                     length_in, width_in, height_in, weight_lb, axle_count,
                     linehaul_rate, fuel_surcharge, total_miles,
                     pickup_appt_start, delivery_appt_start,
                     actual_pickup_at, status, priority,
                     current_location_text, current_state, current_eta,
                     last_check_in_at, driver_hours_remaining_min,
                     customer_reference)
  values (v_tenant, 'LD-2841', '8842019', v_carrier, v_b_tql,
          v_d_ricky, v_t104, v_r104, v_f_mem, v_f_den,
          'Caterpillar 336 excavator', 1,
          402, 170, 162, 112400, 9,
          8400.00, 620.00, 1042,
          now() - interval '3 days', now() + interval '6 days',
          now() - interval '3 days', 'in_transit', 'normal',
          'Salina, KS', 'KS', now() + interval '5 days 20 hours',
          now() - interval '42 minutes', 380,
          'PO-99418')
  returning id into v_l2841;

  insert into load_legs (tenant_id, load_id, seq, state, miles, planned_entry_date)
  values (v_tenant, v_l2841, 1, 'TN', 210, current_date - 3),
         (v_tenant, v_l2841, 2, 'AR', 285, current_date - 2),
         (v_tenant, v_l2841, 3, 'KS', 312, current_date + 1),
         (v_tenant, v_l2841, 4, 'CO', 235, current_date + 4);

  insert into permits (tenant_id, load_id, load_leg_id, state, permit_number,
                       status, valid_from, valid_to, fee, escort_rear)
  select v_tenant, v_l2841, id, 'TN', 'TN-2026-441982', 'issued',
         current_date - 4, current_date + 1, 45.00, true
    from load_legs where load_id = v_l2841 and seq = 1;

  insert into permits (tenant_id, load_id, load_leg_id, state, permit_number,
                       status, valid_from, valid_to, fee, escort_front, escort_rear)
  select v_tenant, v_l2841, id, 'AR', 'AR-88401277', 'issued',
         current_date - 3, current_date + 2, 60.00, true, true
    from load_legs where load_id = v_l2841 and seq = 2;

  insert into permits (tenant_id, load_id, load_leg_id, state, status,
                       applied_at, fee, escort_front)
  select v_tenant, v_l2841, id, 'KS', 'pending', now() - interval '3 days', 75.00, true
    from load_legs where load_id = v_l2841 and seq = 3;

  insert into permits (tenant_id, load_id, load_leg_id, state, status,
                       fee, escort_high_pole)
  select v_tenant, v_l2841, id, 'CO', 'needed', 110.00, true
    from load_legs where load_id = v_l2841 and seq = 4;

  insert into escort_assignments (tenant_id, load_id, role, status, confirmed_rate,
                                  driver_name, driver_phone, scheduled_start)
  values (v_tenant, v_l2841, 'front', 'confirmed', 950.00,
          'Barry Kell', '620-555-0143', now() + interval '1 day'),
         (v_tenant, v_l2841, 'rear', 'confirmed', 900.00,
          'Sue Ann Petit', '620-555-0190', now() + interval '1 day');

  insert into check_ins (tenant_id, load_id, driver_id, occurred_at, location_text,
                         state, eta, hos_remaining_min, source, note)
  values (v_tenant, v_l2841, v_d_ricky, now() - interval '42 minutes',
          'Salina, KS', 'KS', now() + interval '5 days 20 hours', 380,
          'driver_sms', 'Fueled and rolling');

  insert into loads (tenant_id, load_number, carrier_id, broker_id,
                     driver_id, tractor_id, trailer_id,
                     origin_facility_id, dest_facility_id,
                     commodity, length_in, width_in, height_in, weight_lb,
                     linehaul_rate, total_miles,
                     pickup_appt_start, delivery_appt_start,
                     status, priority, hold_reason, hold_since, hold_note,
                     current_location_text, current_state, last_check_in_at)
  values (v_tenant, 'LD-2847', v_carrier, v_b_mercer,
          v_d_mona, v_t112, v_r112, v_f_mem, v_f_lr,
          'Steel plate bundles', 600, 144, 138, 58200,
          2850.00, 148,
          now() + interval '18 hours', now() + interval '2 days',
          'dispatched', 'high', 'awaiting_permits', now() - interval '6 hours',
          'TN and AR both unfiled, pickup is tomorrow 7am',
          'Memphis, TN', 'TN', now() - interval '2 hours')
  returning id into v_l2847;

  insert into load_legs (tenant_id, load_id, seq, state, miles, planned_entry_date)
  values (v_tenant, v_l2847, 1, 'TN', 62, current_date + 1),
         (v_tenant, v_l2847, 2, 'AR', 86, current_date + 1);

  insert into permits (tenant_id, load_id, load_leg_id, state, status, fee)
  select v_tenant, v_l2847, id, 'TN', 'needed', 45.00
    from load_legs where load_id = v_l2847 and seq = 1;

  insert into permits (tenant_id, load_id, load_leg_id, state, status, fee)
  select v_tenant, v_l2847, id, 'AR', 'needed', 60.00
    from load_legs where load_id = v_l2847 and seq = 2;

  insert into loads (tenant_id, load_number, carrier_id, broker_id,
                     driver_id, tractor_id, trailer_id,
                     origin_facility_id, dest_facility_id,
                     commodity, length_in, width_in, height_in, weight_lb,
                     linehaul_rate, fuel_surcharge, total_miles,
                     pickup_appt_start, delivery_appt_start, actual_pickup_at,
                     status, priority, hold_reason, hold_since, hold_note,
                     hold_expected_clear_at,
                     current_location_text, current_state, last_check_in_at,
                     driver_hours_remaining_min)
  values (v_tenant, 'LD-2839', v_carrier, v_b_tql,
          v_d_junior, v_t121, v_r121, v_f_lr, v_f_mem,
          'Transformer housing', 420, 132, 150, 46800,
          3400.00, 280.00, 152,
          now() - interval '1 day', now() + interval '1 day',
          now() - interval '1 day',
          'in_transit', 'critical', 'breakdown', now() - interval '3 hours',
          'Air line blew on the trailer. Tow dispatched from Little Rock.',
          now() + interval '2 hours',
          'I-40 MM 155, Little Rock AR', 'AR', now() - interval '25 minutes', 240)
  returning id into v_l2839;

  insert into load_legs (tenant_id, load_id, seq, state, miles, planned_entry_date)
  values (v_tenant, v_l2839, 1, 'AR', 90, current_date - 1),
         (v_tenant, v_l2839, 2, 'TN', 62, current_date);

  insert into permits (tenant_id, load_id, load_leg_id, state, permit_number,
                       status, valid_from, valid_to, fee, escort_front)
  select v_tenant, v_l2839, id, 'AR', 'AR-88400913', 'issued',
         current_date - 2, current_date + 3, 60.00, true
    from load_legs where load_id = v_l2839 and seq = 1;

  insert into permits (tenant_id, load_id, load_leg_id, state, permit_number,
                       status, valid_from, valid_to, fee, escort_front)
  select v_tenant, v_l2839, id, 'TN', 'TN-2026-440118', 'issued',
         current_date - 2, current_date + 3, 45.00, true
    from load_legs where load_id = v_l2839 and seq = 2;

  insert into escort_assignments (tenant_id, load_id, role, status, confirmed_rate,
                                  driver_name, driver_phone)
  values (v_tenant, v_l2839, 'front', 'en_route', 700.00,
          'Cal Rhodes', '501-555-0203');

  insert into load_charges (tenant_id, load_id, kind, category, description, amount)
  values (v_tenant, v_l2839, 'cost', 'repair', 'Roadside air line repair and tow', 1150.00);

  insert into loads (tenant_id, load_number, carrier_id, broker_id,
                     origin_facility_id, dest_facility_id,
                     commodity, length_in, width_in, height_in, weight_lb,
                     linehaul_rate, total_miles,
                     pickup_appt_start, delivery_appt_start,
                     status, priority)
  values (v_tenant, 'LD-2852', v_carrier, v_b_mercer,
          v_f_lr, v_f_den,
          'Crane counterweights', 360, 126, 120, 88000,
          6200.00, 920,
          now() + interval '4 days', now() + interval '7 days',
          'booked', 'normal')
  returning id into v_l2852;

  insert into events (tenant_id, entity_type, entity_id, load_id, event_type,
                      direction, occurred_at, subject, body, is_milestone)
  values
    (v_tenant, 'load', v_l2841, v_l2841, 'rate_con_received', 'inbound',
     now() - interval '5 days', 'Rate confirmation received',
     'TQL rate con v2, 8400 linehaul', true),
    (v_tenant, 'load', v_l2841, v_l2841, 'pickup_completed', 'internal',
     now() - interval '3 days', 'Pickup completed',
     'Loaded and secured at Delta Machinery Yard', true),
    (v_tenant, 'load', v_l2841, v_l2841, 'escort_confirmed', 'outbound',
     now() - interval '2 days', 'Escorts confirmed',
     'Front and rear booked through Prairie Pilot Cars', false),
    (v_tenant, 'load', v_l2839, v_l2839, 'mechanical_breakdown', 'inbound',
     now() - interval '3 hours', 'Breakdown reported',
     'Driver reports blown air line on trailer, I-40 MM 155', true),
    (v_tenant, 'load', v_l2847, v_l2847, 'note', 'internal',
     now() - interval '6 hours', 'Permits still open',
     'Called permit service twice, no callback yet', false);

end
$seed$;
