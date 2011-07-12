
gen max_hpy = feel_hpy == 1
gen min_hpy = feel_hpy == 0
gen not_min_hpy = ! min_hpy


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
  
, fe vce(robust);
#delimit cr

outreg2 using "S:\XYZ.rtf", stats(coef se pval) sideway label alpha(0.001, 0.01, 0.05) symbol(***, **, *) auto(2) pdec(4) pfmt(f) word


#delimit ;
logit max_hpy  // max_hpy not_min_hpy

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
