
set more off
#delimit ;

foreach lcm in gigl_green greens {;
  foreach lcmsuffix in r1000 r3000 {;
    foreach dep in life_sat__q esswb_satisfying_life esswb_personal esswb_personal_and_social {;
      capture drop hc_green;
      gen hc_green = home_`lcm'_`lcmsuffix';

regress 
  `dep' 

  home_map_pm10a

  hc_green

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
  
  home_own_outright  // correlates 0.44 with age_mp and 0.48 with age_mp_sq
  social_tenant 

  hh_ind_inc_ln

  male__q
  age_mp  age_mp_sq
  degree
  unemployed 
  really_single divsep
  religious

, cluster(home_lsoa_or_dzone);
outreg2 using "/Users/gjm06/Downloads/regs_london_aggs_04.xls", sideway label alpha(0.001, 0.01, 0.05, 0.1) symbol(***, **, *, +) auto(2) adjr2 word;
};
};
};

