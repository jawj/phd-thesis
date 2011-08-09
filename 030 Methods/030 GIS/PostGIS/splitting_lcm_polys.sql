
# general setup

gdpath = "/Library/Frameworks/GDAL.framework/Versions/Current/Programs"
pgpath = "/usr/local/pgsql/bin"
gdt    = "#{gdpath}/gdal_translate"
gdp    = "#{gdpath}/gdal_polygonize.py"
gdi    = "#{gdpath}/gdalinfo"
s2p    = "#{pgpath}/shp2pgsql"
psql   = "#{pgpath}/psql"

outrst = "/tmp/cut.tif"
outshp = "/tmp/cut.shp"
outsql = "/tmp/cut.sql"

db     = "phd"
user   = "postgres"
step   = 10000

Infinity = 1.0 / 0


# UK

inrst  = "/Users/George/GIS/Data/Land use/Land Cover Map 2000/martinez/data/lcm2000gb/w001001.adf"
table  = "lcm2000gb10km"
epsg   = 27700
emin, emax = -Infinity, Infinity
nmin, nmax = -Infinity, Infinity

=begin -- testing
emin, emax = -10000,  200000
nmin, nmax = -10000,   70000
=end


# NI

inrst  = "/Users/George/GIS/Data/Land use/Land Cover Map 2000/martinez/data/nireland/w001001.adf"
table  = "lcm2000ni10km"
epsg   = 29903
emin, emax = -Infinity, Infinity
nmin, nmax = -Infinity, Infinity

=begin -- testing
emin, emax = 250000, 280000
nmin, nmax = 350000, 380000
=end


# create table

IO.popen("#{psql} -d #{db} -U #{user}", 'w') do |p| 
  p.puts %{
    drop table if exists #{table}; 
    create table #{table} (
      gid serial primary key, 
      dn integer, 
      the_geom geometry not null,
      constraint enforce_dims_the_geom    check (st_ndims(the_geom) = 2),
      constraint enforce_geotype_the_geom check (geometrytype(the_geom) = 'MULTIPOLYGON'::text),
      constraint enforce_srid_the_geom    check (st_srid(the_geom) = #{epsg})
    );
  }
end

# shrink bounds to raster bounds (gdal_translate ignores projwin if *any* coord is outside bounds)

info = `#{gdi} "#{inrst}"`
eminrst, nminrst = info.match(/^Lower Left\s*\(\s*([\d.]+),\s*([\d.]+)\s*\)/)[1..2].map(&:to_f)
emaxrst, nmaxrst = info.match(/^Upper Right\s*\(\s*([\d.]+),\s*([\d.]+)\s*\)/)[1..2].map(&:to_f)
emin = [emin, eminrst].max
emax = [emax, emaxrst].min
nmin = [nmin, nminrst].max
nmax = [nmax, nmaxrst].min

# cut and load data

(nmin...nmax).step(step) do |n|
  (emin...emax).step(step) do |e|
    ulx, uly = e, [n + step, nmaxrst].min
    lrx, lry = [e + step, emaxrst].min, n
    puts "\n--- #{((n - nmin).to_f / (nmax - nmin).to_f * 100).round}% complete"
    
    File.unlink(outrst) if File.exist?(outrst)
    cut  = %{#{gdt} -projwin "#{ulx}" "#{uly}" "#{lrx}" "#{lry}" "#{inrst}" "#{outrst}"}
    puts cut, `#{cut}`
    next unless File.exist?(outrst)
    
    File.unlink(outshp) if File.exist?(outshp)
    poly = %{#{gdp} -f "ESRI Shapefile" "#{outrst}" "#{outshp}"}
    puts poly, `#{poly}`
    
    shp = %{#{s2p} -a -s #{epsg} "#{outshp}" #{table} #{db} > #{outsql}}
    puts shp, `#{shp}` 
    
    load = %{#{psql} -d #{db} -U #{user} -f "#{outsql}"}
    puts load, `#{load}`
  end
end


# transforming, merging, indexing, clustering

alter table lcm2000gb10km add column ni boolean default false;
insert into lcm2000gb10km(
  select gid + 5000000, dn, st_transform(the_geom, 27700), true
  from lcm2000ni10km
);
alter table lcm2000gb10km rename to lcm2000uk10km;
create index lcm2000uk10km_geom_idx on lcm2000uk10km using gist(the_geom);
cluster lcm2000uk10km_geom_idx on lcm2000uk10km;
analyze lcm2000uk10km;

