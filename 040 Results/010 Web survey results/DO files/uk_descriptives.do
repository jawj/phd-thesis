include "$ukneadir/survey_data/adding_geo_data/05-code_geo.do"

gen ageband = "."
replace ageband = "16 - 24" if inlist(age__q, "16", "20")
replace ageband = "25 - 44" if inlist(age__q, "25", "30", "35", "40")
replace ageband = "45 - 64" if inlist(age__q, "45", "50", "55", "60")
replace ageband = "65+"     if inlist(age__q, "65", "70", "75", "80", "85", "85_or_more")

tab male__q
tab ageband
tab marital_status__q, missing 
tab in_couple_or_rel__q, missing
tab work_status__q
tab work_status__q if of_working_age 

tab hh_inc_mp, missing  // too many categories!
