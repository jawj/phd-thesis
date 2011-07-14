
insheet using "$ukneadir/survey_data/toluna_respondent_data.csv"
save "$ukneadir/survey_data/toluna_respondent_data.dta"

include "$ukneadir/survey_data/adding_geo_data/05-code_geo.do"
gen tl_gid = real(regexs(0)) if regexm(starting_url, "[0-9]+$")

drop if id == 7071  // duplicate Toluna GID, and v similar responses, made within 30 mins
merge 1:1 tl_gid using "$ukneadir/survey_data/toluna_respondent_data.dta", generate(_tl_merge) keep(match master)

