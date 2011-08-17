
set more off
#delimit ;

/**
foreach lcmsuffix in r200 r1000 r3000 r10000 {;
foreach lcm in coast water mountain grassland farmland woodland suburban inlandbare {;
 //foreach lcm in coast water greens suburban inlandbare {;
  capture drop hc_`lcm';
  gen hc_`lcm' = home_`lcm'_`lcmsuffix';
};
**/

 //foreach lcm in osm_green osm_park gigl_green greens {;
foreach lcm in greens {;
  foreach lcmsuffix in r200 r1000 r3000 {;

  #delimit ;
  local lcm greens;      // for non-looping use
  local lcmsuffix r3000; // ditto
  
  capture drop hc_green;
  capture drop hc_blue;
  gen hc_green = home_`lcm'_`lcmsuffix';
  gen hc_blue  = home_water_`lcmsuffix';

regress 
  life_sat__q 

  home_map_pm10a
/**
  hc_coast
  hc_water
  hc_mountain
  hc_grassland
  hc_farmland
  hc_woodland
  hc_suburban
  hc_inlandbare
**/
  
  // home_osm_green_`lcmsuffix' 
  // home_osm_park_`lcmsuffix'
  // home_gigl_green_`lcmsuffix'
  
  // hc_green
  home_aod_01
  
  hc_blue

  home_lhr09_quiet  // home_lhr09_leq
  home_road_quiet   // home_noise_road_lden 
  home_rail_quiet   // home_noise_rail_lden 
  // home_all_quiet

  ln_home_z1_dist
  ln_home_tube_or_station_dist 
  
  home_rb_per_khh 
  home_vap_per_kp 
  
  // home_popdens_ppha // home_lsoa_popdens_ppha
  home_house_price_med9 // home_lsoa_house_price_fe
  
  poor_health good_health  // self_reported_health__q
  
  // home_own_outright  // correlates 0.44 with age_mp and 0.48 with age_mp_sq
  social_tenant 
  // num_house_problems
  // house_crowding

  hh_ind_inc_ln

  male__q
  age_mp  age_mp_sq
  degree
  unemployed 
  really_single divsep
  religious

, cluster(home_lsoa_or_dzone);

outreg2 using "/Users/gjm06/Downloads/regs_london_green_05.xls", sideway label alpha(0.001, 0.01, 0.05, 0.1) symbol(***, **, *, +) auto(2) adjr2 word;
};
};


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




