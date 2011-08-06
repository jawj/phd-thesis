
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

-- Adding LSOA/dzone polys (
  
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

)

-- Adding crime table (

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

