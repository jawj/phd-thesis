

 // basic intreg

gen hpy_lo = feel_hpy_100
gen hpy_hi = feel_hpy_100
replace hpy_lo = . if feel_hpy == 0
replace hpy_hi = . if feel_hpy == 1


#delimit ;
intreg hpy_lo hpy_hi

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
  
, vce(cluster user_id);
#delimit cr

outreg2 using "S:\intreg-cluster.xls", stats(coef se pval) sideway label alpha(0.001, 0.01, 0.05) symbol(***, **, *) auto(2) pdec(4) pfmt(f) word



 // trying intreg with i.valid_gapless_user_id 
 
tostring user_id, gen(user_id_string)
encode user_id_string if valid, gen(valid_gapless_user_id)

log using "S:\intreg-with-dummies.log"

 // intreg -> too many vars -- r(103) -- even if valid & mod(valid_gapless_user_id, 10) == 0 & num_responses > 1



 // xtintreg

#delimit ;
xtintreg hpy_lo hpy_hi

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
  
, intreg;
#delimit cr

outreg2 using "S:\xtintreg.xls", stats(coef se pval) sideway label alpha(0.001, 0.01, 0.05) symbol(***, **, *) auto(2) pdec(4) pfmt(f) word

