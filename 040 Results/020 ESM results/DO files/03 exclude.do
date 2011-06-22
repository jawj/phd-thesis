
set more off
set notifyuser on
clear
clear matrix
set mem 3000m
use "s:\all_data_2011_06_15_augmented.dta"


gen     realistic_lag_mins = response_lag / 60
replace realistic_lag_mins = . if realistic_lag_mins < -15
replace realistic_lag_mins = 0 if realistic_lag_mins < 0

set scheme s1mono

cdfplot realistic_lag_mins if realistic_lag_mins < 720 & mod(id, 200) == 0, ///
  xtitle("Time since signal (minutes)") ytitle("Cumulative probability of response") ///
  xlabel(0(60)720) xline(60, lwidth(thin)) yline(1, lpattern(dotted) lwidth(thin)) 
graph export "S:\response_lag.ps", as(ps) replace

cdfplot loc_h_acc if outdoors & loc_h_acc < 600 & mod(id, 20) == 0, ///
  xtitle("Location +/- value (m)") ytitle("Cumulative proportion of responses") ///
  xlabel(0(100)600) xline(250, lwidth(thin)) yline(1, lpattern(dotted) lwidth(thin))
graph export "S:\loc_acc.ps", as(ps) replace

count
disp %12.0fc r(N)
global n = r(N)

count if num_activities > 0 & !missing(place, place2)
disp %12.0fc r(N)
disp %12.2fc 100 * r(N) / $n

count if num_activities > 0 & !missing(place, place2) & num_activities < 13
disp %12.0fc r(N)
disp %12.2fc 100 * r(N) / $n

count if num_activities > 0 & !missing(place, place2) & num_activities < 13 & !missing(sent_beep_id)
disp %12.0fc r(N)
disp %12.2fc 100 * r(N) / $n

count if num_activities > 0 & !missing(place, place2) & num_activities < 13 & !missing(sent_beep_id) & response_lag < 60 * 60
disp %12.0fc r(N)
disp %12.2fc 100 * r(N) / $n

count if num_activities > 0 & !missing(place, place2) & num_activities < 13 & !missing(sent_beep_id) & response_lag < 60 * 60 & response_duration < 60 * 5 
disp %12.0fc r(N)
disp %12.2fc 100 * r(N) / $n

count if num_activities > 0 & !missing(place, place2) & num_activities < 13 & !missing(sent_beep_id) & response_lag < 60 * 60 & response_duration < 60 * 5 & !missing(lcm_dn)
disp %12.0fc r(N)
disp %12.2fc 100 * r(N) / $n

count if num_activities > 0 & !missing(place, place2) & num_activities < 13 & !missing(sent_beep_id) & response_lag < 60 * 60 & response_duration < 60 * 5 & !missing(lcm_dn) & ((! outdoors) | loc_h_acc <= 250)
disp %12.0fc r(N)
disp %12.2fc 100 * r(N) / $n

count if num_activities > 0 & !missing(place, place2) & num_activities < 13 & !missing(sent_beep_id) & response_lag < 60 * 60 & response_duration < 60 * 5 & !missing(lcm_dn) & ((! outdoors) | loc_h_acc <= 250) & abs(obs_time_diff_s) < 60 * 60 * 3 & !missing(windspeed)
disp %12.0fc r(N)
disp %12.2fc 100 * r(N) / $n


gen valid = num_activities > 0 & !missing(place, place2) & num_activities < 13 & !missing(sent_beep_id) & response_lag < 60 * 60 & response_duration < 60 * 5 & !missing(lcm_dn) & ((! outdoors) | loc_h_acc <= 250) & abs(obs_time_diff_s) < 60 * 60 * 3 & !missing(windspeed)

