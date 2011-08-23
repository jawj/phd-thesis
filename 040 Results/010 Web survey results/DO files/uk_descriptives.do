
gen ageband = "."
replace ageband = "16 - 24" if inlist(age__q, "16", "20")
replace ageband = "25 - 44" if inlist(age__q, "25", "30", "35", "40")
replace ageband = "45 - 64" if inlist(age__q, "45", "50", "55", "60")
replace ageband = "65+"     if inlist(age__q, "65", "70", "75", "80", "85", "85_or_more")

gen of_working_age = inlist(ageband, "16 - 24", "25 - 44") | inlist(age__q, "45", "50", "55") | (male__q == 0 & age__q == "60")

tab male__q
tab ageband
tab tl_marital_status, missing

tab work_status__q
tab work_status__q if of_working_age 

tab tl_education
tab tl_education if of_working_age

tab household_under_sixteen__q, missing
tab household_sixteen_plus__q, missing

tab hh_inc_mp, missing  // too many categories!
centile hh_inc_mp
sum hh_inc_mp

 // <R>
 
library("foreign")
d <- read.dta("/Users/gjm06/Dropbox/Academic/UKNEA/survey_data/toluna_merged.dta")
hist(d$hh_inc_mp[d$hh_inc_mp < 200000], breaks=c(0,4000,6000,8000,10000,12000,15000,18000,20000,23000,26000,29000,32000,38000,44000,50000,56000,68000,80000,100000,150000,200000), xlab = "Household income (£GBP)", main = NA, col = "grey")

  // </R>

hist life_sat__q, discrete frequency xtitle("Life satisfaction")
sum life_sat__q
centile life_sat__q



set more off
#delimit ;
local rhsvars

home_coast_r3000
home_water_r3000
home_mountain_r3000
home_grassland_r3000
home_farmland_r3000
home_woodland_r3000
home_suburban_r3000
home_inlandbare_r3000

ln_home_natpark_dist
ln_home_aonb_dist
ln_home_nnr_dist

ln_home_coast_dist
ln_home_river_dist

ln_home_mway_dist
ln_home_railway_dist
ln_home_station_dist

home_lsoa_popdens_ppha 
home_popdens_ppha 

home_lsoa_house_price_fe
home_house_price_med9
;

 // sum `rhsvars';
 // corr `rhsvars';

estpost sum `rhsvars';
esttab using "/Users/gjm06/Downloads/uksum.html", cells("mean(fmt(2)) sd(fmt(2)) min(fmt(2)) max(fmt(2))") label nomtitle nonumber html replace;

estpost correlate `rhsvars', matrix listwise;
est store c1;
esttab * using "/Users/gjm06/Downloads/ukcorrs.html", label unstack not nostar noobs html replace;




set more off
#delimit ;
local rhsvars
ipaq_total_mhw
poor_health
good_health
social_tenant 
hh_ind_inc_ln
male__q
age_mp 
age_mp_sq
unemployed
lives_alone
religious
;

estpost sum `rhsvars';
esttab using "/Users/gjm06/Downloads/uksum2.html", cells("mean(fmt(2)) sd(fmt(2)) min(fmt(2)) max(fmt(2))") label nomtitle nonumber html replace;

