clear
clear matrix
set mem 3000m
insheet using "s:\all_data_2011_03_10.csv", clear
drop if id == 1193235 & obs_time_diff_s == -3948800  // disturbing duplicate -- from weather join? 
xtset user_id response_seq
save "s:\all_data_2011_03_10.dta"
