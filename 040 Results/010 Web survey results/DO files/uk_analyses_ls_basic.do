
set more off

#delimit ;
foreach lcmsuffix in r1000 r3000 r10000 {;
  
  #delimit ;
  local lcmsuffix r3000; // for non-looping lcmsuffix use
  foreach lcm in coast water mountain grassland farmland woodland suburban inlandbare {;
  // foreach lcm in coast water greens suburban inlandbare {;
    
    capture drop hc_`lcm';
    gen hc_`lcm' = home_`lcm'_`lcmsuffix';
  };


  //regress
 oprobit 
  life_sat__q 
  // sf36_emo_wb 
  // panas_positive 
  // panas_negative
  
  hc_*
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

  ln_home_natpark_dist
  ln_home_aonb_dist
  ln_home_nnr_dist
  
  ln_home_coast_dist
  ln_home_river_dist
  
  ln_home_mway_dist
  ln_home_station_dist
  
  home_popdens_ppha  // home_lsoa_popdens_ppha
  home_house_price_med9 // home_lsoa_house_price_fe 
  
  // i.home_country  // wipes out all lcm!
  
  // ipaq_total_mhw
  poor_health good_health
  
  // home_own_outright  // correlates 0.44 with age_mp and 0.48 with age_mp_sq
  social_tenant 
  // num_house_problems // don't include these -- should be compensated in rent
  // house_crowding
  
  hh_ind_inc_ln
  // hh_oecd_inc_ln
  
  male__q
  age_mp age_mp_sq
  unemployed
  lives_alone
  religious
  // if household_sixteen_plus__q < 2
  // if ipaq_total_mhw < 300
, vce(robust)
;
outreg2 using "/Users/gjm06/Downloads/regs_uk_07_oprobit.xls", sideway label alpha(0.001, 0.01, 0.05, 0.1) symbol(***, **, *, +) auto(2) adjr2 word;
};
#delimit CR


// after sd1000
local inc_coeff _b[hh_ind_inc_ln]
local water_coeff _b[home_water_`lcmsuffix']
sum(hh_ind_inc)
local mean_inc = r(mean)

disp `water_coeff' * (`mean_inc' / `inc_coeff')


// ES for additional 1% water: £1.4K
disp exp(ln(`mean_inc') + (`water_coeff' / `inc_coeff') * 1) - `mean_inc'




