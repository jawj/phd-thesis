
gen max_hpy = feel_hpy == 1
gen min_hpy = feel_hpy == 0
gen not_min_hpy = ! min_hpy


 // FE w/o or w/only spatial vars

#delimit ;
xtreg feel_hpy_100

 // lctout_*  
 // aonb_enc_out nnr_enc_out natpark_enc_out
 do_* with_*
 at_work elsewhere
 vehicle outdoors
 rseq_0 rseq_10 rseq_50
 wkdayhour_* wkendhour_*
 // is_daylight_out sunny_out rain_out snow_out fog_out temp_*_out wind_*_out

if valid  

, fe vce(robust);
#delimit cr

outreg2 using "S:\fe-no-spatial.xls", stats(coef se pval) sideway label alpha(0.001, 0.01, 0.05) symbol(***, **, *) auto(2) pdec(4) pfmt(f) word


#delimit ;
xtreg feel_hpy_100

 lctout_*  
 // aonb_enc_out nnr_enc_out natpark_enc_out
 // do_* with_*
 // at_work elsewhere
 vehicle outdoors
 // rseq_0 rseq_10 rseq_50
 // wkdayhour_* wkendhour_*
 is_daylight_out sunny_out rain_out snow_out fog_out temp_*_out wind_*_out

if valid  

, fe vce(robust);
#delimit cr

outreg2 using "S:\fe-only-spatial.xls", stats(coef se pval) sideway label alpha(0.001, 0.01, 0.05) symbol(***, **, *) auto(2) pdec(4) pfmt(f) word


 // FE

#delimit ;
xtreg feel_hpy_100

  lctout_*  
  // aonb_enc_out nnr_enc_out natpark_enc_out
  do_* with_*
  at_work elsewhere
  vehicle outdoors
  rseq_0 rseq_10 rseq_50
  wkdayhour_* wkendhour_*
  is_daylight_out sunny_out rain_out snow_out fog_out temp_*_out wind_*_out

if valid  
  // & loc_h_acc <= 100 & response_lag < 20 * 60
  // & ! min_hpy & ! max_hpy
  // & weekend
  
, fe vce(robust);
#delimit cr

outreg2 using "S:\spikeless.xls", stats(coef se pval) sideway label alpha(0.001, 0.01, 0.05) symbol(***, **, *) auto(2) pdec(4) pfmt(f) word


 // spikes

#delimit ;
probit min_hpy  // max_hpy not_min_hpy

  lctout_*
  do_* with_*
  at_work elsewhere
  vehicle outdoors
  rseq_0 rseq_10 rseq_50
  wkdayhour_* wkendhour_*
  is_daylight_out sunny_out rain_out snow_out fog_out temp_*_out wind_*_out

if valid

, vce(cluster user_id);
#delimit cr


 // OLS -- same as FE spec
 
#delimit ;
regress feel_hpy_100

 lctout_*  
 do_* with_*
 at_work elsewhere
 vehicle outdoors
 rseq_0 rseq_10 rseq_50
 wkdayhour_* wkendhour_*
 is_daylight_out sunny_out rain_out snow_out fog_out temp_*_out wind_*_out

if valid  

, vce(cluster user_id);
#delimit cr

outreg2 using "S:\ols-fe-spec.xls", stats(coef se pval) sideway label alpha(0.001, 0.01, 0.05) symbol(***, **, *) auto(2) pdec(4) pfmt(f) word


 // OLS -- FE spec plus individual FX
 
#delimit ;
regress feel_hpy_100

 lctout_*  
 do_* with_*
 at_work elsewhere
 vehicle outdoors
 rseq_0 rseq_10 rseq_50
 wkdayhour_* wkendhour_*
 is_daylight_out sunny_out rain_out snow_out fog_out temp_*_out wind_*_out
 
 male age agesq ib5.health ib(freq).work_enc ib(freq).mrg_enc lnpcinck

if valid  

, vce(cluster user_id);
#delimit cr

outreg2 using "S:\ols-with-ind.xls", stats(coef se pval) sideway label alpha(0.001, 0.01, 0.05) symbol(***, **, *) auto(2) pdec(4) pfmt(f) word


 // RE -- FE spec plus individual FX

#delimit ;
xtreg feel_hpy_100

 lctout_*  
 // aonb_enc_out nnr_enc_out natpark_enc_out
 do_* with_*
 at_work elsewhere
 vehicle outdoors
 rseq_0 rseq_10 rseq_50
 wkdayhour_* wkendhour_*
 is_daylight_out sunny_out rain_out snow_out fog_out temp_*_out wind_*_out

 male age agesq ib(freq).work_enc ib(freq).mrg_enc lnpcinck

if valid  
 // & loc_h_acc <= 100 & response_lag < 20 * 60
 // & ! min_hpy & ! max_hpy
 // & weekend

, re vce(robust);
#delimit cr

outreg2 using "S:\re-incl-demog.xls", stats(coef se pval) sideway label alpha(0.001, 0.01, 0.05) symbol(***, **, *) auto(2) pdec(4) pfmt(f) word
