
#delimit ;
local lcmsuffix r3000;
regress 
  life_sat__q 

  home_map_pm10a

  home_coast_`lcmsuffix'
  home_water_`lcmsuffix'
  home_mountain_`lcmsuffix'
  home_grassland_`lcmsuffix'
  home_farmland_`lcmsuffix'
  home_woodland_`lcmsuffix'
  home_suburban_`lcmsuffix'
  home_inlandbare_`lcmsuffix'

  // home_osm_green_`lcmsuffix' 
  // home_osm_park_`lcmsuffix'
  // home_gigl_green_`lcmsuffix'
  // home_aod_01

  home_lhr09_leq

  home_noise_road_lden 
  home_noise_rail_lden 

  ln_home_z1_dist 
  // ln_home_tube_or_station_dist 
  
  home_rb_per_khh 
  home_vap_per_kp 

  home_lsoa_house_price_fe
  
  home_own_outright  // correlates 0.44 with age_mp and 0.48 with age_mp_sq
  num_house_problems
  house_crowding

  hh_ind_inc_ln

  male__q
	age_mp 	age_mp_sq
	degree
	unemployed 
	really_single divsep
	religious
	// poor_health

, cluster(home_lsoa_or_dzone);
#delimit CR


// after sd1000
local inc_coeff _b[hh_ind_inc_ln]
local mntns_coeff _b[home_mountain_`lcmsuffix']
local bare_coeff _b[home_inlandbare_`lcmsuffix']
sum(hh_ind_inc)
local mean_inc = r(mean)

disp `mntns_coeff' * (`mean_inc' / `inc_coeff')
disp `bare_coeff' * (`mean_inc' / `inc_coeff')


// ES for additional 1% mountains: £41K!
disp exp(ln(`mean_inc') + (`mntns_coeff' / `inc_coeff') * 1) - `mean_inc'




