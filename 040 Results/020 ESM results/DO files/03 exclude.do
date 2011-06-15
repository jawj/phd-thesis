
set more off
set notifyuser on
clear
clear matrix
set mem 3000m
use "s:\all_data_2011_06_15_augmented.dta"


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

