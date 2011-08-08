
-- get extent right
drop table ukbox;
create table ukbox as (
  select 1 as id, st_setsrid(st_makebox2d(
    st_makepoint(0, 0), -- -10000 is a better easting, but complicates things
    st_makepoint(700000, 1250000)
  ), 27700) as cell
);

-- out of c. 2m polygons
select count(1) from lcm2000uk where st_area(st_box2d(the_geom)) > 10^9;  --     43
select count(1) from lcm2000uk where st_area(st_box2d(the_geom)) > 10^8;  --    455
select count(1) from lcm2000uk where st_area(st_box2d(the_geom)) > 10^7;  --   6291
select count(1) from lcm2000uk where st_area(st_box2d(the_geom)) > 10^6;  --  74269
select count(1) from lcm2000uk where st_area(st_box2d(the_geom)) > 10^5;  -- 580908


create table lcm2000uk_s as (
  select * from lcm2000uk where st_area(st_box2d(the_geom)) < 10^9;
  
)