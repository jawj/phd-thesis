set more off
#delimit ;
 foreach dep in panas_positive panas_negative sf36_emo_wb  {;
 //foreach dep in sf36_emo_wb {;
regress 
  `dep'

  home_coast_r3000
  home_water_r3000
  home_mountain_r3000
  home_grassland_r3000
  home_farmland_r3000
  home_woodland_r3000
  home_suburban_r3000
  home_inlandbare_r3000
  
  ln_home_natpark_dist
  ln_home_aonb_dist
  ln_home_nnr_dist
  
  ln_home_coast_dist
  ln_home_river_dist
  
  ln_home_mway_dist
  ln_home_station_dist
  
  home_popdens_ppha // home_lsoa_popdens_ppha
  home_house_price_med9 // home_lsoa_house_price_fe 
  
  // ipaq_total_mhw
  poor_health good_health
  
  // home_own_outright  // correlates 0.44 with age_mp and 0.48 with age_mp_sq
  social_tenant
  
  hh_ind_inc_ln
  
  male__q
  age_mp age_mp_sq
  unemployed
  lives_alone
  religious
  // if ipaq_total_mhw < 300
, vce(robust)
;
 // outreg2 using "/Users/gjm06/Downloads/regs_uk_mood_07.xls", sideway label alpha(0.001, 0.01, 0.05, 0.1) symbol(***, **, *, +) auto(2) adjr2 word;
};


sum(hh_ind_inc)  // mean: 19204.41
local mean_inc = r(mean)

nlcom _b[home_farmland_r3000] * (`mean_inc' / _b[hh_ind_inc_ln])
nlcom _b[home_farmland_r3000] * (`mean_inc' / 4.883644)

 // larger income coefficient from: regress sf36_emo_wb hh_ind_inc_ln, vce(robust)
