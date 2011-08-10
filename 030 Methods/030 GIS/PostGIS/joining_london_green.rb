
# ***
# NOTE: home_gigl_green_sd1000 has to be re-run without the st_buffer!
# ***

place, loc_type = 'london', 'map'

# run one as applicable
# *** REMEMBER! ***: create appropriate __current_kernel_pdf function!
dist, unit, slices, truncation_multiple, std_devs = 'normal', 'sd', 8, 3, [200, 1000]  
# *** REMEMBER! ***: create appropriate __current_kernel_pdf function!
# dist, unit, slices, truncation_multiple, std_devs = 'uniform', 'r', 1, 1, [200, 1000, 3000]

# -------------------------

src_tables = {
  'osm_green'  => ['osm_green_spaces', 'osgb36_polygon'],
  'osm_park'   => ['osm_parks',        'osgb36_polygon'],
  'gigl_green' => ['giglopenspace',    'wkb_geometry']
}
loc_prefixes = %w(home other)

table_name = "#{place}_green_#{dist}"

IO.popen('pbcopy', 'r+') do |clipboard| clipboard.puts("
create table #{table_name} as (select id from #{place}_survey);
" +
loc_prefixes.map do |loc_prefix| src_tables.map do |src_name, src_table| std_devs.map do |sd| 
  col_name = "#{loc_prefix}_#{src_name}_#{unit}#{sd}"
"
alter table #{table_name} add column #{col_name} real; 
update #{table_name} s1 set #{col_name} = kernel_weighted_local_proportion(
  ( select st_union(st_buffer(l.#{src_table[1]}, 0)) 
    from #{src_table[0]} l 
    join #{place}_survey s2 
    on st_dwithin(l.#{src_table[1]}, s2.#{loc_prefix}_#{loc_type}_osgb, #{sd} * #{truncation_multiple}) 
    where s1.id = s2.id ),
  ( select #{loc_prefix}_#{loc_type}_osgb from #{place}_survey s2 where s1.id = s2.id ),
  #{sd}, 
  #{sd} * #{truncation_multiple},
  #{slices},
  3
) * 100;
"
end; end; end.flatten.join)
end

# create unique index london_lcm_normal_id_idx on london_lcm_normal (id);

