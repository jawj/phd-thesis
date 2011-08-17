set more off
#delimit ;
foreach lcmsuffix in r1000 r3000 {;
regress 
  life_sat__q
  
  other_coast_`lcmsuffix'
  other_water_`lcmsuffix'
  other_mountain_`lcmsuffix'
  other_grassland_`lcmsuffix'
  other_farmland_`lcmsuffix'
  other_woodland_`lcmsuffix'
  other_suburban_`lcmsuffix'
  other_inlandbare_`lcmsuffix'
  
  commutetimemp 
  
  home_coast_`lcmsuffix'
  home_water_`lcmsuffix'
  home_mountain_`lcmsuffix'
  home_grassland_`lcmsuffix'
  home_farmland_`lcmsuffix'
  home_woodland_`lcmsuffix'
  home_suburban_`lcmsuffix'
  home_inlandbare_`lcmsuffix'
  
  ln_home_natpark_dist
  ln_home_aonb_dist
  ln_home_nnr_dist
  
  ln_home_mway_dist
  ln_home_station_dist
  ln_home_coast_dist
  
  home_popdens_ppha // home_lsoa_popdens_ppha
  home_house_price_med9 // home_lsoa_house_price_fe 
  
  ipaq_total_mhw
  poor_health good_health
  
  // home_own_outright  // correlates 0.44 with age_mp and 0.48 with age_mp_sq
  social_tenant
  
  hh_ind_inc_ln
  
  male__q
  age_mp age_mp_sq
  unemployed
  lives_alone
  religious
, vce(robust)
;
outreg2 using "/Users/gjm06/Downloads/regs_uk_work_02.xls", sideway label alpha(0.001, 0.01, 0.05, 0.1) symbol(***, **, *, +) auto(2) adjr2 word;
};