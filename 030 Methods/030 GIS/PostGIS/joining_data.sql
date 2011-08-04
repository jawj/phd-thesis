
-- Adding geometries

-- alter table london_survey drop column home_geom_osgb;
select addgeometrycolumn('london_survey', 'home_geom_osgb', 27700, 'POINT', 2);
update london_survey set home_geom_osgb = st_transform(
  st_setsrid(st_makepoint(home_lon, home_lat), 4326), 
  27700
);

-- alter table london_survey drop column other_geom_osgb;
select addgeometrycolumn('london_survey', 'other_geom_osgb', 27700, 'POINT', 2);
update london_survey set other_geom_osgb = st_transform(
  st_setsrid(st_makepoint(other_lon, other_lat), 4326), 
  27700
);


