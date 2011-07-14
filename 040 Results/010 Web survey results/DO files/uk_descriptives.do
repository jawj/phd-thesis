include "$ukneadir/survey_data/adding_geo_data/05-code_geo.do"

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
  
