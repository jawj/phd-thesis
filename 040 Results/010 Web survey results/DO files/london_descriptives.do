include "$lseqdir/Data analysis/07-perceptions_instruments_01.do"

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
