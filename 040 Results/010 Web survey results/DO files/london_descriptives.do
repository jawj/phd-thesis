
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


#delimit ;
sum // corr pca br

home_map_pm10a 
home_map_no2a 

home_coast_sd1000
home_water_sd1000
home_mountain_sd1000
home_grassland_sd1000
home_farmland_sd1000
home_woodland_sd1000
home_suburban_sd1000
home_inlandbare_sd1000

home_osm_green_sd1000 
home_osm_park_sd1000 
home_gigl_green_sd1000 
home_aod_01

home_lhr09_leq

home_noise_road_lden 
home_noise_rail_lden 

ln_home_z1_dist 
ln_home_tube_or_station_dist 
ln_home_railway_dist 

home_tno_per_kp
home_rb_per_khh 
home_vap_per_kp 

home_lsoa_popdens
home_lsoa_house_price_fe
home_house_price_med9
home_popdens_ppkm2
;
delimit CR
