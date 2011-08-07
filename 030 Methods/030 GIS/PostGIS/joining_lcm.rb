
# run one as applicable
place, loc_type = 'london', 'map'
#place, loc_type = 'uk', 'postcode'

# run one as applicable
# remember: create appropriate __current_kernel_pdf function!
dist, slices, truncation_multiple, std_devs = 'normal',  6, 3, [200, 1000]  
#dist, slices, truncation_multiple, std_devs = 'uniform', 1, 1, [200, 1000, 3000]

# -------------------------

types = {
  coast:      '221, 201, 211, 212, 181, 191',
  water:      '131, 111',
  mountain:   '121, 101, 102, 151, 91',
  grassland:  '61, 71, 81',
  farmland:   '41, 42, 43, 51, 52',
  woodland:   '21, 11',
  suburban:   '171',
  inlandbare: '161',
# urban:      '172'
}
loc_prefixes    = %w(home other)

table_name = "#{place}_lcm_#{dist}"

IO.popen('pbcopy', 'r+') do |clipboard| clipboard.puts("
create table #{table_name} as (select id from #{place}_survey);
" +
loc_prefixes.map do |loc_prefix| types.map do |type_name, type_dns| std_devs.map do |sd| 
  col_name = "#{loc_prefix}_#{type_name}_sd#{sd}"
"
alter table #{table_name} add column #{col_name} real; 
update #{table_name} s1 set #{col_name} = kernel_weighted_local_proportion(
  ( select st_union(l.the_geom) 
    from lcm2000uk l 
    join #{place}_survey s2 
    on st_dwithin(l.the_geom, s2.#{loc_prefix}_#{loc_type}_osgb, #{sd} * #{truncation_multiple}) 
    where s1.id = s2.id
    and dn in (#{type_dns}) ),
  ( select #{loc_prefix}_#{loc_type}_osgb from #{place}_survey s2 where s1.id = s2.id ),
  #{sd}, 
  #{sd} * #{truncation_multiple},
  #{slices},
  3
) * 100;
"
end; end; end.flatten.join)
end

# $1 = area geometry
# $2 = kernel centre point geometry
# $3 = kernel std dev
# $4 = truncation bandwidth (for normal kernel only -- for others, repeat $3)
# $5 = number of slices for approximation
# $6 = buffer precision (points per 1/4 circle)

