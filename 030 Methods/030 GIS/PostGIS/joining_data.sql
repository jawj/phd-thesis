
-- Adding map points (London only) (

select addgeometrycolumn('london_survey', 'home_map_osgb', 27700, 'POINT', 2);
update london_survey set home_map_osgb = st_transform(
  st_setsrid(st_makepoint(home_lon, home_lat), 4326), 
  27700
);

select addgeometrycolumn('london_survey', 'other_map_osgb', 27700, 'POINT', 2);
update london_survey set other_map_osgb = st_transform(
  st_setsrid(st_makepoint(other_lon, other_lat), 4326), 
  27700
);

)

-- Adding postcode points (

select addgeometrycolumn('london_survey', 'home_postcode_osgb', 27700, 'POINT', 2);
update london_survey l set home_postcode_osgb = the_geom 
  from nspd2010aug n where l.home_postcode = n.postcode_no_sp;

select addgeometrycolumn('london_survey', 'other_postcode_osgb', 27700, 'POINT', 2);
update london_survey l set other_postcode_osgb = the_geom 
  from nspd2010aug n where l.other_postcode = n.postcode_no_sp;

select addgeometrycolumn('uk_survey', 'home_postcode_osgb', 27700, 'POINT', 2);
update uk_survey l set home_postcode_osgb = the_geom 
  from nspd2010aug n where l.home_postcode = n.postcode_no_sp;

select addgeometrycolumn('uk_survey', 'other_postcode_osgb', 27700, 'POINT', 2);
update uk_survey l set other_postcode_osgb = the_geom 
  from nspd2010aug n where l.other_postcode = n.postcode_no_sp;

)

-- Adding postcode polygons (
  
select addgeometrycolumn('london_survey', 'home_postcode_poly', 27700, 'MULTIPOLYGON', 2);
update london_survey l set home_postcode_poly = the_geom 
  from cpp_polygons p where l.home_postcode = p.postcode_no_sp;

select addgeometrycolumn('london_survey', 'other_postcode_poly', 27700, 'MULTIPOLYGON', 2);
update london_survey l set other_postcode_poly = the_geom 
  from cpp_polygons p where l.other_postcode = p.postcode_no_sp;

select addgeometrycolumn('uk_survey', 'home_postcode_poly', 27700, 'MULTIPOLYGON', 2);
update uk_survey l set home_postcode_poly = the_geom 
  from cpp_polygons p where l.home_postcode = p.postcode_no_sp;

select addgeometrycolumn('uk_survey', 'other_postcode_poly', 27700, 'MULTIPOLYGON', 2);
update uk_survey l set other_postcode_poly = the_geom 
  from cpp_polygons p where l.other_postcode = p.postcode_no_sp;

)

-- Adding map/point/poly derivatives table (London only) (

create table london_location_derivatives as (
  select 
    id,
    st_distance(home_map_osgb, home_postcode_osgb) as home_map_centroid_distance,
    st_distance(home_map_osgb, home_postcode_poly) as home_map_poly_distance,
    st_distance(other_map_osgb, other_postcode_osgb) as other_map_centroid_distance,
    st_distance(other_map_osgb, other_postcode_poly) as other_map_poly_distance
  from london_survey
);
create unique index lld_id_idx on london_location_derivatives (id);

-- select * from london_location_derivatives where home_map_poly_distance = 0 order by home_map_centroid_distance desc;
-- centroid is up to 200m off even where map location is inside poly

)

-- Adding LSOA/dzone codes (

alter table london_survey add column home_lsoa_or_dzone text;
update london_survey l set home_lsoa_or_dzone = n.lsoa from nspd2010aug n where l.home_postcode = n.postcode_no_sp;
  
alter table london_survey add column other_lsoa_or_dzone text;
update london_survey l set other_lsoa_or_dzone = n.lsoa from nspd2010aug n where l.other_postcode = n.postcode_no_sp;

alter table uk_survey add column home_lsoa_or_dzone text;
update uk_survey l set home_lsoa_or_dzone = case n.country
  when '064' then n.lsoa
  when '200' then n.lsoa
  when '179' then n.scottish_dzone
  when '152' then n.soa_ni
  else            null
end 
from nspd2010aug n where l.home_postcode = n.postcode_no_sp;

alter table uk_survey add column other_lsoa_or_dzone text;
update uk_survey l set other_lsoa_or_dzone = case n.country
  when '064' then n.lsoa
  when '200' then n.lsoa
  when '179' then n.scottish_dzone
  when '152' then n.soa_ni
  else            null
end 
from nspd2010aug n where l.other_postcode = n.postcode_no_sp;

)

-- Adding TTWAs for UK (
  
alter table uk_survey add column home_ttwa text;
update uk_survey l set home_ttwa = n.ttwa from nspd2010aug n where l.home_postcode = n.postcode_no_sp;

alter table uk_survey add column other_ttwa text;
update uk_survey l set other_ttwa = n.ttwa from nspd2010aug n where l.other_postcode = n.postcode_no_sp;

)

-- Adding Experian data table (

create table london_experian2010 as (
  select
    s.id,
    eh.hh_count         as home_lsoa_hh_count,
    eh.median_hh_income as home_lsoa_medhhinc,
    eph.pop             as home_lsoa_pop,
    eo.hh_count         as other_lsoa_hh_count,
    eo.median_hh_income as other_lsoa_medhhinc,
    epo.pop             as other_lsoa_pop
  from london_survey s
  left join experian2010 eh       on s.home_lsoa_or_dzone   = eh.lsoa
  left join experian2010pops eph  on s.home_lsoa_or_dzone   = eph.lsoa
  left join experian2010 eo       on s.other_lsoa_or_dzone  = eo.lsoa
  left join experian2010pops epo  on s.other_lsoa_or_dzone  = epo.lsoa
);
create unique index londonexp_id_idx on london_experian2010 (id);

create table uk_experian2010 as (
  select
    s.id,
    eh.hh_count         as home_lsoa_hh_count,
    eh.median_hh_income as home_lsoa_medhhinc,
    eph.pop             as home_lsoa_pop,
    eo.hh_count         as other_lsoa_hh_count,
    eo.median_hh_income as other_lsoa_medhhinc,
    epo.pop             as other_lsoa_pop
  from uk_survey s
  left join experian2010 eh       on s.home_lsoa_or_dzone   = eh.lsoa
  left join experian2010pops eph  on s.home_lsoa_or_dzone   = eph.lsoa
  left join experian2010 eo       on s.other_lsoa_or_dzone  = eo.lsoa
  left join experian2010pops epo  on s.other_lsoa_or_dzone  = epo.lsoa
);
create unique index ukexp_id_idx on uk_experian2010 (id);


)

-- Adding LSOA/dzone polys + areas (
  
select addgeometrycolumn('london_survey', 'home_lsoa_dzone_poly', 27700, 'GEOMETRY', 2);
update london_survey l set home_lsoa_dzone_poly = wkb_geometry
  from lsoa_polys p where l.home_lsoa_or_dzone = p.lsoa04cd;
update london_survey l set home_lsoa_dzone_poly = the_geom
  from dzone_polys p where l.home_lsoa_or_dzone = p.zonecode;

select addgeometrycolumn('london_survey', 'other_lsoa_dzone_poly', 27700, 'GEOMETRY', 2);
update london_survey l set other_lsoa_dzone_poly = wkb_geometry
  from lsoa_polys p where l.other_lsoa_or_dzone = p.lsoa04cd;
update london_survey l set other_lsoa_dzone_poly = the_geom
  from dzone_polys p where l.other_lsoa_or_dzone = p.zonecode;

select addgeometrycolumn('uk_survey', 'home_lsoa_dzone_poly', 27700, 'GEOMETRY', 2);
update uk_survey l set home_lsoa_dzone_poly = wkb_geometry
  from lsoa_polys p where l.home_lsoa_or_dzone = p.lsoa04cd;
update uk_survey l set home_lsoa_dzone_poly = the_geom
  from dzone_polys p where l.home_lsoa_or_dzone = p.zonecode;

select addgeometrycolumn('uk_survey', 'other_lsoa_dzone_poly', 27700, 'GEOMETRY', 2);
update uk_survey l set other_lsoa_dzone_poly = wkb_geometry
  from lsoa_polys p where l.other_lsoa_or_dzone = p.lsoa04cd;
update uk_survey l set other_lsoa_dzone_poly = the_geom
  from dzone_polys p where l.other_lsoa_or_dzone = p.zonecode;

alter table london_survey add column home_lsoa_area real;
update london_survey set home_lsoa_area = st_area(home_lsoa_dzone_poly);

alter table london_survey add column other_lsoa_area real;
update london_survey set other_lsoa_area = st_area(other_lsoa_dzone_poly);

alter table uk_survey add column home_lsoa_area real;
update uk_survey set home_lsoa_area = st_area(home_lsoa_dzone_poly);

alter table uk_survey add column other_lsoa_area real;
update uk_survey set other_lsoa_area = st_area(other_lsoa_dzone_poly);

-- indices needed for LCM per LSOA

create index london_home_lsoa_poly_idx on london_survey using gist(home_lsoa_dzone_poly);
create index london_other_lsoa_poly_idx on london_survey using gist(other_lsoa_dzone_poly);
create index uk_home_lsoa_poly_idx on uk_survey using gist(home_lsoa_dzone_poly);
create index uk_other_lsoa_poly_idx on uk_survey using gist(other_lsoa_dzone_poly);
analyze london_survey;
analyze uk_survey;

)

-- Adding crime table (London only) (

create table london_crime as (
  select 
    s.id,
    ht.tno as home_tno,
    hv.vap as home_vap,
    hb.rb  as home_rb,
    ot.tno as other_tno,
    ov.vap as other_vap,
    ob.rb  as other_rb
  from london_survey s
  left join crime_tno ht on s.home_lsoa_or_dzone  = ht.lsoa
  left join crime_vap hv on s.home_lsoa_or_dzone  = hv.lsoa
  left join crime_rb  hb on s.home_lsoa_or_dzone  = hb.lsoa
  left join crime_tno ot on s.other_lsoa_or_dzone = ot.lsoa
  left join crime_vap ov on s.other_lsoa_or_dzone = ov.lsoa
  left join crime_rb  ob on s.other_lsoa_or_dzone = ob.lsoa
);
create unique index londoncrime_id_idx on london_crime (id);

)

-- Adding Heathrow noise data (London only) (

alter table london_survey add column home_lhr09_leq integer;
update london_survey l set home_lhr09_leq = coalesce((
  select max(db) / 3 - 18 from lhr09_leq_standard_plg where st_contains(the_geom, l.home_map_osgb)
), 0);

alter table london_survey add column other_lhr09_leq integer;
update london_survey l set other_lhr09_leq = coalesce((
  select max(db) / 3 - 18 from lhr09_leq_standard_plg where st_contains(the_geom, l.other_map_osgb)
), 0);

)

-- Adding Defra noise data (London only) (

alter table london_survey add column home_noise_rail_lden integer;
update london_survey set home_noise_rail_lden = n.dn from noise_rail_lden n where st_contains(n.the_geom, home_map_osgb);

alter table london_survey add column other_noise_rail_lden integer;
update london_survey set other_noise_rail_lden = n.dn from noise_rail_lden n where st_contains(n.the_geom, other_map_osgb);

alter table london_survey add column home_noise_road_lden integer;
update london_survey set home_noise_road_lden = n.dn from noise_road_lden n where st_contains(n.the_geom, home_map_osgb);

alter table london_survey add column other_noise_road_lden integer;
update london_survey set other_noise_road_lden = n.dn from noise_road_lden n where st_contains(n.the_geom, other_map_osgb);

)

-- Adding LAEI table (London only) (

create table london_laei2008 as (
  select 
    s.id,
    
    h2.laei08_08    as home_map_no2a,
    hpa.laei08_08   as home_map_pm10a,
    hpe.laei08_08   as home_map_pm10e,
    
    o2.laei08_08    as other_map_no2a,
    opa.laei08_08   as other_map_pm10a,
    ope.laei08_08   as other_map_pm10e,
    
    hpc2.laei08_08  as home_pcc_no2a,  -- measures at postcode centroids
    hpcpa.laei08_08 as home_pcc_pm10a,
    hpcpe.laei08_08 as home_pcc_pm10e
    
  from london_survey s
  
  left join laei08_no2a  h2    on st_contains(h2.the_geom,  s.home_map_osgb)
  left join laei08_pm10a hpa   on st_contains(hpa.the_geom, s.home_map_osgb)
  left join laei08_pm10e hpe   on st_contains(hpe.the_geom, s.home_map_osgb)
  
  left join laei08_no2a  o2    on st_contains(o2.the_geom,  s.other_map_osgb)
  left join laei08_pm10a opa   on st_contains(opa.the_geom, s.other_map_osgb)
  left join laei08_pm10e ope   on st_contains(ope.the_geom, s.other_map_osgb)
  
  left join laei08_no2a  hpc2  on st_contains(hpc2.the_geom,  s.home_postcode_osgb)
  left join laei08_pm10a hpcpa on st_contains(hpcpa.the_geom, s.home_postcode_osgb)
  left join laei08_pm10e hpcpe on st_contains(hpcpe.the_geom, s.home_postcode_osgb)
);
create unique index londonlaei_id_idx on london_laei2008 (id);

) 

-- Adding GiGL AoD (London only) (

alter table london_survey add column home_aod boolean default false;
update london_survey s set home_aod = true from aods a where st_contains(a.wkb_geometry, s.home_map_osgb);

alter table london_survey add column other_aod boolean default false;
update london_survey s set other_aod = true from aods a where st_contains(a.wkb_geometry, s.other_map_osgb);
  
)

-- Adding Tube & Meridian nearests table (London) (

create view zone1tubes as (select * from tube_stops where lowzone = 1);

create table zone1 as (
  select 1 as id, st_convexhull(st_collect(the_geom)) as the_geom from zone1tubes
);

drop table if exists london_meridian;
create table london_meridian as (
  select 
    id,
    st_distance(home_map_osgb, (select the_geom from zone1))         as home_z1_dist,
    nnDistance(home_map_osgb,   500, 2, 8, 'zone1tubes', 'the_geom') as home_z1tube_dist,
    nnDistance(home_map_osgb,   500, 2, 8, 'tube_stops', 'the_geom') as home_tube_dist,
    nnDistance(home_map_osgb,   500, 2, 8, 'm2_mways',   'the_geom') as home_mway_dist,
    nnDistance(home_map_osgb,   500, 2, 8, 'm2_railway', 'the_geom') as home_railway_dist,
    nnDistance(home_map_osgb,   500, 2, 8, 'm2_stations','the_geom') as home_station_dist,
    nnDistance(home_map_osgb,   500, 2, 8, 'm2_coast',   'the_geom') as home_coast_dist,
    nnDistance(home_map_osgb,   500, 2, 8, 'm2_river',   'the_geom') as home_river_dist,
    st_distance(other_map_osgb, (select the_geom from zone1))        as other_z1_dist,
    nnDistance(other_map_osgb,  500, 2, 8, 'zone1tubes', 'the_geom') as other_z1tube_dist,
    nnDistance(other_map_osgb,  500, 2, 8, 'tube_stops', 'the_geom') as other_tube_dist,
    nnDistance(other_map_osgb,  500, 2, 8, 'm2_mways',   'the_geom') as other_mway_dist,
    nnDistance(other_map_osgb,  500, 2, 8, 'm2_railway', 'the_geom') as other_railway_dist,
    nnDistance(other_map_osgb,  500, 2, 8, 'm2_stations','the_geom') as other_station_dist,
    nnDistance(other_map_osgb,  500, 2, 8, 'm2_coast',   'the_geom') as other_coast_dist,
    nnDistance(other_map_osgb,  500, 2, 8, 'm2_river',   'the_geom') as other_river_dist
  from london_survey
);
create unique index londonmeridian_id_idx on london_meridian (id);
analyze london_meridian;

)

-- Adding Meridian and designation nearests table (UK) (

drop table if exists uk_nearests;
create table uk_nearests as (
  select 
    id,
    nnDistance(home_postcode_osgb,   500, 2, 12, 'm2_mways',   'the_geom') as home_mway_dist,
    nnDistance(home_postcode_osgb,   500, 2, 12, 'm2_aroads',  'the_geom') as home_aroad_dist,
    nnDistance(home_postcode_osgb,   500, 2, 12, 'm2_railway', 'the_geom') as home_railway_dist,
    nnDistance(home_postcode_osgb,   500, 2, 12, 'm2_stations','the_geom') as home_station_dist,
    nnDistance(home_postcode_osgb,   500, 2, 12, 'm2_coast',   'the_geom') as home_coast_dist,
    nnDistance(home_postcode_osgb,   500, 2, 12, 'm2_river',   'the_geom') as home_river_dist,
    nnDistance(home_postcode_osgb,   500, 2, 12, 'natparks',   'the_geom') as home_natpark_dist,
    nnDistance(home_postcode_osgb,   500, 2, 12, 'aonbs',      'the_geom') as home_aonb_dist,
    nnDistance(home_postcode_osgb,   500, 2, 12, 'nnrs',       'the_geom') as home_nnr_dist,
    nnDistance(other_postcode_osgb,  500, 2, 12, 'm2_mways',   'the_geom') as other_mway_dist,
    nnDistance(other_postcode_osgb,  500, 2, 12, 'm2_aroads',  'the_geom') as other_aroad_dist,
    nnDistance(other_postcode_osgb,  500, 2, 12, 'm2_railway', 'the_geom') as other_railway_dist,
    nnDistance(other_postcode_osgb,  500, 2, 12, 'm2_stations','the_geom') as other_station_dist,
    nnDistance(other_postcode_osgb,  500, 2, 12, 'm2_coast',   'the_geom') as other_coast_dist,
    nnDistance(other_postcode_osgb,  500, 2, 12, 'm2_river',   'the_geom') as other_river_dist,
    nnDistance(other_postcode_osgb,  500, 2, 12, 'natparks',   'the_geom') as other_natpark_dist,
    nnDistance(other_postcode_osgb,  500, 2, 12, 'aonbs',      'the_geom') as other_aonb_dist,
    nnDistance(other_postcode_osgb,  500, 2, 12, 'nnrs',       'the_geom') as other_nnr_dist
  from uk_survey
);
create unique index uknearests_id_idx on uk_nearests (id);
analyze uk_nearests;

)

-- Adding LSOA house prices (

alter table london_survey add column home_lsoa_house_price_fe real;
update london_survey s set home_lsoa_house_price_fe = price_fe from lsoa_house_price_fes p where s.home_lsoa_or_dzone = p.code;

alter table london_survey add column other_lsoa_house_price_fe real;
update london_survey s set other_lsoa_house_price_fe = price_fe from lsoa_house_price_fes p where s.other_lsoa_or_dzone = p.code;

alter table uk_survey add column home_lsoa_house_price_fe real;
update uk_survey s set home_lsoa_house_price_fe = price_fe from lsoa_house_price_fes p where s.home_lsoa_or_dzone = p.code;

alter table uk_survey add column other_lsoa_house_price_fe real;
update uk_survey s set other_lsoa_house_price_fe = price_fe from lsoa_house_price_fes p where s.other_lsoa_or_dzone = p.code;

)

-- Adding nearby LCM category proportions (

-- 200m, 1km, 3km radius  (uniform/unweighted)
-- 200m, 1km      std dev (normal kernel)

-- $1 = area geometry
-- $2 = kernel centre point geometry
-- $3 = kernel std dev
-- $4 = truncation bandwidth (for normal kernel only -- for others, repeat $3)
-- $5 = number of slices for approximation
-- $6 = buffer precision (points per 1/4 circle)

-- see separate file: joining_lcm.rb

)

-- Adding OSM and GiGL green space (London) (

-- see separate file: joining_london_green.rb

)

-- Adding mean house price residuals (

alter table uk_survey add column home_house_price_med9 real;
update uk_survey u set home_house_price_med9 = (
  select residual from (
    select * from nnReals(
        u.home_postcode_osgb    -- nearTo                   geometry
      , 750                     -- initialDistance          real
      , 2                       -- distanceMultiplier       real 
      , 500                     -- maxPower                 integer
      , 'house_price_residuals' -- nearThings               text
      , 'the_geom'              -- nearThingsGeometryField  text
      , 'residual'              -- nearThingsRealField      text
      , 9                       -- numWanted                integer
    ) as residual
  ) as residual order by residual limit 1 offset 4
);

alter table london_survey add column home_house_price_med9 real;
update london_survey u set home_house_price_med9 = (
  select residual from (
    select * from nnReals(
        u.home_map_osgb         -- nearTo                   geometry
      , 750                     -- initialDistance          real
      , 2                       -- distanceMultiplier       real 
      , 500                     -- maxPower                 integer
      , 'house_price_residuals' -- nearThings               text
      , 'the_geom'              -- nearThingsGeometryField  text
      , 'residual'              -- nearThingsRealField      text
      , 9                       -- numWanted                integer
    ) as residual
  ) as residual order by residual limit 1 offset 4
);

)

