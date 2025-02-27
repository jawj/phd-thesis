create database phd template postgis_template;
psql -d phd -U postgres -f /usr/local/pgsql/share/contrib/postgis-1.5/postgis_upgrade_15_minor.sql

-- LAEI 2008 (London) (

cd "/Users/George/GIS/Data/Air quality/LAEI_2008/Concentration maps"
shp2pgsql -D -I -s 27700 "laei-2008-no2a-20mgrid-shp/LAEI08_NO2a.shp"   laei08_no2a  | psql -d phd -U postgres
shp2pgsql -D -I -s 27700 "laei-2008-pm10a-20mgrid-shp/LAEI08_PM10a.shp" laei08_pm10a | psql -d phd -U postgres
shp2pgsql -D -I -s 27700 "laei-2008-pm10e-20mgrid-shp/LAEI08_PM10e.shp" laei08_pm10e | psql -d phd -U postgres

)

-- LCM 2000 -- superseded -- see joining_lcm.rb (

cd "/Users/George/GIS/Data/Land use/Land Cover Map 2000"
shp2pgsql -D -I -s 27700 "gdal_polygonize_output.shp"    lcm2000gb | psql -d phd -U postgres
shp2pgsql -D -I -s 29903 "gdal_polygonize_output_ni.shp" lcm2000ni | psql -d phd -U postgres

alter table lcm2000gb add column ni boolean default false;
insert into lcm2000gb(
  select
    gid + 5000000, 
    dn,
    st_transform(the_geom, 27700),
    true
  from lcm2000ni
);
alter table lcm2000gb rename to lcm2000uk;

vacuum analyze lcm2000uk;

alter table lcm2000uk alter column the_geom set not null;
cluster lcm2000gb_the_geom_gist on lcm2000uk;
analyze lcm2000uk;

create table lcm2000uk_sample as (
  select * from lcm2000uk where gid % 1000 = 0
);

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
create index nspd_pc8_idx on nspd2010aug (postcode_8);
analyze nspd2010aug;

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
  
create table experian2010 (
area_type text,
lsoa text,
hh_count integer,
median_hh_income double precision,
mosaic2003_grp_1 integer,
mosaic2003_grp_2 integer,
mosaic2003_grp_3 integer,
mosaic2003_grp_4 integer,
mosaic2003_grp_5 integer,
mosaic2003_grp_6 integer,
mosaic2003_grp_7 integer,
mosaic2003_grp_8 integer,
mosaic2003_grp_9 integer,
mosaic2003_grp_10 integer,
mosaic2003_grp_11 integer,
mosaic2003_type_1 integer,
mosaic2003_type_2 integer,
mosaic2003_type_3 integer,
mosaic2003_type_4 integer,
mosaic2003_type_5 integer,
mosaic2003_type_6 integer,
mosaic2003_type_7 integer,
mosaic2003_type_8 integer,
mosaic2003_type_9 integer,
mosaic2003_type_10 integer,
mosaic2003_type_11 integer,
mosaic2003_type_12 integer,
mosaic2003_type_13 integer,
mosaic2003_type_14 integer,
mosaic2003_type_15 integer,
mosaic2003_type_16 integer,
mosaic2003_type_17 integer,
mosaic2003_type_18 integer,
mosaic2003_type_19 integer,
mosaic2003_type_20 integer,
mosaic2003_type_21 integer,
mosaic2003_type_22 integer,
mosaic2003_type_23 integer,
mosaic2003_type_24 integer,
mosaic2003_type_25 integer,
mosaic2003_type_26 integer,
mosaic2003_type_27 integer,
mosaic2003_type_28 integer,
mosaic2003_type_29 integer,
mosaic2003_type_30 integer,
mosaic2003_type_31 integer,
mosaic2003_type_32 integer,
mosaic2003_type_33 integer,
mosaic2003_type_34 integer,
mosaic2003_type_35 integer,
mosaic2003_type_36 integer,
mosaic2003_type_37 integer,
mosaic2003_type_38 integer,
mosaic2003_type_39 integer,
mosaic2003_type_40 integer,
mosaic2003_type_41 integer,
mosaic2003_type_42 integer,
mosaic2003_type_43 integer,
mosaic2003_type_44 integer,
mosaic2003_type_45 integer,
mosaic2003_type_46 integer,
mosaic2003_type_47 integer,
mosaic2003_type_48 integer,
mosaic2003_type_49 integer,
mosaic2003_type_50 integer,
mosaic2003_type_51 integer,
mosaic2003_type_52 integer,
mosaic2003_type_53 integer,
mosaic2003_type_54 integer,
mosaic2003_type_55 integer,
mosaic2003_type_56 integer,
mosaic2003_type_57 integer,
mosaic2003_type_58 integer,
mosaic2003_type_59 integer,
mosaic2003_type_60 integer,
mosaic2003_type_61 integer,
mosaic2009_grp_1 integer,
mosaic2009_grp_2 integer,
mosaic2009_grp_3 integer,
mosaic2009_grp_4 integer,
mosaic2009_grp_5 integer,
mosaic2009_grp_6 integer,
mosaic2009_grp_7 integer,
mosaic2009_grp_8 integer,
mosaic2009_grp_9 integer,
mosaic2009_grp_10 integer,
mosaic2009_grp_11 integer,
mosaic2009_grp_12 integer,
mosaic2009_grp_13 integer,
mosaic2009_grp_14 integer,
mosaic2009_grp_15 integer,
mosaic2009_type_1 integer,
mosaic2009_type_2 integer,
mosaic2009_type_3 integer,
mosaic2009_type_4 integer,
mosaic2009_type_5 integer,
mosaic2009_type_6 integer,
mosaic2009_type_7 integer,
mosaic2009_type_8 integer,
mosaic2009_type_9 integer,
mosaic2009_type_10 integer,
mosaic2009_type_11 integer,
mosaic2009_type_12 integer,
mosaic2009_type_13 integer,
mosaic2009_type_14 integer,
mosaic2009_type_15 integer,
mosaic2009_type_16 integer,
mosaic2009_type_17 integer,
mosaic2009_type_18 integer,
mosaic2009_type_19 integer,
mosaic2009_type_20 integer,
mosaic2009_type_21 integer,
mosaic2009_type_22 integer,
mosaic2009_type_23 integer,
mosaic2009_type_24 integer,
mosaic2009_type_25 integer,
mosaic2009_type_26 integer,
mosaic2009_type_27 integer,
mosaic2009_type_28 integer,
mosaic2009_type_29 integer,
mosaic2009_type_30 integer,
mosaic2009_type_31 integer,
mosaic2009_type_32 integer,
mosaic2009_type_33 integer,
mosaic2009_type_34 integer,
mosaic2009_type_35 integer,
mosaic2009_type_36 integer,
mosaic2009_type_37 integer,
mosaic2009_type_38 integer,
mosaic2009_type_39 integer,
mosaic2009_type_40 integer,
mosaic2009_type_41 integer,
mosaic2009_type_42 integer,
mosaic2009_type_43 integer,
mosaic2009_type_44 integer,
mosaic2009_type_45 integer,
mosaic2009_type_46 integer,
mosaic2009_type_47 integer,
mosaic2009_type_48 integer,
mosaic2009_type_49 integer,
mosaic2009_type_50 integer,
mosaic2009_type_51 integer,
mosaic2009_type_52 integer,
mosaic2009_type_53 integer,
mosaic2009_type_54 integer,
mosaic2009_type_55 integer,
mosaic2009_type_56 integer,
mosaic2009_type_57 integer,
mosaic2009_type_58 integer,
mosaic2009_type_59 integer,
mosaic2009_type_60 integer,
mosaic2009_type_61 integer,
mosaic2009_type_62 integer,
mosaic2009_type_63 integer,
mosaic2009_type_64 integer,
mosaic2009_type_65 integer,
mosaic2009_type_66 integer,
mosaic2009_type_67 integer,
mosaic2009_type_68 integer,
mosaic2009_type_69 integer,
females_0004_in_2010 integer,
females_0004_in_2015 integer,
females_0004_in_2020 integer,
females_0509_in_2010 integer,
females_0509_in_2015 integer,
females_0509_in_2020 integer,
females_1014_in_2010 integer,
females_1014_in_2015 integer,
females_1014_in_2020 integer,
females_1519_in_2010 integer,
females_1519_in_2015 integer,
females_1519_in_2020 integer,
females_2024_in_2010 integer,
females_2024_in_2015 integer,
females_2024_in_2020 integer,
females_2529_in_2010 integer,
females_2529_in_2015 integer,
females_2529_in_2020 integer,
females_3034_in_2010 integer,
females_3034_in_2015 integer,
females_3034_in_2020 integer,
females_3539_in_2010 integer,
females_3539_in_2015 integer,
females_3539_in_2020 integer,
females_4044_in_2010 integer,
females_4044_in_2015 integer,
females_4044_in_2020 integer,
females_4549_in_2010 integer,
females_4549_in_2015 integer,
females_4549_in_2020 integer,
females_5054_in_2010 integer,
females_5054_in_2015 integer,
females_5054_in_2020 integer,
females_5559_in_2010 integer,
females_5559_in_2015 integer,
females_5559_in_2020 integer,
females_6064_in_2010 integer,
females_6064_in_2015 integer,
females_6064_in_2020 integer,
females_6569_in_2010 integer,
females_6569_in_2015 integer,
females_6569_in_2020 integer,
females_7074_in_2010 integer,
females_7074_in_2015 integer,
females_7074_in_2020 integer,
females_7579_in_2010 integer,
females_7579_in_2015 integer,
females_7579_in_2020 integer,
females_8084_in_2010 integer,
females_8084_in_2015 integer,
females_8084_in_2020 integer,
females_85_in_2010 integer,
females_85_in_2015 integer,
females_85_in_2020 integer,
males_0004_in_2010 integer,
males_0004_in_2015 integer,
males_0004_in_2020 integer,
males_0509_in_2010 integer,
males_0509_in_2015 integer,
males_0509_in_2020 integer,
males_1014_in_2010 integer,
males_1014_in_2015 integer,
males_1014_in_2020 integer,
males_1519_in_2010 integer,
males_1519_in_2015 integer,
males_1519_in_2020 integer,
males_2024_in_2010 integer,
males_2024_in_2015 integer,
males_2024_in_2020 integer,
males_2529_in_2010 integer,
males_2529_in_2015 integer,
males_2529_in_2020 integer,
males_3034_in_2010 integer,
males_3034_in_2015 integer,
males_3034_in_2020 integer,
males_3539_in_2010 integer,
males_3539_in_2015 integer,
males_3539_in_2020 integer,
males_4044_in_2010 integer,
males_4044_in_2015 integer,
males_4044_in_2020 integer,
males_4549_in_2010 integer,
males_4549_in_2015 integer,
males_4549_in_2020 integer,
males_5054_in_2010 integer,
males_5054_in_2015 integer,
males_5054_in_2020 integer,
males_5559_in_2010 integer,
males_5559_in_2015 integer,
males_5559_in_2020 integer,
males_6064_in_2010 integer,
males_6064_in_2015 integer,
males_6064_in_2020 integer,
males_6569_in_2010 integer,
males_6569_in_2015 integer,
males_6569_in_2020 integer,
males_7074_in_2010 integer,
males_7074_in_2015 integer,
males_7074_in_2020 integer,
males_7579_in_2010 integer,
males_7579_in_2015 integer,
males_7579_in_2020 integer,
males_8084_in_2010 integer,
males_8084_in_2015 integer,
males_8084_in_2020 integer,
males_85_in_2010 integer,
males_85_in_2015 integer,
males_85_in_2020 integer
);

copy experian2010 from '/Users/George/GIS/Data/Social/Experian Super Output Area data/2010/experian_2010_LSOA.csv' csv header;  -- must remove extra header line first!
create unique index exp10_lsoa_index on experian2010 (lsoa);
analyze experian2010;

create table experian2010pops as (
  select lsoa,
  females_0004_in_2010 + females_0509_in_2010 + females_1014_in_2010 + females_1519_in_2010 + females_2024_in_2010 + females_2529_in_2010 + females_3034_in_2010 + females_3539_in_2010 + females_4044_in_2010 + females_4549_in_2010 + females_5054_in_2010 + females_5559_in_2010 + females_6064_in_2010 + females_6569_in_2010 + females_7074_in_2010 + females_7579_in_2010 + females_8084_in_2010 + females_85_in_2010 + males_0004_in_2010 + males_0509_in_2010 + males_1014_in_2010 + males_1519_in_2010 + males_2024_in_2010 + males_2529_in_2010 + males_3034_in_2010 + males_3539_in_2010 + males_4044_in_2010 + males_4549_in_2010 + males_5054_in_2010 + males_5559_in_2010 + males_6064_in_2010 + males_6569_in_2010 + males_7074_in_2010 + males_7579_in_2010 + males_8084_in_2010 + males_85_in_2010 as pop 
  from experian2010
);

create unique index exp10pops_lsoa_index on experian2010pops (lsoa);
analyze experian2010pops;

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

-- LSOA/dzone house price FEs (

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

create index lsoa_polys_code_idx on lsoa_polys (lsoa04cd);

cd "/Users/George/GIS/Data/Borders, boundaries, codes/SNS_Geography_24_2_2011"
shp2pgsql -D -I -s 27700 datazones_2001.shp dzone_polys | psql -d phd -U postgres

create index dzone_polys_code_idx on dzone_polys (zonecode);

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

-- House price residuals (all sales with postcode) (

create table house_price_residuals (
  postcode text,
  residual real
);

copy house_price_residuals from '/Users/George/GIS/Data/Social/House prices/NATIONWIDE/house_price_residuals.csv' csv header;

create index hpresid_pc_idx on house_price_residuals (postcode);
analyze hpresid_pc_idx;

select addgeometrycolumn('house_price_residuals', 'the_geom', 27700, 'POINT', 2);
update house_price_residuals r set the_geom = n.the_geom from nspd2010aug n where r.postcode = n.postcode_8;

)

-- Population density (

cd "/Users/George/GIS/Data/uk_pop/uk_pop_100m"
/Library/Frameworks/GDAL.framework/Versions/Current/Programs/gdal_polygonize.py -f "ESRI Shapefile" "w001001.adf" "gdpout_ukpop100m.shp"
shp2pgsql -D -I -s 27700 "gdpout_ukpop100m.shp" ukpop100m | psql -d phd -U postgres

cd "/Users/George/GIS/Data/uk_pop/popagsum2"
/Library/Frameworks/GDAL.framework/Versions/Current/Programs/gdal_polygonize.py -f "ESRI Shapefile" "w001001.adf" "gdpout_ukpop1km.shp"
shp2pgsql -D -I -s 27700 "gdpout_ukpop1km.shp" ukpop1km | psql -d phd -U postgres

)

-- Weather (

-- see also ukcp09_commands.sh, generated by ukcp09_generate_commands.rb

cd "/Users/George/GIS/Data/Weather/UKCP09/"

/Library/Frameworks/GDAL.framework/Versions/Current/Programs/gdal_polygonize.py -f "ESRI Shapefile" "Rainfall_MeanK.gtiff" "Rainfall_MeanK.shp"
shp2pgsql -D -I -s 27700 "Rainfall_MeanK.shp" ukcp_rainfall_meank | psql -d phd -U postgres
  
/Library/Frameworks/GDAL.framework/Versions/Current/Programs/gdal_polygonize.py -f "ESRI Shapefile" "Sunshine_MeanK.gtiff" "Sunshine_MeanK.shp"
shp2pgsql -D -I -s 27700 "Sunshine_MeanK.shp" ukcp_sunshine_meank | psql -d phd -U postgres

/Library/Frameworks/GDAL.framework/Versions/Current/Programs/gdal_polygonize.py -f "ESRI Shapefile" "SnowLying_MeanK.gtiff" "SnowLying_MeanK.shp"
shp2pgsql -D -I -s 27700 "SnowLying_MeanK.shp" ukcp_snowlying_meank | psql -d phd -U postgres

/Library/Frameworks/GDAL.framework/Versions/Current/Programs/gdal_polygonize.py -f "ESRI Shapefile" "MeanTemp_MeanK.gtiff" "MeanTemp_MeanK.shp"
shp2pgsql -D -I -s 27700 "MeanTemp_MeanK.shp" ukcp_meantemp_meank | psql -d phd -U postgres

/Library/Frameworks/GDAL.framework/Versions/Current/Programs/gdal_polygonize.py -f "ESRI Shapefile" "MeanWindSpeed_MeanK.gtiff" "MeanWindSpeed_MeanK.shp"
shp2pgsql -D -I -s 27700 "MeanWindSpeed_MeanK.shp" ukcp_meanwindspeed_meank | psql -d phd -U postgres
  
/Library/Frameworks/GDAL.framework/Versions/Current/Programs/gdal_polygonize.py -f "ESRI Shapefile" "RelativeHumidity_MeanK.gtiff" "RelativeHumidity_MeanK.shp"
shp2pgsql -D -I -s 27700 "RelativeHumidity_MeanK.shp" ukcp_relhumidity_meank | psql -d phd -U postgres

)
