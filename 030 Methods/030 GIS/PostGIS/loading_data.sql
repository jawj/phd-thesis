create database phd template postgis_template;
psql -d phd -U postgres -f /usr/local/pgsql/share/contrib/postgis-1.5/postgis_upgrade_15_minor.sql

-- LAEI 2008 (London) (

cd "/Users/George/GIS/Data/Air quality/LAEI_2008/Concentration maps"
shp2pgsql -D -I -s 27700 "laei-2008-no2a-20mgrid-shp/LAEI08_NO2a.shp"   laei08_no2a  | psql -d phd -U postgres
shp2pgsql -D -I -s 27700 "laei-2008-pm10a-20mgrid-shp/LAEI08_PM10a.shp" laei08_pm10a | psql -d phd -U postgres
shp2pgsql -D -I -s 27700 "laei-2008-pm10e-20mgrid-shp/LAEI08_PM10e.shp" laei08_pm10e | psql -d phd -U postgres

)

-- LCM 2000 (

cd "/Users/George/GIS/Data/Land use/Land Cover Map 2000"
shp2pgsql -D -I -s 27700 "gdal_polygonize_output.shp"    lcm2000gb | psql -d phd -U postgres
shp2pgsql -D -I -s 29903 "gdal_polygonize_output_ni.shp" lcm2000ni | psql -d phd -U postgres

/* no -- makes qgis hang for minutes on end! -- bug 3453
create view lcm2000uk as (
  select gid, dn, the_geom from lcm2000gb
  union
  select gid + 5000000, dn, st_transform(the_geom, 27700) from lcm2000ni
);

create view lcm2000uk_1k as (  
  select gid, dn, the_geom from lcm2000uk where gid % 1000 = 0  -- to check visually
);
*/

)

-- NSPD (

create table nspd2010aug (
 postcode_7 char(7),
 postcode_8 char(8),
 postcode_egif char(8),
 intro_date_string char(6),
 termination_date_string char(6),
 county char(2),
 la char(2),
 ward char(2),
 large_user char(1),
 grid_easting char(6),
 grid_northing char(7),
 grid_ref_quality char(1),
 health_authority char(3),
 pan_sha char(3),
 country char(3),
 non_geo char(1),
 in_paf char(1),
 go_region char(1),
 ssr char(1),
 parl_const char(3),
 eer char(2),
 tecr char(3),
 ttwa char(3),
 pct char(5),
 nuts char(10),
 ed_1991_ogss char(8),
 ed_1991 char(6),
 ed_quality char(1),
 address_count char(4),
 delivery_point_count char(4),
 multiple_occupancy_count char(4),
 small_business_count char(4),
 previous_sha char(3),
 lea char(3),
 ha char(3),
 ward_1991 char(6),
 ward_1991_ogss char(6),
 ward_1998 char(6),
 stat_ward_2005 char(6),
 oa char(10),
 oa_indicator char(1),
 cas_ward char(6),
 national_park char(2),
 lsoa char(9), -- 44
 scottish_dzone char(9), -- 45
 msoa char(9), -- 46
 urban_rural_ew char(1),
 urban_rural_scot char(1),
 urban_rural_ni char(1),
 scottish_izone char(9), -- 50
 soa_ni char(8),
 oa_class char(3),
 old_pct char(5)
);
copy nspd2010aug from '/Users/George/GIS/Data/Borders, boundaries, codes/NSPDF_AUG_2010_UK_1M_FP.csv' csv;
alter table nspd2010aug add column postcode_no_sp text;
update nspd2010aug set postcode_no_sp = replace(postcode_7, ' ', '');
alter table nspd2010aug add primary key (postcode_no_sp);
select addgeometrycolumn('nspd2010aug', 'the_geom', 27700, 'POINT', 2);
update nspd2010aug set the_geom = st_transform(
  st_setsrid(
    st_makepoint(
      cast(grid_easting as integer),
      cast(grid_northing as integer)
    ), 
    case when country = '152' then 29903 else 27700 end
  ),
  27700
) where grid_ref_quality != '9';

)

-- Code Point Polygons (

create table cpp_vertical_streets (postcode text, vstreet text);
create table cpp_discards (postcode text, reason text);

-- IRB -- load all data

# create main polygons table 
path = '/Users/George/GIS/Data/Borders, boundaries, codes/CodePoint polygons'
`shp2pgsql -p -D -s 27700 "#{path}/ab.shp" cpp_polygons | psql -d phd -U postgres`

# copy in all polygons, vstreets and discards (5 - 10 mins)
Dir["#{path}/*.shp"].each do |f|
  puts f
  `shp2pgsql -a -D -s 27700 "#{f}" cpp_polygons | psql -d phd -U postgres`
  `echo "copy cpp_vertical_streets from '#{f.sub(/\.shp$/, '_vstreet_lookup.txt')}' csv;" | psql -d phd -U postgres`
  `echo "copy cpp_discards from '#{f.sub(/\.shp$/, '_discard.txt')}' csv;" | psql -d phd -U postgres`
end


-- SQL

-- standard polygons
create type cpp_type as enum ('standard', 'discard', 'vstreet_only', 'standard_and_vstreet');
alter table cpp_polygons add column type cpp_type default 'standard'; 
create unique index pc_index on cpp_polygons (postcode);
analyze cpp_polygons;

-- vstreets
create sequence cpp_vstreet_seq start with 2000000;
create table cpp_vstreet_polys as (
  select 
    nextval('cpp_vstreet_seq') as gid, 
    v.postcode as postcode, 
    cast(null as text) as upp, 
    max(p.pc_area) as pc_area,
    st_union(p.the_geom) as the_geom, 
    cast('vstreet_only' as cpp_type) as type
  from cpp_vertical_streets v 
  left join cpp_polygons p 
  on v.vstreet = p.postcode
  group by v.postcode
);

-- vstreets + standard
create sequence cpp_vstreet_and_std_seq start with 3000000;
create table cpp_vstreet_and_std_polys as (
select 
  nextval('cpp_vstreet_and_std_seq') as gid, 
  p.postcode as postcode,
  cast(null as text) as upp, 
  p.pc_area as pc_area,
  st_multi(st_union(p.the_geom, v.the_geom)) as the_geom, 
  cast('standard_and_vstreet' as cpp_type) as type
from cpp_polygons p
inner join cpp_vstreet_polys v
on p.postcode = v.postcode
);

-- discards
create sequence cpp_discard_seq start with 4000000;
create table cpp_discard_polys as (
select 
  nextval('cpp_discard_seq') as gid, 
  postcode,
  cast(null as text) as upp, 
  substring(postcode from '^[A-Z][A-Z]?') as pc_area, 
  cast(null as geometry) as the_geom, 
  cast('discard' as cpp_type) as type
from cpp_discards
);

-- tidying and merging

delete from cpp_discard_polys where postcode in (select postcode from cpp_polygons); -- no rows
delete from cpp_discard_polys where postcode in (select postcode from cpp_vstreet_polys); -- 1106 rows -- oops!
delete from cpp_polygons where postcode in (select postcode from cpp_vstreet_and_std_polys);
delete from cpp_vstreet_polys where postcode in (select postcode from cpp_vstreet_and_std_polys);
  
insert into cpp_polygons select * from cpp_discard_polys;
insert into cpp_polygons select * from cpp_vstreet_polys;
insert into cpp_polygons select * from cpp_vstreet_and_std_polys;

alter table cpp_polygons add column postcode_no_sp text;
update cpp_polygons set postcode_no_sp = replace(postcode, ' ', ''); -- 12 mins
create unique index pcns_index on cpp_polygons (postcode_no_sp);

vacuum analyze cpp_polygons;
 
)

-- Experian (
  
create table experian2009 (
lsoa text,
mosaic_grp_1 integer,
mosaic_grp_2 integer,
mosaic_grp_3 integer,
mosaic_grp_4 integer,
mosaic_grp_5 integer,
mosaic_grp_6 integer,
mosaic_grp_7 integer,
mosaic_grp_8 integer,
mosaic_grp_9 integer,
mosaic_grp_10 integer,
mosaic_grp_11 integer,
mosaic_grp_unknown integer,
mosaic_type_1 integer,
mosaic_type_2 integer,
mosaic_type_3 integer,
mosaic_type_4 integer,
mosaic_type_5 integer,
mosaic_type_6 integer,
mosaic_type_7 integer,
mosaic_type_8 integer,
mosaic_type_9 integer,
mosaic_type_10 integer,
mosaic_type_11 integer,
mosaic_type_12 integer,
mosaic_type_13 integer,
mosaic_type_14 integer,
mosaic_type_15 integer,
mosaic_type_16 integer,
mosaic_type_17 integer,
mosaic_type_18 integer,
mosaic_type_19 integer,
mosaic_type_20 integer,
mosaic_type_21 integer,
mosaic_type_22 integer,
mosaic_type_23 integer,
mosaic_type_24 integer,
mosaic_type_25 integer,
mosaic_type_26 integer,
mosaic_type_27 integer,
mosaic_type_28 integer,
mosaic_type_29 integer,
mosaic_type_30 integer,
mosaic_type_31 integer,
mosaic_type_32 integer,
mosaic_type_33 integer,
mosaic_type_34 integer,
mosaic_type_35 integer,
mosaic_type_36 integer,
mosaic_type_37 integer,
mosaic_type_38 integer,
mosaic_type_39 integer,
mosaic_type_40 integer,
mosaic_type_41 integer,
mosaic_type_42 integer,
mosaic_type_43 integer,
mosaic_type_44 integer,
mosaic_type_45 integer,
mosaic_type_46 integer,
mosaic_type_47 integer,
mosaic_type_48 integer,
mosaic_type_49 integer,
mosaic_type_50 integer,
mosaic_type_51 integer,
mosaic_type_52 integer,
mosaic_type_53 integer,
mosaic_type_54 integer,
mosaic_type_55 integer,
mosaic_type_56 integer,
mosaic_type_57 integer,
mosaic_type_58 integer,
mosaic_type_59 integer,
mosaic_type_60 integer,
mosaic_type_61 integer,
mosaic_type_unknown integer,
hh_no integer,
median_hh_income double precision,
females_0004_in_2009 integer,
females_0004_in_2014 integer,
females_0004_in_2019 integer,
females_0509_in_2009 integer,
females_0509_in_2014 integer,
females_0509_in_2019 integer,
females_1014_in_2009 integer,
females_1014_in_2014 integer,
females_1014_in_2019 integer,
females_1519_in_2009 integer,
females_1519_in_2014 integer,
females_1519_in_2019 integer,
females_2024_in_2009 integer,
females_2024_in_2014 integer,
females_2024_in_2019 integer,
females_2529_in_2009 integer,
females_2529_in_2014 integer,
females_2529_in_2019 integer,
females_3034_in_2009 integer,
females_3034_in_2014 integer,
females_3034_in_2019 integer,
females_3539_in_2009 integer,
females_3539_in_2014 integer,
females_3539_in_2019 integer,
females_4044_in_2009 integer,
females_4044_in_2014 integer,
females_4044_in_2019 integer,
females_4549_in_2009 integer,
females_4549_in_2014 integer,
females_4549_in_2019 integer,
females_5054_in_2009 integer,
females_5054_in_2014 integer,
females_5054_in_2019 integer,
females_5559_in_2009 integer,
females_5559_in_2014 integer,
females_5559_in_2019 integer,
females_6064_in_2009 integer,
females_6064_in_2014 integer,
females_6064_in_2019 integer,
females_6569_in_2009 integer,
females_6569_in_2014 integer,
females_6569_in_2019 integer,
females_7074_in_2009 integer,
females_7074_in_2014 integer,
females_7074_in_2019 integer,
females_7579_in_2009 integer,
females_7579_in_2014 integer,
females_7579_in_2019 integer,
females_8084_in_2009 integer,
females_8084_in_2014 integer,
females_8084_in_2019 integer,
females_85_in_2009 integer,
females_85_in_2014 integer,
females_85_in_2019 integer,
males_0004_in_2009 integer,
males_0004_in_2014 integer,
males_0004_in_2019 integer,
males_0509_in_2009 integer,
males_0509_in_2014 integer,
males_0509_in_2019 integer,
males_1014_in_2009 integer,
males_1014_in_2014 integer,
males_1014_in_2019 integer,
males_1519_in_2009 integer,
males_1519_in_2014 integer,
males_1519_in_2019 integer,
males_2024_in_2009 integer,
males_2024_in_2014 integer,
males_2024_in_2019 integer,
males_2529_in_2009 integer,
males_2529_in_2014 integer,
males_2529_in_2019 integer,
males_3034_in_2009 integer,
males_3034_in_2014 integer,
males_3034_in_2019 integer,
males_3539_in_2009 integer,
males_3539_in_2014 integer,
males_3539_in_2019 integer,
males_4044_in_2009 integer,
males_4044_in_2014 integer,
males_4044_in_2019 integer,
males_4549_in_2009 integer,
males_4549_in_2014 integer,
males_4549_in_2019 integer,
males_5054_in_2009 integer,
males_5054_in_2014 integer,
males_5054_in_2019 integer,
males_5559_in_2009 integer,
males_5559_in_2014 integer,
males_5559_in_2019 integer,
males_6064_in_2009 integer,
males_6064_in_2014 integer,
males_6064_in_2019 integer,
males_6569_in_2009 integer,
males_6569_in_2014 integer,
males_6569_in_2019 integer,
males_7074_in_2009 integer,
males_7074_in_2014 integer,
males_7074_in_2019 integer,
males_7579_in_2009 integer,
males_7579_in_2014 integer,
males_7579_in_2019 integer,
males_8084_in_2009 integer,
males_8084_in_2014 integer,
males_8084_in_2019 integer,
males_85_in_2009 integer,
males_85_in_2014 integer,
males_85_in_2019 integer
);

copy experian2009 from '/Users/George/GIS/Data/Social/Experian Super Output Area data/2009/Experian_2009_LSOA_DZ.csv' csv header;
create unique index exp09_lsoa_index on experian2009 (lsoa);
analyze experian2009;

)

-- UK outline (

cd "/Users/George/GIS/Data/Borders, boundaries, codes/Countries"
shp2pgsql -D -I -s 27700 "England/england_ol_2001.shp"         england  | psql -d phd -U postgres
shp2pgsql -D -I -s 27700 "NI/nireland_ol_2001.shp"             nireland | psql -d phd -U postgres
shp2pgsql -D -I -s 27700 "Scotland/Scotland_ol_2001_area.shp"  scotland | psql -d phd -U postgres
shp2pgsql -D -I -s 27700 "Wales/Wales_ol_2001_area.shp"        wales    | psql -d phd -U postgres

create table uk250m as (
  select st_simplifypreservetopology(st_union(the_geom), 250) as the_geom from (
              select the_geom from england
    union all select the_geom from wales
    union all select the_geom from scotland
    union all select the_geom from nireland
  ) as uk
);
alter table uk250m add column id serial primary key;

)

-- Airport noise (Heathrow) (

cd "/Users/George/GIS/Data/Noise/Airport noise/Heathrow 2009"
psql -d phd -U postgres < Standard/lhr09_leq_standard.sql

drop table lhr09_leq_standard_lay;
drop table lhr09_leq_standard_lin;
drop table lhr09_leq_standard_pnt;
drop table lhr09_leq_standard_txt;
alter table lhr09_leq_standard_plg add column db integer;
update lhr09_leq_standard_plg set db = cast(substring(layer from 'x[0-9]x([0-9]+)') as integer);

)

-- OSM (London) (

psql -d phd -U postgres < ~/bin/osmosis/script/pgsimple_schema_0.6.sql
cd "/Users/George/GIS/Data/Transport and mapping/OpenStreetMap/Cloudmade22June2011"
bzip2 -d -c england.osm.bz2 | ~/bin/osmosis/bin/osmosis -verbose \
  --read-xml /dev/stdin \
  --bounding-box top=51.793328497122545 right=0.4888916015625 bottom=51.176760221369186 left=-0.655059814453125 \
  --write-pgsimp host=localhost database=phd user=postgres # 10 mins

create sequence green_seq;
create table osm_green_spaces as (
  select
  nextval('green_seq') as id,
  way_id as osm_way_id,
  st_makepolygon(st_makeline(points)) as wgs84_polygon,
  st_transform(st_makepolygon(st_makeline(points)), 27700) as osgb36_polygon,
  max(k) as k, max(v) as v, max(name) as name,
  st_area(transform(st_makepolygon(st_makeline(points)), 27700)) as area,
  st_perimeter(st_transform(st_makepolygon(st_makeline(points)), 27700)) as perimeter
  from (
    select nodes.geom as points,
      wt1.way_id as way_id, wt1.k as k, wt1.v as v, wt2.v as name
    from way_tags as wt1
    inner join ways
      on wt1.way_id = ways.id
    inner join way_nodes
      on ways.id = way_nodes.way_id
    inner join nodes
      on way_nodes.node_id = nodes.id
    left outer join way_tags as wt2
      on wt1.way_id = wt2.way_id and wt2.k = 'name'
    where (
         (wt1.k = 'leisure' and wt1.v = 'park')
      or (wt1.k = 'leisure' and wt1.v = 'common')
      or (wt1.k = 'natural' and wt1.v = 'wood')
      or (wt1.k = 'natural' and wt1.v = 'heath')
      or (wt1.k = 'natural' and wt1.v = 'fell')
      or (wt1.k = 'natural' and wt1.v = 'marsh')
      or (wt1.k = 'natural' and wt1.v = 'wetland')
      or (wt1.k = 'landuse' and wt1.v = 'forest')
      or (wt1.k = 'landuse' and wt1.v = 'meadow')
      or (wt1.k = 'landuse' and wt1.v = 'allotments')
      or (wt1.k = 'landuse' and wt1.v = 'village_green')
      or (wt1.k = 'landuse' and wt1.v = 'recreation_ground')
    )
    order by sequence_id
  ) as ways
group by way_id
having st_numpoints(st_makeline(points)) > 3
and st_isclosed(st_makeline(points))
);
create index idx_osgb36_polygon on osm_green_spaces using gist(osgb36_polygon);
create index idx_wgs84_polygon on osm_green_spaces using gist(wgs84_polygon);

create sequence park_seq;
create table osm_parks as (
  select
  nextval('park_seq') as id,
  way_id as osm_way_id,
  st_makepolygon(st_makeline(points)) as wgs84_polygon,
  st_transform(st_makepolygon(st_makeline(points)), 27700) as osgb36_polygon,
  max(k) as k, max(v) as v, max(name) as name,
  st_area(transform(st_makepolygon(st_makeline(points)), 27700)) as area,
  st_perimeter(st_transform(st_makepolygon(st_makeline(points)), 27700)) as perimeter
  from (
    select nodes.geom as points,
      wt1.way_id as way_id, wt1.k as k, wt1.v as v, wt2.v as name
    from way_tags as wt1
    inner join ways
      on wt1.way_id = ways.id
    inner join way_nodes
      on ways.id = way_nodes.way_id
    inner join nodes
      on way_nodes.node_id = nodes.id
    left outer join way_tags as wt2
      on wt1.way_id = wt2.way_id and wt2.k = 'name'
    where (
         (wt1.k = 'leisure' and wt1.v = 'park')
      or (wt1.k = 'leisure' and wt1.v = 'common')
      or (wt1.k = 'landuse' and wt1.v = 'village_green')
      or (wt1.k = 'landuse' and wt1.v = 'recreation_ground')
    )
    order by sequence_id
  ) as ways
group by way_id
having st_numpoints(st_makeline(points)) > 3
and st_isclosed(st_makeline(points))
);
create index parks_idx_osgb36_polygon on osm_parks using gist(osgb36_polygon);
create index parks_idx_wgs84_polygon on osm_parks using gist(wgs84_polygon);

)

-- Defra noise (London) (

cd "/Users/George/GIS/Data/Noise/Defra noise data"
shp2pgsql -D -I -s 27700 "London_Rail/london_rail_lden.gdal_polygonize.shp" noise_rail_lden \
  | psql -d phd -U postgres
shp2pgsql -D -I -s 27700 "London_Road/london_roads_lden.gdal_polygonize.shp" noise_road_lden \
  | psql -d phd -U postgres

)

-- Crime (London) (

create table crime_tno (lsoa char(9), tno integer);
create table crime_vap (lsoa char(9), vap integer);
create table crime_rb  (lsoa char(9), rb integer);
create table lsoa_pop  (lsoa char(9), pop integer);

copy crime_tno from '/Users/George/Dropbox/Academic/PhD/London LS and EQ/Geo data/Crime/total_notifiable_offences_0809.csv' csv;
copy crime_vap from '/Users/George/Dropbox/Academic/PhD/London LS and EQ/Geo data/Crime/violence_against_person_0809.csv' csv;
copy crime_rb  from '/Users/George/Dropbox/Academic/PhD/London LS and EQ/Geo data/Crime/residential_burglary_0809.csv' csv;
copy lsoa_pop  from '/Users/George/Dropbox/Academic/PhD/London LS and EQ/Geo data/Crime/lsoa_population_mid_08.csv' csv;

create index crime_tno_lsoa_index on crime_tno (lsoa);
create index crime_vap_lsoa_index on crime_vap (lsoa);
create index crime_rb_lsoa_index on crime_rb (lsoa);
create index lsoa_pop_lsoa_index on lsoa_pop (lsoa);

analyze crime_tno;
analyze crime_vap;
analyze crime_rb;
analyze lsoa_pop;

)

-- Meridian 2 (GB) (

cd "/Users/George/GIS/Data/Transport and mapping/Meridian 2 Shape 2/data"
shp2pgsql -D -I -s 27700 "rail_ln_polyline.shp"   m2_railway  | psql -d phd -U postgres
shp2pgsql -D -I -s 27700 "motorway_polyline.shp"  m2_mways    | psql -d phd -U postgres
shp2pgsql -D -I -s 27700 "a_road_polyline.shp"    m2_aroads   | psql -d phd -U postgres
shp2pgsql -D -I -s 27700 "coast_ln_polyline.shp"  m2_coast    | psql -d phd -U postgres
shp2pgsql -D -I -s 27700 "river_polyline.shp"     m2_river    | psql -d phd -U postgres
shp2pgsql -D -I -s 27700 "station_point.shp"      m2_stations | psql -d phd -U postgres

)

-- Designations -- AONBs, NNRs, NPs (UK) (

# National Parks

cd "/Users/George/GIS/Data/Nature/National Parks"
shp2pgsql -D -s 27700 "English National Parks/magnatpk.shp"     natparkseng | psql -d phd -U postgres
shp2pgsql -D -s 27700 "Scottish National Parks/NP_SCOTLAND.shp" natparkssco | psql -d phd -U postgres
shp2pgsql -D -s 27700 "Welsh National Parks/wales_np_2001.shp"  natparkswal | psql -d phd -U postgres

create table natparks as (
  select name, the_geom from natparkseng
  union all
  select name, the_geom from natparkssco
  union all
  select name, the_geom from natparkswal
);
alter table natparks add column id serial primary key;
create index natparks_geom_idx on natparks using gist(the_geom);
analyze natparks;
drop table natparkseng;
drop table natparkssco;
drop table natparkswal;

# AoNBs

cd "/Users/George/GIS/Data/Nature/AoNBs"
shp2pgsql -D -s 27700 "English AoNBs/magaonb.shp"                    aonbseng | psql -d phd -U postgres
shp2pgsql -D -s 27700 "NI AoNBs - OSGB/AONB.shp"                     aonbsni  | psql -d phd -U postgres
shp2pgsql -D -s 27700 "Welsh AoNBs/esri\all-wales\aonb.shp"          aonbswal | psql -d phd -U postgres
shp2pgsql -D -s 27700 "Scottish National Scenic Areas/NSA_2010.shp"  aonbssco | psql -d phd -U postgres

create table aonbs as (
  select name, the_geom from aonbseng
  union all
  select name, the_geom from aonbsni
  union all
  select aonb_name, the_geom from aonbswal
  union all
  select first_name, the_geom from aonbssco
);
alter table aonbs add column id serial primary key;
create index aonbs_geom_idx on aonbs using gist(the_geom);
analyze aonbs;
drop table aonbseng;
drop table aonbsni;
drop table aonbswal;
drop table aonbssco;

# NNRs

cd "/Users/George/GIS/Data/Nature/National Nature Reserves"
shp2pgsql -D -s 27700 "English National Nature Reserves/nnr.shp"              nnrseng | psql -d phd -U postgres
shp2pgsql -D -s 27700 "NI National Nature Reserves - OSGB/nnrs.shp"           nnrsni  | psql -d phd -U postgres
shp2pgsql -D -s 27700 "Scottish National Nature Reserves/NNR_SCOTLAND.shp"    nnrssco | psql -d phd -U postgres
shp2pgsql -D -s 27700 "Welsh National Nature Reserves/esri\all-wales\NNR.shp" nnrswal | psql -d phd -U postgres

create table nnrs as (
  select nnr_name as name, the_geom from nnrseng
  union all
  select name, the_geom from nnrsni
  union all
  select nnr_name, the_geom from nnrswal
  union all
  select site_name, the_geom from nnrssco
);
alter table nnrs add column id serial primary key;
create index nnrs_geom_idx on nnrs using gist(the_geom);
analyze nnrs;
drop table nnrseng;
drop table nnrsni;
drop table nnrswal;
drop table nnrssco;

)

-- GiGL data: open spaces and AoDs (

cd "/Users/George/GIS/Data/GiGL"
export PATH="/Library/Frameworks/GDAL.framework/Programs/:$PATH"
ogr2ogr -f "PostgreSQL" -a_srs "EPSG:27700" PG:"user=postgres dbname=phd" AOD.TAB -nln aods
ogr2ogr -f "PostgreSQL" -a_srs "EPSG:27700" PG:"user=postgres dbname=phd" GiGL_Openspace_ALGG.TAB -nln giglopenspace

)

-- LSOAs and dzone centroids (

create table lsoas (
  code char(9),
  name text,
  geoeast integer,
  geonorth integer,
  popeast integer,
  popnorth integer
);
copy lsoas from '/Users/George/GIS/Data/Borders, boundaries, codes/LSOAs/LSOA_centroids_Apr05.csv' csv header;
select addgeometrycolumn('lsoas', 'geo_geom', 27700, 'POINT', 2);
update lsoas set geo_geom = st_setsrid(st_makepoint(geoeast, geonorth), 27700);
alter table lsoas add column gid serial primary key;
create unique index lsoas_code_index on lsoas (code);


shp2pgsql -D -s 27700 "/Users/George/GIS/Data/Borders, boundaries, codes/SNS_Geography_24_2_2011/Datazones_Centroids_V2.shp" dzones | psql -d phd -U postgres
create unique index dzones_zonecode_index on dzones (zonecode);

)

-- LSOA/dzone house prices (

create table lsoa_house_price_fes (
  code char(9) primary key,
  price_fe real
);
copy lsoa_house_price_fes from '/Users/George/GIS/Data/Social/House prices/NATIONWIDE/lsoa_price_fes.csv' csv header;

create table lsoa_dzone_prices as (
  select l.code, name, geo_geom, price_fe from lsoas l left join lsoa_house_price_fes p on l.code = p.code
);
insert into lsoa_dzone_prices (
  select zonecode, null, the_geom, price_fe from dzones d left join lsoa_house_price_fes p on d.zonecode = p.code
);
alter table lsoa_dzone_prices add column gid serial primary key;
create unique index lsoa_dzone_code_index on lsoa_dzone_prices (code);
create index lsoa_dzone_geo_geom_idx on lsoa_dzone_prices using gist(geo_geom);
analyze lsoa_dzone_prices;

)

-- LSOA/dzone polygons (

cd "/Users/George/GIS/Data/Borders, boundaries, codes/LSOAs"
export PATH="/Library/Frameworks/GDAL.framework/Programs/:$PATH"
ogr2ogr -f "PostgreSQL" -a_srs "EPSG:27700" PG:"user=postgres dbname=phd" LSOA_FEB_2004_EW_BFE.mif -nln lsoa_polys

cd "/Users/George/GIS/Data/Borders, boundaries, codes/SNS_Geography_24_2_2011"
shp2pgsql -D -I -s 27700 datazones_2001.shp dzone_polys | psql -d phd -U postgres

)

-- Tube stations (

create table tube_stops (
  id integer primary key,
  lat real,
  lon real,
  name text,
  dummy text,
  zone real, -- can be x.5
  lines integer,
  rail integer
);
copy tube_stops from '/Users/George/GIS/Data/Transport and mapping/Tube network/stations.csv' csv header;
alter table tube_stops drop column dummy;
alter table tube_stops add column low_zone integer;
update tube_stops set low_zone = floor(zone);
select addgeometrycolumn('tube_stops', 'the_geom', 27700, 'POINT', 2);
update tube_stops set the_geom = st_transform(st_setsrid(st_makepoint(lon, lat), 4326), 27700);

/* -- for official TfL data -- but missing many zone details!
require 'hpricot'
require 'csv'
h = Hpricot(File.open("/Users/George/GIS/Data/Transport and mapping/Tube network/TfL/stream.xml").read)
(h/'station').map { |s| [(s/'name')[0].inner_html.gsub('&amp;', '&'), (s/'zones'/'zone').inner_html.to_i, *(s/'coordinates')[0].inner_html.strip.split(',')[0..1].map(&:to_f)] }
*/

)

-- London survey data (
  
create table london_survey_strings (
rid integer,
home_postcode text, home_street text, home_location text, home_status text,
other_postcode text, other_street text, other_location text, other_status text
);

copy london_survey_strings from '/Users/George/Dropbox/Academic/PhD/London LS and EQ/Data analysis/unpacking_variables_02_geodata.csv' csv header;

create table london_survey as (
  select rid as id,
  case 
    when replace(upper(home_postcode), ' ', '') ~ '^[A-Z][A-Z]?[0-9][0-9]?[A-Z]?[0-9][A-Z][A-Z]$'
    then replace(upper(home_postcode), ' ', '')
    else NULL 
  end as home_postcode,
  case 
    when home_location <> '' 
    then cast(split_part(home_location, ',', 1) as double precision)   
    else NULL
  end as home_lat,
  case 
    when home_location <> '' 
    then cast(split_part(home_location, ',', 2) as double precision)
    else NULL 
  end as home_lon,
  case 
    when home_location <> '' 
    then cast(split_part(home_location, ',', 3) as integer)   
    else NULL
  end as home_zoom,
  (home_status = 'confirmed' or home_status = 'approximate') as home_is_valid,
  (home_status = 'approximate') as home_is_approx,
  
  case 
    when replace(upper(other_postcode), ' ', '') ~ '^[A-Z][A-Z]?[0-9][0-9]?[A-Z]?[0-9][A-Z][A-Z]$' 
    then replace(upper(other_postcode), ' ', '')  
    else NULL 
  end as other_postcode,
  case 
    when other_location <> '' 
    then cast(split_part(other_location, ',', 1) as double precision)
    else NULL
  end as other_lat,
  case when other_location <> '' then 
    cast(split_part(other_location, ',', 2) as double precision)
    else NULL 
  end as other_lon,
  case 
    when other_location <> '' then
    cast(split_part(other_location, ',', 3) as integer)
    else NULL
  end as other_zoom,
  (other_status = 'confirmed' or other_status = 'approximate') as other_is_valid,
  (other_status = 'approximate') as other_is_approx 
  
  from london_survey_strings
);

create unique index london_survey_id_idx on london_survey(id);

)

-- UKNEA survey data (

create table uk_survey_postcodes (
  id integer primary key,
  home_postcode text,
  other_postcode text
);

copy uk_survey_postcodes from '/Users/George/Dropbox/Academic/UKNEA/survey_data/adding_geo_data/20100902_postcodes.csv' csv header;

create table uk_survey as (
  select 
  id,
  case 
    when replace(upper(home_postcode), ' ', '') ~ '^[A-Z][A-Z]?[0-9][0-9]?[A-Z]?[0-9][A-Z][A-Z]$'
    then replace(upper(home_postcode), ' ', '')
    else NULL 
  end as home_postcode,
  case 
    when replace(upper(other_postcode), ' ', '') ~ '^[A-Z][A-Z]?[0-9][0-9]?[A-Z]?[0-9][A-Z][A-Z]$'
    then replace(upper(other_postcode), ' ', '')
    else NULL 
  end as other_postcode
  from uk_survey_postcodes
);
create unique index uk_survey_id_idx on uk_survey(id);

)