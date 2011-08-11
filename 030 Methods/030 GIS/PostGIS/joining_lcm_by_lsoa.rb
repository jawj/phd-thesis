# run one as applicable
place = 'london'
# place = 'uk'

types = {
  coast:      '221, 201, 211, 212, 181, 191',
  water:      '131, 111',
  mountain:   '121, 101, 102, 151, 91',
  grassland:  '61, 71, 81',
  farmland:   '41, 42, 43, 51, 52',
  woodland:   '21, 11',
  suburban:   '171',
  inlandbare: '161',
#  urban:      '172'
}
loc_prefixes    = %w(home other)

table_name = "#{place}_lcm_by_lsoa"

IO.popen('pbcopy', 'r+') do |clipboard| clipboard.puts("
create table #{table_name} as (select id from #{place}_survey);
" +
loc_prefixes.map do |loc_prefix| types.map do |type_name, type_dns|
  col_name = "#{loc_prefix}_#{type_name}_lsoaprop"
"
alter table #{table_name} add column #{col_name} real; 
update #{table_name} u set #{col_name} = 
  st_area(st_intersection(
    s.#{loc_prefix}_lsoa_dzone_poly,
    (select st_union(l.the_geom) from lcm2000uk10km l 
     where dn in (#{type_dns}) 
     and st_intersects(s.#{loc_prefix}_lsoa_dzone_poly, l.the_geom))
  )) / s.#{loc_prefix}_lsoa_area
  from #{place}_survey s where s.id = u.id;
"
end; end.flatten.join)
end

# create unique index london_lcm_normal_id_idx on london_lcm_normal (id);
