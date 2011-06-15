
set more off
set notifyuser on
clear
clear matrix
set mem 3000m
use "s:\all_data_2011_06_15_augmented.dta"


set scheme s1mono

preserve
keep if valid

hist feel_hpy_100 if valid, width(2) xtitle("Happy: self-rating")
graph export "S:\happy_dist.ps", as(ps) replace

gen feel_rlx_100 = feel_rlx * 100
hist feel_rlx_100 if valid, width(2) xtitle("Relaxed: self-rating")
graph export "S:\relaxed_dist.ps", as(ps) replace

gen feel_awk_100 = feel_awk * 100
hist feel_awk_100 if valid, width(2) xtitle("Awake: self-rating")
graph export "S:\awake_dist.ps", as(ps) replace

restore
