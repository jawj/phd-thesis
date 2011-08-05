
-- Adding map points (London only) (

-- alter table london_survey drop column home_map_osgb;
select addgeometrycolumn('london_survey', 'home_map_osgb', 27700, 'POINT', 2);
update london_survey set home_map_osgb = st_transform(
  st_setsrid(st_makepoint(home_lon, home_lat), 4326), 
  27700
);

-- alter table london_survey drop column other_map_osgb;
select addgeometrycolumn('london_survey', 'other_map_osgb', 27700, 'POINT', 2);
update london_survey set other_map_osgb = st_transform(
  st_setsrid(st_makepoint(other_lon, other_lat), 4326), 
  27700
);

)

-- Adding postcode points (

-- alter table london_survey drop column home_postcode_osgb;
select addgeometrycolumn('london_survey', 'home_postcode_osgb', 27700, 'POINT', 2);
update london_survey l set home_postcode_osgb = the_geom 
  from nspd2010aug n where l.home_postcode = n.postcode_no_sp;

-- alter table london_survey drop column other_postcode_osgb;
select addgeometrycolumn('london_survey', 'other_postcode_osgb', 27700, 'POINT', 2);
update london_survey l set other_postcode_osgb = the_geom 
  from nspd2010aug n where l.other_postcode = n.postcode_no_sp;

-- alter table uk_survey drop column home_postcode_osgb;
select addgeometrycolumn('uk_survey', 'home_postcode_osgb', 27700, 'POINT', 2);
update uk_survey l set home_postcode_osgb = the_geom 
  from nspd2010aug n where l.home_postcode = n.postcode_no_sp;

-- alter table uk_survey drop column other_postcode_osgb;
select addgeometrycolumn('uk_survey', 'other_postcode_osgb', 27700, 'POINT', 2);
update uk_survey l set other_postcode_osgb = the_geom 
  from nspd2010aug n where l.other_postcode = n.postcode_no_sp;

)

-- Adding postcode polygons (
  
-- alter table london_survey drop column home_postcode_poly;
select addgeometrycolumn('london_survey', 'home_postcode_poly', 27700, 'MULTIPOLYGON', 2);
update london_survey l set home_postcode_poly = the_geom 
  from cpp_polygons p where l.home_postcode = p.postcode_no_sp;

-- alter table london_survey drop column other_postcode_poly;
select addgeometrycolumn('london_survey', 'other_postcode_poly', 27700, 'MULTIPOLYGON', 2);
update london_survey l set other_postcode_poly = the_geom 
  from cpp_polygons p where l.other_postcode = p.postcode_no_sp;

-- alter table uk_survey drop column home_postcode_poly;
select addgeometrycolumn('uk_survey', 'home_postcode_poly', 27700, 'MULTIPOLYGON', 2);
update uk_survey l set home_postcode_poly = the_geom 
  from cpp_polygons p where l.home_postcode = p.postcode_no_sp;

-- alter table uk_survey drop column other_postcode_poly;
select addgeometrycolumn('uk_survey', 'other_postcode_poly', 27700, 'MULTIPOLYGON', 2);
update uk_survey l set other_postcode_poly = the_geom 
  from cpp_polygons p where l.other_postcode = p.postcode_no_sp;

)

-- Adding LSOAs/dzones (

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

-- Adding Experian data (
  
alter table london_survey add column hh_no integer;
update london_survey s set hh_no = e.hh_no from experian2009 e where s.lsoa = e.lsoa
e.hh_no as home_hh_no, 

)


-- Adding LSOA/dzone polys (
  
)

-- Adding crime (
  
)

