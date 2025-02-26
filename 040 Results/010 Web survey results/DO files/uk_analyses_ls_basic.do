
set more off

#delimit ;
foreach lcmsuffix in r1000 r3000 r10000 {;
  
  #delimit ;
  // local lcmsuffix r3000; // for non-looping lcmsuffix use
  foreach lcm in coast water mountain grassland farmland woodland suburban inlandbare {;
  // foreach lcm in coast water greens suburban inlandbare {;
    
    capture drop hc_`lcm';
    gen hc_`lcm' = home_`lcm'_`lcmsuffix';
  };


regress
 // oprobit 
  life_sat__q 
  // sf36_emo_wb 
  // panas_positive 
  // panas_negative
  
    
  // *** NEW for corrections
  home_w_meantemp 
  home_w_sunshine 
  home_w_rainfall 
  home_w_meanwindspeed 
  home_w_snowlying
  home_lat
  home_lon
  i.home_country
  home_own_outright  // (correlates 0.44 with age_mp and 0.48 with age_mp_sq)
  ln_home_railway_dist
  // home_lsoa_popdens_ppha
  // home_lsoa_house_price_fe
  // *** END
  
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
  
  social_tenant 
  // num_house_problems // don't include these -- should be compensated in rent
  // house_crowding
  
  hh_ind_inc_ln       // -- reportedly used in PhD, and used in corrections where applicable
  // hh_oecd_inc_ln   // -- actually used in PhD
  
  male__q
  age_mp age_mp_sq
  unemployed
  lives_alone
  religious
  
  // if hh_size_unweighted == 1
  // if ipaq_total_mhw < 300
  // if work_status__q != "self_emp"
, vce(robust) // beta
;
outreg2 using "/Users/George/Downloads/regs_uk_13.xls", sideway label alpha(0.001, 0.01, 0.05, 0.1) symbol(***, **, *, +) auto(2) adjr2 word;

 // outreg2 using "/Users/George/Downloads/regs_uk_old_beta_12.xls", sideway label auto(2) stats(coef beta) asterisk(beta) noparen alpha(0.001, 0.01, 0.05, 0.1) symbol(***, **, *, +) adjr2;
};
#delimit CR



// after r3000

sum(hh_ind_inc)  // mean: 19204.41
local mean_inc = r(mean)

nlcom _b[hc_water] * (`mean_inc' / _b[hh_ind_inc_ln])
nlcom _b[hc_grassland] * (`mean_inc' / _b[hh_ind_inc_ln])
nlcom _b[hc_woodland] * (`mean_inc' / _b[hh_ind_inc_ln])

nlcom _b[hc_water] * (`mean_inc' / .5285416)
nlcom _b[hc_grassland] * (`mean_inc' / .5285416)
nlcom _b[hc_woodland] * (`mean_inc' / .5285416)


 // larger income coefficient from: regress life_sat__q hh_ind_inc_ln , vce(robust)


 // CS for additional water: (at 60% it's equal to the mean income!)
sum(hh_ind_inc)  // mean: 19204.41
disp r(mean) - exp(ln(r(mean)) + (_b[hc_water] / _b[hh_ind_inc_ln]) * -60)



 // regression for Dolan + Fujiwara + Metcalfe (no health) valuation

#delimit ;
local lcmsuffix r3000; // for non-looping lcmsuffix use
foreach lcm in coast water mountain grassland farmland woodland suburban inlandbare {;
 capture drop hc_`lcm';
 gen hc_`lcm' = home_`lcm'_`lcmsuffix';
};

regress
    // oprobit 
    // life_sat__q 
    sf36_emo_wb 
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

    // if hh_size_unweighted == 1
    // if ipaq_total_mhw < 300
    // if work_status__q != "self_emp"
    , vce(robust)
    ;

sum(hh_ind_inc)  // mean: 19204.41
local mean_inc = r(mean)

nlcom _b[hc_water] * (`mean_inc' / _b[hh_ind_inc_ln])
nlcom _b[hc_grassland] * (`mean_inc' / _b[hh_ind_inc_ln])
nlcom _b[hc_woodland] * (`mean_inc' / _b[hh_ind_inc_ln])

nlcom _b[hc_farmland] * (`mean_inc' / _b[hh_ind_inc_ln])
