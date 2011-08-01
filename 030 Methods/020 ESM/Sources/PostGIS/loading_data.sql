create database phd template postgis_template;
  
psql -d phd -U postgres -f /usr/local/pgsql/share/contrib/postgis-1.5/postgis_upgrade_15_minor.sql


-- LAEI (London)

cd "/Users/George/GIS/Data/Air quality/LAEI_2008/Concentration maps"
shp2pgsql -D -I -s 27700 "laei-2008-no2a-20mgrid-shp/LAEI08_NO2a.shp"   laei08_no2a  | psql -d phd -U postgres
shp2pgsql -D -I -s 27700 "laei-2008-pm10a-20mgrid-shp/LAEI08_PM10a.shp" laei08_pm10a | psql -d phd -U postgres
shp2pgsql -D -I -s 27700 "laei-2008-pm10e-20mgrid-shp/LAEI08_PM10e.shp" laei08_pm10e | psql -d phd -U postgres


-- LCM 2000

cd "/Users/George/GIS/Data/Land use/Land Cover Map 2000"
shp2pgsql -D -I -s 27700 "gdal_polygonize_output.shp"    lcm2000gb | psql -d phd -U postgres
shp2pgsql -D -I -s 29903 "gdal_polygonize_output_ni.shp" lcm2000ni | psql -d phd -U postgres

/* no -- makes qgis hang for minutes on end! -- bug 3453
create view lcm2000uk as (
  select gid, dn, the_geom from lcm2000gb
  union
  select gid + 5000000, dn, st_transform(the_geom, 27700) from lcm2000ni
);

create view lcm2000uk_1k as (  -- to check visually
  select gid, dn, the_geom from lcm2000uk where gid % 1000 = 0
);
*/

-- NSPD

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
 lsoa char(9),
 scottish_dzone char(9),
 msoa char(9),
 urban_rural_ew char(1),
 urban_rural_scot char(1),
 urban_rural_ni char(1),
 scottish_izone char(9),
 soa_ni char(8),
 oa_class char(3),
 old_pct char(5)
);
copy nspd2010aug from '/Users/George/GIS/Data/Borders, boundaries, codes/NSPDF_AUG_2010_UK_1M_FP.csv' csv;
alter table nspd2010aug add column postcode_no_sp char(8);
update nspd2010aug set postcode_no_sp = replace(postcode_7, ' ', '');
alter table nspd2010aug add primary key (postcode_no_sp);
select addgeometrycolumn('nspd2010aug', 'the_geom', 27700, 'POINT', 2);
update nspd2010aug set the_geom = st_setsrid(st_makepoint(
  cast(grid_easting as integer),
  cast(grid_northing as integer)
), 27700) where grid_ref_quality != '9';


-- UK outline

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


-- Airport noise (Heathrow)

cd "/Users/George/GIS/Data/Noise/Airport noise/Heathrow 2009"
psql -d phd -U postgres < Standard/lhr09_leq_standard.sql

drop table lhr09_leq_standard_lay;
drop table lhr09_leq_standard_lin;
drop table lhr09_leq_standard_pnt;
drop table lhr09_leq_standard_txt;
alter table lhr09_leq_standard_plg add column db integer;
update lhr09_leq_standard_plg set db = cast(substring(layer from 'x[0-9]x([0-9]+)') as integer);


-- OSM (London, 10 mins)

psql -d phd -U postgres < ~/bin/osmosis/script/pgsimple_schema_0.6.sql
cd "/Users/George/GIS/Data/Transport and mapping/OpenStreetMap/Cloudmade22June2011"
bzip2 -d -c england.osm.bz2 | ~/bin/osmosis/bin/osmosis -verbose \
  --read-xml /dev/stdin \
  --bounding-box top=51.793328497122545 right=0.4888916015625 bottom=51.176760221369186 left=-0.655059814453125 \
  --write-pgsimp host=localhost database=phd user=postgres


-- Defra noise (London)

cd "/Users/George/GIS/Data/Noise/Defra noise data"
shp2pgsql -D -I -s 27700 "London_Rail/london_rail_lden.gdal_polygonize.shp" noise_rail_lden \
  | psql -d phd -U postgres
shp2pgsql -D -I -s 27700 "London_Road/london_roads_lden.gdal_polygonize.shp" noise_road_lden \
  | psql -d phd -U postgres


-- Crime (London)

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


-- Meridian 2 (GB)

cd "/Users/George/GIS/Data/Transport and mapping/Meridian 2 Shape 2/data"
shp2pgsql -D -I -s 27700 "rail_ln_polyline.shp"   m2_railway  | psql -d phd -U postgres
shp2pgsql -D -I -s 27700 "motorway_polyline.shp"  m2_mways    | psql -d phd -U postgres
shp2pgsql -D -I -s 27700 "a_road_polyline.shp"    m2_aroads   | psql -d phd -U postgres
shp2pgsql -D -I -s 27700 "coast_ln_polyline.shp"  m2_coast    | psql -d phd -U postgres
shp2pgsql -D -I -s 27700 "river_polyline.shp"     m2_river    | psql -d phd -U postgres
shp2pgsql -D -I -s 27700 "station_point.shp"      m2_stations | psql -d phd -U postgres


-- Designations (UK)

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


-- GiGL data

cd "/Users/George/GIS/Data/GiGL"
export PATH="/Library/Frameworks/GDAL.framework/Programs/:$PATH"
ogr2ogr -f "PostgreSQL" -a_srs "EPSG:27700" PG:"user=postgres dbname=phd" AOD.TAB -nln aods
ogr2ogr -f "PostgreSQL" -a_srs "EPSG:27700" PG:"user=postgres dbname=phd" GiGL_Openspace_ALGG.TAB -nln giglopenspace


-- House prices

set mem 1g
set more off
cd "/Users/George/GIS/Data/Social/House prices/NATIONWIDE"
append using dmz9504a dmz9505a dmz9506a dmz9507a dmz9508a dmz9509a dmz9510a dmz9511a dmz9512a dmz9601a dmz9602a dmz9603a dmz9604a dmz9605a dmz9606a dmz9607a dmz9608a dmz9609a dmz9610a dmz9611a dmz9612a dmz9701a dmz9702a dmz9703a dmz9704a dmz9705a dmz9706a dmz9707a dmz9708a dmz9709a dmz9710a dmz9711a dmz9712a dmz9801a dmz9802a dmz9803a dmz9804a dmz9805a dmz9806a dmz9807a dmz9808a dmz9809a dmz9810a dmz9811a dmz9812a dmz9901a dmz9902a dmz9903a dmz9904a dmz9905a dmz9906a dmz9907a dmz9908a dmz9909a dmz9910a dmz9911a dmz9912a dmz0001a dmz0002a dmz0003a dmz0004a dmz0005a dmz0006a dmz0007a dmz0008a dmz0009a dmz0010a dmz0011a dmz0012a dmz0101a dmz0102a dmz0103a dmz0104a dmz0105a dmz0106a dmz0107a dmz0108a dmz0109a dmz0110a dmz0111a dmz0112a dmz0201a dmz0202a dmz0203a dmz0204a dmz0205a dmz0206a dmz0207a dmz0208a dmz0209a dmz0210a dmz0211a dmz0212a dmz0301a dmz0302a dmz0303a dmz0304a dmz0305a dmz0306a dmz0307a dmz0308a dmz0309a dmz0310a dmz0311a dmz0312a dmz0401a dmz0402a dmz0403a dmz0404a dmz0405a dmz0406a, generate(month)
save "gm_all.dta"


