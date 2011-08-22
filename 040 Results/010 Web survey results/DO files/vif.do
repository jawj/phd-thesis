#delimit ;
local rhs
  home_greens_r3000
  ln_home_natpark_dist
  ln_home_aonb_dist
  ln_home_nnr_dist
  ln_home_coast_dist
  ln_home_river_dist
  ln_home_mway_dist
  ln_home_station_dist
  home_popdens_ppha
  home_house_price_med9
  ipaq_total_mhw
  poor_health good_health
  social_tenant
  hh_ind_inc_ln
  male__q
  age_mp age_mp_sq
  unemployed
  lives_alone
  religious;
  
preserve;
keep `rhs';

foreach rh in rhs {;
  regress rh home_greens_r3000-rh rh-
  
}