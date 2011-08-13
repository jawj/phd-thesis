

#delimit ;
local lcmsuffix sd1000;
regress 
  // life_sat__q 
  sf36_emo_wb 
  // panas_positive 
  // panas_negative


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
  
  home_lsoa_popdens // ln_home_lsoa_popdens
  home_house_price_med9
  
  ipaq_total_mmw
  self_rated_health 
  
  home_own_outright  // correlates 0.44 with age_mp and 0.48 with age_mp_sq
  social_tenant 
  num_house_problems
  house_crowding
  
  hh_ind_inc_ln
  
  male__q
  age_mp age_mp_sq
  unemployed
  lives_alone
  religious

, cluster(home_lsoa_or_dzone);
#delimit CR


// after sd1000
local inc_coeff _b[hh_ind_inc_ln]
local water_coeff _b[home_water_`lcmsuffix']
sum(hh_ind_inc)
local mean_inc = r(mean)

disp `water_coeff' * (`mean_inc' / `inc_coeff')


// ES for additional 1% water: £1.4K
disp exp(ln(`mean_inc') + (`water_coeff' / `inc_coeff') * 1) - `mean_inc'




