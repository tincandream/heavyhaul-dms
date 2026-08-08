-- ============================================================
-- 031_golden_route_reasons.sql
-- Heavy Haul Command
-- Enrich original 027 National Backbone Golden Routes
--
-- PURPOSE
-- Adds freight-specific "Why this is a Golden Route" intelligence
-- to the original 72 reference backbone records created by 027.
--
-- DOES NOT:
-- - insert new routes
-- - modify company routes
-- - modify newer national/regional lane records from 030
--
-- SAFE TO RERUN:
-- Updates only route_class='reference' records whose route_name
-- begins with 'REFERENCE — ' and whose lane_type is null.
-- ============================================================


-- ============================================================
-- 1. NATIONAL BACKBONE CLASSIFICATION
-- ============================================================

update public.golden_routes
set
  lane_type = 'national_backbone',
  evidence_class = case freight_type
    when 'heavy_haul' then 'national_freight_backbone'
    when 'reefer' then 'national_food_freight_backbone'
    when 'dry_van' then 'national_distribution_backbone'
    when 'flatbed' then 'national_industrial_backbone'
    when 'step_deck' then 'national_machinery_backbone'
    when 'specialized' then 'national_specialized_freight_backbone'
    else 'national_freight_backbone'
  end,
  confidence_level = case
    when highways in ('I-5','I-10','I-20','I-35','I-40','I-55','I-65','I-70','I-75','I-80','I-90','I-95')
      then 'high'
    else 'medium'
  end
where route_class = 'reference'
  and route_name like 'REFERENCE — %'
  and lane_type is null;


-- ============================================================
-- 2. FREIGHT-SPECIFIC "WHY GOLDEN" REASONS
--
-- Uses the original corridor/highway record plus freight type.
-- ============================================================

update public.golden_routes
set freight_reason =
  case

    -- ========================================================
    -- I-5
    -- ========================================================
    when highways = 'I-5' and freight_type = 'dry_van' then
      'A core West Coast distribution backbone linking Southern California, Northern California, Oregon, and Washington. It connects major population centers, ports, warehouses, and regional distribution markets, making it a strong dry-van reference corridor.'

    when highways = 'I-5' and freight_type = 'reefer' then
      'A major West Coast food and produce corridor connecting California agricultural regions with large consumer markets in California, Oregon, and Washington. It is especially useful as a reefer planning backbone for north-south cold-chain freight.'

    when highways = 'I-5' and freight_type = 'flatbed' then
      'A major West Coast industrial and construction corridor connecting large metro construction markets, ports, building-material suppliers, and manufacturing regions. It is a useful flatbed reference backbone for materials and industrial freight.'

    when highways = 'I-5' and freight_type = 'step_deck' then
      'A strong West Coast machinery and equipment corridor serving major ports, construction markets, manufacturing centers, and industrial regions. It is useful for step-deck planning where taller or dimensional equipment is common.'

    when highways = 'I-5' and freight_type = 'specialized' then
      'A major West Coast freight spine connecting ports, industrial markets, manufacturing centers, and project-cargo gateways from Southern California through the Pacific Northwest.'

    when highways = 'I-5' and freight_type = 'heavy_haul' then
      'A nationally important West Coast freight corridor connecting major port, industrial, manufacturing, and project-cargo markets. It is valuable as a heavy-haul market reference only; the legal oversize/overweight route must be established by current permits and route restrictions.'


    -- ========================================================
    -- I-10
    -- ========================================================
    when highways = 'I-10' and freight_type = 'dry_van' then
      'A major southern transcontinental distribution corridor linking Southern California, Phoenix, Texas, the Gulf Coast, and Florida. It connects large consumer and warehouse markets and is a strong dry-van planning backbone.'

    when highways = 'I-10' and freight_type = 'reefer' then
      'A major southern cold-chain corridor linking California and Southwest food origins with Texas, Gulf Coast, and Florida consumer markets. It is useful for long-haul reefer planning across warmer southern states.'

    when highways = 'I-10' and freight_type = 'flatbed' then
      'A major southern industrial corridor serving construction, steel, building-material, energy, and manufacturing markets across California, Arizona, Texas, Louisiana, and the Gulf Coast.'

    when highways = 'I-10' and freight_type = 'step_deck' then
      'A strong machinery and equipment corridor serving Southwest construction markets, Texas industrial centers, Gulf Coast energy markets, and major freight gateways.'

    when highways = 'I-10' and freight_type = 'specialized' then
      'One of the strongest southern specialized-freight backbones, linking major ports, petrochemical regions, energy markets, industrial centers, and project-cargo gateways from California to Florida.'

    when highways = 'I-10' and freight_type = 'heavy_haul' then
      'A major southern heavy-industrial and project-cargo market corridor, especially through Texas and the Gulf Coast. It is a useful market reference for heavy haul, but current permits, bridge limits, clearances, escort rules, and state routing requirements control the actual move.'


    -- ========================================================
    -- I-20
    -- ========================================================
    when highways = 'I-20' and freight_type = 'dry_van' then
      'A strong South-Central to Southeast distribution corridor connecting Dallas, Shreveport, Jackson, Birmingham, and Atlanta. It links major warehouse, consumer, and manufacturing markets.'

    when highways = 'I-20' and freight_type = 'reefer' then
      'A useful southern reefer corridor connecting Texas and Southeast food-distribution markets, with access to major population centers and regional cold-chain networks.'

    when highways = 'I-20' and freight_type = 'flatbed' then
      'A strong industrial and construction corridor linking Texas, Louisiana, Mississippi, Alabama, and Georgia, including major steel, manufacturing, building-material, and construction markets.'

    when highways = 'I-20' and freight_type = 'step_deck' then
      'A practical machinery and industrial-equipment backbone connecting Texas with major Southeast manufacturing and construction markets.'

    when highways = 'I-20' and freight_type = 'specialized' then
      'A major southern industrial corridor connecting energy, manufacturing, construction, machinery, and inland distribution markets between Texas and Georgia.'

    when highways = 'I-20' and freight_type = 'heavy_haul' then
      'A useful heavy-industrial market corridor through Texas and the Southeast, connecting machinery, steel, energy, and project-cargo markets. It is a market reference only; current permits determine the legal route.'


    -- ========================================================
    -- I-35
    -- ========================================================
    when highways = 'I-35' and freight_type = 'dry_van' then
      'A major north-south central U.S. distribution corridor linking the Texas border region, San Antonio, Dallas, Oklahoma City, Kansas City, and the Upper Midwest.'

    when highways = 'I-35' and freight_type = 'reefer' then
      'A major food and agricultural freight corridor connecting the Texas border gateway and southern food markets with central and northern U.S. distribution centers.'

    when highways = 'I-35' and freight_type = 'flatbed' then
      'A strong central U.S. industrial corridor serving construction, steel, agricultural equipment, manufacturing, and building-material markets from Texas through the Midwest.'

    when highways = 'I-35' and freight_type = 'step_deck' then
      'A strong machinery and equipment corridor connecting Texas industrial markets with Oklahoma, Kansas City, and Upper Midwest manufacturing regions.'

    when highways = 'I-35' and freight_type = 'specialized' then
      'A major central freight backbone connecting a large border gateway with energy, machinery, manufacturing, and inland distribution markets.'

    when highways = 'I-35' and freight_type = 'heavy_haul' then
      'A major central industrial and equipment market corridor connecting Texas, Oklahoma, Kansas, Missouri, and the Upper Midwest. It is useful as a heavy-haul market reference, but permit-authorized routing controls.'


    -- ========================================================
    -- I-40
    -- ========================================================
    when highways = 'I-40' and freight_type = 'dry_van' then
      'A major east-west distribution corridor connecting the Southwest, Oklahoma, Arkansas, Memphis, Tennessee, and North Carolina. It links multiple national and regional warehouse markets.'

    when highways = 'I-40' and freight_type = 'reefer' then
      'A strong cross-country reefer backbone linking western food-producing regions with central, Mid-South, and Southeast consumer markets.'

    when highways = 'I-40' and freight_type = 'flatbed' then
      'A broad industrial and construction corridor connecting Southwest materials markets with Oklahoma, Arkansas, Tennessee, and Southeast manufacturing regions.'

    when highways = 'I-40' and freight_type = 'step_deck' then
      'A useful machinery and equipment corridor through the Southwest, central U.S., Mid-South, and Southeast, serving manufacturing and construction freight.'

    when highways = 'I-40' and freight_type = 'specialized' then
      'A nationally important east-west freight backbone connecting machinery, industrial, manufacturing, and distribution markets across the southern half of the country.'

    when highways = 'I-40' and freight_type = 'heavy_haul' then
      'A major east-west freight market corridor crossing several heavy-industrial and machinery markets. It is a planning reference only; each heavy-haul move requires current state permits and route verification.'


    -- ========================================================
    -- I-55
    -- ========================================================
    when highways = 'I-55' and freight_type = 'dry_van' then
      'A strong Mississippi Valley distribution corridor linking New Orleans, Jackson, Memphis, St. Louis, and Chicago-region markets.'

    when highways = 'I-55' and freight_type = 'reefer' then
      'A useful food and agricultural corridor connecting Gulf and Mid-South origins with Memphis, St. Louis, and Chicago food-distribution markets.'

    when highways = 'I-55' and freight_type = 'flatbed' then
      'A useful industrial and building-material corridor connecting Gulf Coast, Mid-South, St. Louis, and Chicago-region markets.'

    when highways = 'I-55' and freight_type = 'step_deck' then
      'A strong machinery and equipment corridor connecting Mid-South industrial markets with St. Louis and Chicago-region manufacturing centers.'

    when highways = 'I-55' and freight_type = 'specialized' then
      'A strategic Mississippi Valley freight corridor connecting Gulf Coast, river, industrial, and major Midwest freight markets.'

    when highways = 'I-55' and freight_type = 'heavy_haul' then
      'A valuable heavy-industrial market corridor linking Gulf Coast, Memphis, St. Louis, and Chicago-region project and machinery markets. Current permit routing controls every oversize move.'


    -- ========================================================
    -- I-65
    -- ========================================================
    when highways = 'I-65' and freight_type = 'dry_van' then
      'A major north-south distribution corridor linking Mobile, Birmingham, Nashville, Louisville, Indianapolis-region freight, and the southern Chicago market.'

    when highways = 'I-65' and freight_type = 'reefer' then
      'A useful Southeast-to-Midwest food-distribution corridor connecting Gulf and southern markets with Nashville, Louisville, Indiana, and Chicago-region consumers.'

    when highways = 'I-65' and freight_type = 'flatbed' then
      'A strong industrial corridor connecting Alabama steel and manufacturing markets with Tennessee, Kentucky, Indiana, and Midwest construction markets.'

    when highways = 'I-65' and freight_type = 'step_deck' then
      'A strong machinery and equipment corridor connecting Southeast manufacturing markets with Louisville, Indiana, and Midwest industrial centers.'

    when highways = 'I-65' and freight_type = 'specialized' then
      'A major Southeast-to-Midwest industrial backbone connecting ports, manufacturing, machinery, and inland freight markets.'

    when highways = 'I-65' and freight_type = 'heavy_haul' then
      'A useful heavy-industrial market corridor connecting Alabama, Tennessee, Kentucky, and Indiana manufacturing regions. It is not a blanket oversize route; permit-specific routing controls.'


    -- ========================================================
    -- I-70
    -- ========================================================
    when highways = 'I-70' and freight_type = 'dry_van' then
      'A major central U.S. east-west distribution corridor connecting Denver, Kansas City, St. Louis, Indianapolis, and Ohio Valley markets.'

    when highways = 'I-70' and freight_type = 'reefer' then
      'A useful central U.S. food-distribution corridor connecting Plains and Mountain West origins with major Midwest and Ohio Valley consumer markets.'

    when highways = 'I-70' and freight_type = 'flatbed' then
      'A strong industrial and construction corridor connecting Mountain West, Plains, Midwest, and Ohio Valley markets.'

    when highways = 'I-70' and freight_type = 'step_deck' then
      'A strong machinery and industrial-equipment corridor connecting Denver, Kansas City, St. Louis, Indianapolis, and Ohio Valley manufacturing markets.'

    when highways = 'I-70' and freight_type = 'specialized' then
      'A major central industrial and specialized-freight backbone linking Mountain West, Plains, Midwest, and Ohio Valley project markets.'

    when highways = 'I-70' and freight_type = 'heavy_haul' then
      'A valuable central heavy-industrial market corridor across major machinery and manufacturing regions. Actual heavy-haul routing must be independently permitted and verified.'


    -- ========================================================
    -- I-75
    -- ========================================================
    when highways = 'I-75' and freight_type = 'dry_van' then
      'A major Southeast-to-Great Lakes distribution corridor linking Florida, Atlanta, Tennessee, Kentucky, Ohio, and Michigan markets.'

    when highways = 'I-75' and freight_type = 'reefer' then
      'A major north-south food and cold-chain corridor connecting Florida and Southeast food markets with Atlanta, Ohio, and Great Lakes consumer regions.'

    when highways = 'I-75' and freight_type = 'flatbed' then
      'A strong manufacturing and construction corridor connecting Southeast growth markets with Ohio and Michigan industrial regions.'

    when highways = 'I-75' and freight_type = 'step_deck' then
      'A major machinery and equipment corridor serving Southeast manufacturing, automotive, construction, and Great Lakes industrial markets.'

    when highways = 'I-75' and freight_type = 'specialized' then
      'A strong specialized-freight corridor connecting Florida, Atlanta, Tennessee, Ohio, and Michigan manufacturing and project markets.'

    when highways = 'I-75' and freight_type = 'heavy_haul' then
      'A useful heavy-industrial market corridor connecting Southeast project markets with Ohio and Michigan manufacturing regions. Current permits and state routing rules determine the legal path.'


    -- ========================================================
    -- I-80
    -- ========================================================
    when highways = 'I-80' and freight_type = 'dry_van' then
      'A major transcontinental distribution backbone connecting Northern California, the Mountain West, Plains, Chicago, and onward Northeast freight markets.'

    when highways = 'I-80' and freight_type = 'reefer' then
      'A major long-haul cold-chain corridor connecting western agricultural markets with Midwest and Northeast consumer regions.'

    when highways = 'I-80' and freight_type = 'flatbed' then
      'A major industrial and building-material corridor linking western, Plains, Great Lakes, and Northeast manufacturing markets.'

    when highways = 'I-80' and freight_type = 'step_deck' then
      'A major machinery and equipment corridor connecting western and central U.S. industrial markets with the Great Lakes and Northeast.'

    when highways = 'I-80' and freight_type = 'specialized' then
      'A nationally important specialized-freight backbone connecting ports, industrial markets, manufacturing centers, and major inland freight hubs.'

    when highways = 'I-80' and freight_type = 'heavy_haul' then
      'A major national industrial market corridor linking western, central, Great Lakes, and Northeast project markets. It is a market reference only; current permits and route restrictions control every oversize move.'


    -- ========================================================
    -- I-90
    -- ========================================================
    when highways = 'I-90' and freight_type = 'dry_van' then
      'A major northern transcontinental distribution corridor linking Seattle, the northern Plains, Minneapolis, Chicago, New York, and New England markets.'

    when highways = 'I-90' and freight_type = 'reefer' then
      'A useful northern long-haul food corridor connecting Pacific Northwest and northern agricultural markets with Midwest, Northeast, and New England consumers.'

    when highways = 'I-90' and freight_type = 'flatbed' then
      'A strong northern industrial corridor connecting Pacific Northwest, Plains, Great Lakes, and Northeast construction and manufacturing markets.'

    when highways = 'I-90' and freight_type = 'step_deck' then
      'A major machinery and equipment corridor serving northern manufacturing, agricultural-equipment, Great Lakes, and Northeast markets.'

    when highways = 'I-90' and freight_type = 'specialized' then
      'A major northern specialized-freight backbone connecting Pacific Northwest gateways, industrial markets, Great Lakes manufacturing, New York, and New England.'

    when highways = 'I-90' and freight_type = 'heavy_haul' then
      'A nationally important northern industrial market corridor. It can be useful for heavy-haul market planning, but bridge restrictions, dimensions, weather, and current permit routing control the actual move.'


    -- ========================================================
    -- I-95
    -- ========================================================
    when highways = 'I-95' and freight_type = 'dry_van' then
      'The primary East Coast distribution backbone connecting Florida, the Southeast, Mid-Atlantic, New York/New Jersey, and New England consumer and warehouse markets.'

    when highways = 'I-95' and freight_type = 'reefer' then
      'A major East Coast cold-chain corridor connecting Florida and Southeast food origins with dense Mid-Atlantic, New York/New Jersey, and New England consumer markets.'

    when highways = 'I-95' and freight_type = 'flatbed' then
      'A major East Coast industrial and construction corridor connecting rapidly growing Southeast and Northeast construction, port, and manufacturing markets.'

    when highways = 'I-95' and freight_type = 'step_deck' then
      'A major East Coast machinery and equipment corridor linking ports, construction markets, manufacturing regions, and dense Northeast industrial markets.'

    when highways = 'I-95' and freight_type = 'specialized' then
      'The principal East Coast specialized-freight backbone connecting major ports, population centers, industrial markets, project-cargo gateways, and Northeast manufacturing regions.'

    when highways = 'I-95' and freight_type = 'heavy_haul' then
      'A major East Coast heavy-industrial and project-cargo market corridor connecting ports and industrial markets from Florida through the Northeast. It is not a universal oversize route; permits and state routing restrictions control.'

    else
      coalesce(
        freight_reason,
        'National freight backbone with strong freight-market significance for this equipment type. Verify current load-specific requirements before use.'
      )

  end
where route_class = 'reference'
  and route_name like 'REFERENCE — %';


-- ============================================================
-- 3. UPDATE GENERAL NOTES FOR ORIGINAL 72
-- Keeps the explanation visible even if a card uses notes.
-- ============================================================

update public.golden_routes
set general_notes =
  case
    when freight_type = 'heavy_haul' then
      coalesce(general_notes,'') ||
      case when coalesce(general_notes,'') <> '' then E'\n\n' else '' end ||
      'WHY GOLDEN: ' || freight_reason ||
      E'\n\nHEAVY HAUL NOTICE: This is a freight-market reference corridor only. Current oversize/overweight permits, route surveys, bridge restrictions, clearances, escort requirements, construction, weather, curfews, and state-specific rules control the actual move.'
    else
      coalesce(general_notes,'') ||
      case when coalesce(general_notes,'') <> '' then E'\n\n' else '' end ||
      'WHY GOLDEN: ' || freight_reason
  end
where route_class = 'reference'
  and route_name like 'REFERENCE — %'
  and freight_reason is not null
  and (
    general_notes is null
    or general_notes not like '%WHY GOLDEN:%'
  );


-- ============================================================
-- 4. VERIFICATION
-- Expected: original 72 reference backbone routes now have
-- freight_reason + evidence_class + confidence_level +
-- national_backbone lane_type.
-- ============================================================

select
  freight_type,
  count(*) as backbone_routes_with_reason

from public.golden_routes

where route_class = 'reference'
  and route_name like 'REFERENCE — %'
  and lane_type = 'national_backbone'
  and freight_reason is not null

group by freight_type

order by freight_type;


-- ============================================================
-- 5. SAMPLE CHECK
-- ============================================================

select
  route_name,
  freight_type,
  lane_type,
  evidence_class,
  confidence_level,
  freight_reason

from public.golden_routes

where route_class = 'reference'
  and route_name like 'REFERENCE — %'

order by
  route_name,
  freight_type

limit 12;
