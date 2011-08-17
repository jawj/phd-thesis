
gen ageband = "."
replace ageband = "16 - 24" if inlist(screening_age__q, "16", "20")
replace ageband = "25 - 44" if inlist(screening_age__q, "25", "30", "35", "40")
replace ageband = "45 - 64" if inlist(screening_age__q, "45", "50", "55", "60")
replace ageband = "65+"     if inlist(screening_age__q, "65", "70", "75", "80", "85", "85_or_more")

gen of_working_age = inlist(ageband, "16 - 24", "25 - 44") | inlist(screening_age__q, "45", "50", "55") | (male__q == 0 & screening_age__q == "60")

tab male__q
tab ageband
tab marital_status__q, missing 
tab in_couple_or_rel__q, missing

tab work_status__q
tab work_status__q if of_working_age

tab qualifications__q
tab qualifications__q if of_working_age 

tab household_under_sixteen__q, missing
tab household_sixteen_plus__q, missing

tab hh_inc_mp, missing  // too many categories!
centile hh_inc_mp
sum hh_inc_mp

 // <R>
 
library("foreign")
d <- read.dta("/Users/gjm06/Dropbox/Academic/PhD/London LS and EQ/Geo data/joined_geo_data_2010_03_31.dta")

hist(d$hh_inc_mp[d$hh_inc_mp < 200000], breaks=c(0,4000,6000,8000,10000,12000,15000,18000,20000,23000,26000,29000,32000,38000,44000,50000,56000,68000,80000,100000,150000,200000), xlab = "Household income (£GBP)", main = NA, col = "grey")

hist(d$ind_inc_mp, breaks=c(0,4000,6000,8000,10000,12000,15000,18000,20000,23000,26000,29000,32000,38000,44000,50000,56000,68000,80000,100000,150000,200000), xlab = "Individual income (£GBP)", main = NA, col = "grey")

  // </R>

hist life_sat__q, discrete frequency xtitle("Life satisfaction")
sum life_sat__q
centile life_sat__q

preserve
keep id nspd_point_e nspd_point_n  // wrong! should be map point, not postcode point!
outsheet using "~/Downloads/points.csv", comma  // for mapping in QGIS
restore

set more off
#delimit ;
local rhsvars

home_map_pm10a 
home_map_no2a 

/**
home_coast_r3000
home_water_r3000
home_mountain_r3000
home_grassland_r3000
home_farmland_r3000
home_woodland_r3000
home_suburban_r3000
home_inlandbare_r3000
**/

home_greens_r3000
home_osm_green_r3000 
home_osm_park_r3000 
home_gigl_green_r3000 
home_aod_01

home_water_r3000

home_lhr09_quiet
home_road_quiet 
home_rail_quiet 

ln_home_z1_dist 
ln_home_tube_or_station_dist 
ln_home_railway_dist 

home_tno_per_kp
home_rb_per_khh 
home_vap_per_kp 

home_lsoa_popdens_ppha 
home_popdens_ppha 

home_lsoa_house_price_fe
home_house_price_med9
;

 // sum `rhsvars';
 // corr `rhsvars';

estpost sum `rhsvars';
esttab using "/Users/gjm06/Downloads/londonsum.html", cells("mean(fmt(2)) sd(fmt(2)) min(fmt(2)) max(fmt(2))") label nomtitle nonumber html replace;

estpost correlate `rhsvars', matrix listwise;
est store c1;
esttab * using "/Users/gjm06/Downloads/londoncorrs.html", label unstack not nostar noobs html replace;

