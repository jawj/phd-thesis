
set more off
#delimit ;
foreach lcmsuffix in r3000 {;  // r1000 r3000 {;
regress 
  life_sat__q 
  
  other_map_pm10a

  other_greens_`lcmsuffix'
  other_water_`lcmsuffix'

  other_lhr09_quiet  // other_lhr09_leq
  other_road_quiet   // other_noise_road_lden 
  other_rail_quiet   // other_noise_rail_lden 

  commutetimemp
  long_hours_normal

  home_map_pm10a

  home_greens_`lcmsuffix'
  home_water_`lcmsuffix'

  home_lhr09_quiet  // home_lhr09_leq
  home_road_quiet   // home_noise_road_lden 
  home_rail_quiet   // home_noise_rail_lden 

  ln_home_z1_dist
  ln_home_tube_or_station_dist 
  
  home_rb_per_khh 
  home_vap_per_kp 
  
  // home_popdens_ppha // home_lsoa_popdens
  home_house_price_med9 // home_lsoa_house_price_fe
  
  poor_health good_health  // self_reported_health__q
  
  // home_own_outright  // correlates 0.44 with age_mp and 0.48 with age_mp_sq
  social_tenant 

  hh_ind_inc_ln

  male__q
  age_mp  age_mp_sq
  degree
  unemployed 
  really_single divsep
  religious

, cluster(home_lsoa_or_dzone);
 //outreg2 using "/Users/gjm06/Downloads/regs_london_work_02.xls", sideway label alpha(0.001, 0.01, 0.05, 0.1) symbol(***, **, *, +) auto(2) adjr2 word;
};
