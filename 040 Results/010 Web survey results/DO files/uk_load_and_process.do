clear matrix
clear
set mem 150m
set more off
set scrollbufsize 100000
insheet using "$ukneadir/survey_data/processed_csv/20100902b.csv"

* Export locations/import PG data {

preserve
keep id home_postcode__q other_postcode__q
outsheet using "$ukneadir/survey_data/adding_geo_data/20100902_postcodes.csv", comma replace

clear
insheet using "$phddatadir/pg_data_uk.csv"
save "$phddatadir/pg_data_uk.dta", replace
restore

merge 1:1 id using "$phddatadir/pg_data_uk.dta", generate(_pgmerge)

* }

* ADD TOLUNA DATA!?

* SF-36 {

gen self_rated_health = 6 - rand01_general_health__q 
gen poor_health = self_rated_health < 3
gen good_health = self_rated_health > 3

* recoding

prefixize rand 01 02 20 22 34 36
recode `r(prefixized)' (1 = 100) (2 = 75) (3 = 50) (4 = 25) (5 = 0), prefix("c")
prefixize rand 03 04 05 06 07 08 09 10 11 12
recode `r(prefixized)' (1 = 0) (2 = 50) (3 = 100), prefix("c")
prefixize rand 13 14 15 16 17 18 19
recode `r(prefixized)' (1 = 0) (0 = 100), prefix("c")  // different from the manual: we use 1 = Yes, 0 = No instead of 1 = Yes, 2 = No
prefixize rand 21 23 26 27 30
recode `r(prefixized)' (1 = 100) (2 = 80) (3 = 60) (4 = 40) (5 = 20) (6 = 0), prefix("c")
prefixize rand 24 25 28 29 31
recode `r(prefixized)' (1 = 0) (2 = 20) (3 = 40) (4 = 60) (5 = 80) (6 = 100), prefix("c")
prefixize rand 32 33 35
recode `r(prefixized)' (1 = 0) (2 = 25) (3 = 50) (4 = 75) (5 = 100), prefix("c")

* scales

prefixize crand 03 04 05 06 07 08 09 10 11 12
egen sf36_phys_func = rowmean(`r(prefixized)')
prefixize crand 13 14 15 16
egen sf36_role_lim_phys = rowmean(`r(prefixized)')
prefixize crand 17 18 19
egen sf36_role_lim_emo = rowmean(`r(prefixized)')
prefixize crand 23 27 29 31
egen sf36_energy = rowmean(`r(prefixized)')
prefixize crand 24 25 26 28 30
egen sf36_emo_wb = rowmean(`r(prefixized)')
prefixize crand 20 32
egen sf36_soc_func = rowmean(`r(prefixized)')
prefixize crand 21 22
egen sf36_pain = rowmean(`r(prefixized)')
prefixize crand 01 33 34 35 36
egen sf36_gen_health = rowmean(`r(prefixized)')

* }

* PANAS {

* (rowmean * N gives us simple mean interpolation for missing values)

prefixize panas_ interested alert excited inspired strong determined attentive active enthusiastic proud
egen panas_mean_pos = rowmean(`r(prefixized)')
gen panas_positive = panas_mean_pos * 10

prefixize panas_ irritable distressed ashamed upset nervous guilty scared hostile jittery afraid
egen panas_mean_neg = rowmean(`r(prefixized)')
gen panas_negative = panas_mean_neg * 10

* }

* IPAQ {

* work

gen     ipaq_work_walk_mmw = 3.3 * ipaq_walk_mod_days__q * ipaq_walk_mod_time__q  // (these questions were mis-named on the survey)
replace ipaq_work_walk_mmw = 0 if ipaq_walk_mod_days__q == 0 | ipaq_job__q == 0   // because otherwise missing time var leads to missing var overall

gen     ipaq_work_mod_mmw = 4.0 * ipaq_work_mod_days__q * ipaq_work_mod_time__q 
replace ipaq_work_mod_mmw = 0 if ipaq_work_mod_days__q == 0 | ipaq_job__q == 0

gen     ipaq_work_vig_mmw = 8.0 * ipaq_work_vigour_days__q * ipaq_work_vigour_time__q 
replace ipaq_work_vig_mmw = 0 if ipaq_work_vigour_days__q == 0 | ipaq_job__q == 0

gen     ipaq_work_total_mmw = ipaq_work_walk_mmw + ipaq_work_mod_mmw + ipaq_work_vig_mmw 

* active transport

gen     ipaq_trans_walk_mmw = 3.3 * ipaq_travel_walk_days__q * ipaq_travel_walk_time__q 
replace ipaq_trans_walk_mmw = 0 if ipaq_travel_walk_days__q == 0

gen     ipaq_trans_bike_mmw = 6.0 * ipaq_travel_bike_days__q * ipaq_travel_bike_time__q 
replace ipaq_trans_bike_mmw = 0 if ipaq_travel_bike_days__q == 0

gen     ipaq_trans_total_mmw = ipaq_trans_walk_mmw + ipaq_trans_bike_mmw

* domestic

gen     ipaq_yard_vig_mmw = 5.5 * ipaq_garden_vigour_days__q * ipaq_garden_vigour_time__q 
replace ipaq_yard_vig_mmw = 0 if ipaq_garden_vigour_days__q == 0

gen     ipaq_yard_mod_mmw = 4.0 * ipaq_garden_mod_days__q * ipaq_garden_mod_time__q
replace ipaq_yard_mod_mmw = 0 if ipaq_garden_mod_days__q == 0

gen     ipaq_inside_mod_mmw = 3.0 * ipaq_home_mod_days__q * ipaq_home_mod_time__q 
replace ipaq_inside_mod_mmw = 0 if ipaq_home_mod_days__q == 0

gen     ipaq_dom_total_mmw = ipaq_yard_vig_mmw + ipaq_yard_mod_mmw + ipaq_inside_mod_mmw

* leisure

gen     ipaq_leisure_walk_mmw = 3.3 * ipaq_leisure_walk_days__q * ipaq_leisure_walk_time__q 
replace ipaq_leisure_walk_mmw = 0 if ipaq_leisure_walk_days__q == 0

gen     ipaq_leisure_mod_mmw = 4.0 * ipaq_leisure_mod_days__q * ipaq_leisure_mod_time__q 
replace ipaq_leisure_mod_mmw = 0 if ipaq_leisure_mod_days__q == 0

gen     ipaq_leisure_vig_mmw = 8.0 * ipaq_leisure_vigour_days__q * ipaq_leisure_vigour_time__q 
replace ipaq_leisure_vig_mmw = 0  if ipaq_leisure_vigour_days__q == 0

gen     ipaq_leisure_total_mmw = ipaq_leisure_walk_mmw + ipaq_leisure_mod_mmw + ipaq_leisure_vig_mmw

* activity totals

gen ipaq_all_walk_mmw = ipaq_work_walk_mmw + ipaq_trans_walk_mmw  + ipaq_leisure_walk_mmw
gen ipaq_all_mod_mmw  = ipaq_work_mod_mmw  + ipaq_yard_mod_mmw    + ipaq_inside_mod_mmw   + ipaq_leisure_mod_mmw 
gen ipaq_all_vig_mmw  = ipaq_work_vig_mmw  + ipaq_leisure_vig_mmw 
gen ipaq_total_mmw    = ipaq_all_walk_mmw  + ipaq_all_mod_mmw     + ipaq_all_vig_mmw 

* green exercise

recode ipaq_leisure_walk_green__q   (4 = 0.9) (3 = 0.65) (2 = 0.4) (1 = 0.15) (0 = 0) (. = 0), gen(walk_green_prop)
recode ipaq_leisure_mod_green__q    (4 = 0.9) (3 = 0.65) (2 = 0.4) (1 = 0.15) (0 = 0) (. = 0), gen(mod_green_prop)
recode ipaq_leisure_vigour_green__q (4 = 0.9) (3 = 0.65) (2 = 0.4) (1 = 0.15) (0 = 0) (. = 0), gen(vigour_green_prop)

gen ipaq_green_mmw = ipaq_yard_vig_mmw + ipaq_yard_mod_mmw + ///
   (ipaq_leisure_walk_mmw * walk_green_prop) + (ipaq_leisure_mod_mmw * mod_green_prop) + (ipaq_leisure_vig_mmw * vigour_green_prop)

gen ipaq_nongreen_mmw = ipaq_total_mmw - ipaq_green_mmw

gen ipaq_leisure_natural_mmw = (ipaq_leisure_walk_mmw * walk_green_prop) + (ipaq_leisure_mod_mmw * mod_green_prop) + (ipaq_leisure_vig_mmw * vigour_green_prop)

gen ipaq_leisure_nonnatural_mmw = ipaq_leisure_total_mmw - ipaq_leisure_natural_mmw

gen ipaq_all_walk_mhw = ipaq_all_walk_mmw / 60
gen ipaq_all_mod_mhw  = ipaq_all_mod_mmw / 60
gen ipaq_all_vig_mhw  = ipaq_all_vig_mmw / 60
gen ipaq_total_mhw    = ipaq_total_mmw / 60

gen ipaq_green_mhw    = ipaq_green_mmw / 60
gen ipaq_nongreen_mhw = ipaq_nongreen_mmw / 60

gen ipaq_leisure_natural_mhw = ipaq_leisure_natural_mmw / 60
gen ipaq_leisure_nonnatural_mhw = ipaq_leisure_nonnatural_mmw / 60
gen ipaq_leisure_total_mhw = ipaq_leisure_total_mmw / 60

* exercise time

gen     ipaq_work_walk_minwk = ipaq_walk_mod_days__q * ipaq_walk_mod_time__q  // (these questions were mis-named on the survey)
replace ipaq_work_walk_minwk = 0 if ipaq_walk_mod_days__q == 0 | ipaq_job__q == 0   // because otherwise missing time var leads to missing var overall

gen     ipaq_work_mod_minwk = ipaq_work_mod_days__q * ipaq_work_mod_time__q 
replace ipaq_work_mod_minwk = 0 if ipaq_work_mod_days__q == 0 | ipaq_job__q == 0

gen     ipaq_work_vig_minwk = ipaq_work_vigour_days__q * ipaq_work_vigour_time__q 
replace ipaq_work_vig_minwk = 0 if ipaq_work_vigour_days__q == 0 | ipaq_job__q == 0

gen     ipaq_work_total_minwk = ipaq_work_walk_minwk + ipaq_work_mod_minwk + ipaq_work_vig_minwk 

* active transport

gen     ipaq_trans_walk_minwk = ipaq_travel_walk_days__q * ipaq_travel_walk_time__q 
replace ipaq_trans_walk_minwk = 0 if ipaq_travel_walk_days__q == 0

gen     ipaq_trans_bike_minwk = ipaq_travel_bike_days__q * ipaq_travel_bike_time__q 
replace ipaq_trans_bike_minwk = 0 if ipaq_travel_bike_days__q == 0

gen     ipaq_trans_total_minwk = ipaq_trans_walk_minwk + ipaq_trans_bike_minwk

* domestic

gen     ipaq_yard_vig_minwk = ipaq_garden_vigour_days__q * ipaq_garden_vigour_time__q 
replace ipaq_yard_vig_minwk = 0 if ipaq_garden_vigour_days__q == 0

gen     ipaq_yard_mod_minwk = ipaq_garden_mod_days__q * ipaq_garden_mod_time__q
replace ipaq_yard_mod_minwk = 0 if ipaq_garden_mod_days__q == 0

gen     ipaq_inside_mod_minwk = ipaq_home_mod_days__q * ipaq_home_mod_time__q 
replace ipaq_inside_mod_minwk = 0 if ipaq_home_mod_days__q == 0

gen     ipaq_dom_total_minwk = ipaq_yard_vig_minwk + ipaq_yard_mod_minwk + ipaq_inside_mod_minwk

* leisure

gen     ipaq_leisure_walk_minwk = ipaq_leisure_walk_days__q * ipaq_leisure_walk_time__q 
replace ipaq_leisure_walk_minwk = 0 if ipaq_leisure_walk_days__q == 0

gen     ipaq_leisure_mod_minwk = ipaq_leisure_mod_days__q * ipaq_leisure_mod_time__q 
replace ipaq_leisure_mod_minwk = 0 if ipaq_leisure_mod_days__q == 0

gen     ipaq_leisure_vig_minwk = ipaq_leisure_vigour_days__q * ipaq_leisure_vigour_time__q 
replace ipaq_leisure_vig_minwk = 0  if ipaq_leisure_vigour_days__q == 0

gen     ipaq_leisure_total_minwk = ipaq_leisure_walk_minwk + ipaq_leisure_mod_minwk + ipaq_leisure_vig_minwk

* activity totals

gen ipaq_all_walk_minwk = ipaq_work_walk_minwk + ipaq_trans_walk_minwk  + ipaq_leisure_walk_minwk
gen ipaq_all_mod_minwk  = ipaq_work_mod_minwk  + ipaq_yard_mod_minwk    + ipaq_inside_mod_minwk   + ipaq_leisure_mod_minwk 
gen ipaq_all_vig_minwk  = ipaq_work_vig_minwk  + ipaq_leisure_vig_minwk 
gen ipaq_total_minwk    = ipaq_all_walk_minwk  + ipaq_all_mod_minwk     + ipaq_all_vig_minwk

gen ipaq_leisure_natural_minwk = (ipaq_leisure_walk_minwk * walk_green_prop) + (ipaq_leisure_mod_minwk * mod_green_prop) + (ipaq_leisure_vig_minwk * vigour_green_prop)
gen ipaq_leisure_nonnatural_minwk = ipaq_leisure_total_minwk - ipaq_leisure_natural_minwk

gen ipaq_leisure_natural_hrwk = ipaq_leisure_natural_minwk / 60
gen ipaq_leisure_nonnatural_hrwk = ipaq_leisure_nonnatural_minwk / 60

* }

* Misc coding {

gen lone_adult = household_sixteen_plus__q == 1
gen live_with_kids = household_under_sixteen__q > 0

gen platform = ""
replace platform = "linux" if regexm(user_agent, "Linux")
replace platform = "mac" if regexm(user_agent, "Mac")
replace platform = "win" if regexm(user_agent, "Windows")
replace platform = "iphone" if regexm(user_agent, "iPhone")

gen accommodation = ""
replace accommodation = house_type__q if accomm_type__q == "house"
replace accommodation = flat_type__q if accomm_type__q == "flat"
replace accommodation = other_type__q if accomm_type__q == "other"
replace accommodation = accomm_type__q if accommodation == ""

gen tenure = tenure__q
replace tenure = landlord__q + "_" + tenure if tenure == "rent" & landlord__q != ""

gen home_own_outright = tenure == "own"
replace home_own_outright = . if missing(tenure)
gen home_own_at_all = tenure == "mortgage" | tenure == "own"
replace home_own_at_all = . if missing(tenure)
gen social_tenant = inlist(tenure, "council_rent", "ha_rent")
replace social_tenant = . if missing(tenure)

gen highrise = flat_type__q == "block"
gen ground_level = living_floor__q < 1

gen hh_size_unweighted = household_sixteen_plus__q + household_under_sixteen__q
gen hh_size_weighted = (household_sixteen_plus__q + (0.7 * household_under_sixteen__q)) ^ 0.5

gen crowded_house     = hh_size_unweighted > household_rooms__q
gen crowded_house_alt = household_sixteen_plus__q + (household_under_sixteen__q / 2) > household_rooms__q - 1

gen house_crowding = hh_size_unweighted / household_rooms__q

gen lives_alone = hh_size_unweighted == 1

gen own_garden = garden__q == "own"
replace own_garden = . if missing(garden__q)

gen dblglazing = .
replace dblglazing = 0 if double_glazing__q == "none"
replace dblglazing = 1 if double_glazing__q == "some"
replace dblglazing = 2 if double_glazing__q == "all"

gen nodblglazing = !dblglazing

gen num_house_problems = housing_problems__q_mould + housing_problems__q_cold + housing_problems__q_insects

gen airnoise012 = 3 - aircraft_noise__q  
gen rrnoise012 = 3 - road_rail_noise__q
gen airpoll012 = 3 - air_pollution__q
gen crime012 = 3 - crime__q

gen age_mp = real(age__q) + 2.5
replace age_mp = 18 if age__q == "16"
replace age_mp = 87.5 if age__q == "85_or_more"

gen age_mp_sq = age_mp ^ 2

gen married = marital_status__q == "married" 
replace married = . if missing(marital_status__q)
gen cohabiting = married | in_couple_or_rel__q == 2
replace cohabiting = . if missing(marital_status__q)
gen really_single = !married & in_couple_or_rel__q == 0
replace really_single = . if missing(marital_status__q)
gen divorced = marital_status__q == "divorced"
replace divorced = . if missing(marital_status__q)
gen separated = marital_status__q == "separated"
replace separated = . if missing(marital_status__q)
gen divsep = divorced | separated
replace divsep = . if missing(marital_status__q)

gen degree = qualifications__q == 2
replace degree = . if missing(qualifications__q)
gen no_quals = qualifications__q == 0
replace no_quals = . if missing(qualifications__q)

gen working = inlist(work_status__q, "emp", "self_emp")
replace working = . if missing(work_status__q)
gen unemployed = work_status__q == "unemp"
replace unemployed = . if missing(work_status__q)
gen off_sick = work_status__q == "sick"
replace off_sick = . if missing(work_status__q)

gen homey = inlist(work_status__q, "caring", "home_family", "parental", "retired", "sick", "unemp")
replace homey = . if missing(work_status__q)

gen hh_inc_mp = .
replace hh_inc_mp = 2000 if household_income__q == "4000_less_than"
replace hh_inc_mp = real(household_income__q) + 1000 if inlist(household_income__q, "4000", "6000", "8000", "10000", "18000")
replace hh_inc_mp = real(household_income__q) + 1500 if inlist(household_income__q, "12000", "15000", "20000", "23000", "26000", "29000")
replace hh_inc_mp = real(household_income__q) + 3000 if inlist(household_income__q, "32000", "38000", "44000", "50000")
replace hh_inc_mp = real(household_income__q) + 6000 if inlist(household_income__q, "56000", "68000")
replace hh_inc_mp = real(household_income__q) + 10000 if inlist(household_income__q, "80000")
replace hh_inc_mp = real(household_income__q) + 25000 if inlist(household_income__q, "100000", "150000")
replace hh_inc_mp = real(household_income__q) + 100000 if inlist(household_income__q, "200000")
replace hh_inc_mp = real(household_income__q) + 200000 if inlist(household_income__q, "400000")
replace hh_inc_mp = . if inlist(household_income__q, "800000_or_more")

gen hh_inc_mp_ln = ln(hh_inc_mp)

gen ind_inc_mp = .
replace ind_inc_mp = 2000 if individual_income__q == "4000_less_than"
replace ind_inc_mp = real(individual_income__q) + 1000 if inlist(individual_income__q, "4000", "6000", "8000", "10000", "18000")
replace ind_inc_mp = real(individual_income__q) + 1500 if inlist(individual_income__q, "12000", "15000", "20000", "23000", "26000", "29000")
replace ind_inc_mp = real(individual_income__q) + 3000 if inlist(individual_income__q, "32000", "38000", "44000", "50000")
replace ind_inc_mp = real(individual_income__q) + 6000 if inlist(individual_income__q, "56000", "68000")
replace ind_inc_mp = real(individual_income__q) + 10000 if inlist(individual_income__q, "80000")
replace ind_inc_mp = real(individual_income__q) + 25000 if inlist(individual_income__q, "100000", "150000")
replace ind_inc_mp = real(individual_income__q) + 100000 if inlist(individual_income__q, "200000")
replace ind_inc_mp = real(individual_income__q) + 200000 if inlist(individual_income__q, "400000")
replace ind_inc_mp = . if inlist(individual_income__q, "800000_or_more")

gen ind_inc_mp_ln = ln(ind_inc_mp)

gen hh_ind_inc = hh_inc_mp / hh_size_weighted
gen hh_ind_inc_ln = ln(hh_ind_inc)

gen weekend = (start_time_days_since_sunday == 0 | start_time_days_since_sunday == 6)

gen groupie = clubs_groups_etc__q < 3
replace groupie = . if missing(clubs_groups_etc__q)

gen zero_religiosity = how_religious__q == 0
replace zero_religiosity = . if missing(how_religious__q)
gen mega_religiosity = how_religious__q > 6
replace mega_religiosity = . if missing(how_religious__q)
gen religious = how_religious__q > 5
replace religious = . if missing(how_religious__q)
gen agnostic = how_religious__q > 3 & how_religious__q < 7
replace agnostic = . if missing(how_religious__q)

gen political = political_interest__q < 3
replace political = . if missing(political_interest__q)
gen commie = inlist(politics_left_right__q, "0", "1", "2")
replace commie = . if missing(politics_left_right__q)
gen fascist = inlist(politics_left_right__q, "8", "9", "10")
replace fascist = . if missing(politics_left_right__q)
gen extremist = commie | fascist
replace extremist = . if missing(politics_left_right__q)
gen centrist = inlist(politics_left_right__q, "4", "5", "6")
replace centrist = . if missing(politics_left_right__q)

gen natural_parents = real(natural_parents__q)

gen ln_sleep_last_night = ln(sleep_last_night__q)
gen ln_sleep_got = ln(sleep_got__q)

gen slept_lt_6h_last_night = sleep_last_night__q < 6
replace slept_lt_6h_last_night = . if missing(sleep_last_night__q)
gen sleeps_lt_6h = sleep_got__q < 6
replace sleeps_lt_6h = . if missing(sleep_got__q)

recode commute_time__q (5 = 7.5) (20 = 22.5) (40 = 37.5) (60 = 52.5) (80 = 75), gen(commutetimemp)

* }

* Coding spatial stuff {

gen nature_bbc_num = real(nature_bbc__q)
replace nature_bbc_num = 0 if missing(nature_bbc_num)

recode garden_use__q (7 = 365) (6 = 152) (5 = 52) (4 = 24) (3 = 12) (2 = 4) (1 = 0), generate(garden_use_pa)
replace garden_use_pa = 0 if missing(garden_use_pa)

recode countryside_use__q (7 = 365) (6 = 152) (5 = 52) (4 = 24) (3 = 12) (2 = 4) (1 = 0), generate(countryside_use_pa)
replace countryside_use__q = 0 if missing(countryside_use__q)

recode green_space_use__q (7 = 365) (6 = 152) (5 = 52) (4 = 24) (3 = 12) (2 = 4) (1 = 0), generate(green_space_use_pa)
replace green_space_use__q = 0 if missing(green_space_use__q)


gen garden_use_weekly = garden_use__q >= 5
gen countryside_use_weekly = countryside_use__q >= 5
gen other_green_use_weekly = green_space_use__q >= 5
gen countryside_use_monthly = countryside_use__q >= 3
gen other_green_use_monthly = green_space_use__q >= 3


gen nat_parks_live_in = 0
replace nat_parks_live_in = 1 if nat_parks__q == "home"
gen nat_parks_visits = real(nat_parks__q)
recode nat_parks_visits (0 = 0) (1 = 1.5) (3 = 4) (5 = 8.5) (7 = 14)
replace nat_parks_visits = 0 if nat_parks__q == "home"

foreach loc in home other {
  foreach thing in mway aroad railway station coast river natpark aonb nnr {
    capture drop ln_`loc'_`thing'_dist
    gen ln_`loc'_`thing'_dist = ln(`loc'_`thing'_dist + 1)
  }
  foreach lcm in coast water mountain grassland farmland woodland suburban inlandbare {
    replace `loc'_`lcm'_lsoaprop = 0 if missing(`loc'_`lcm'_lsoaprop)
  }
  gen `loc'_popdens_kpkm2 = `loc'_popdens_ppkm2 / 1000
  gen `loc'_popdens_ppha = `loc'_popdens_ppkm2 / 100
  
  gen `loc'_lsoa_popdens = `loc'_lsoa_pop / `loc'_lsoa_area * 1000000
  gen `loc'_lsoa_popdens_ppha = `loc'_lsoa_pop / `loc'_lsoa_area * 10000
}

foreach loc in "" other_ {
  gen `loc'green_views = `loc'green_views__q_trees | `loc'green_views__q_grass
  gen `loc'blue_views  = `loc'green_views__q_water | `loc'green_views__q_pond
}

foreach lcmsuffix in r1000 r3000 r10000 {
  gen home_greens_`lcmsuffix' = home_mountain_`lcmsuffix' + home_grassland_`lcmsuffix' + home_farmland_`lcmsuffix' + home_woodland_`lcmsuffix' 
}

* }

* SF-6D {

merge 1:1 id using "$ukneadir/survey_data/sf-6d/bayes_posterior_means.dta", generate(_sf6dmerge)

* }

* Labels {

foreach lcmsuffix in sd200 sd1000 r200 r1000 r3000 r10000 {
  label variable home_coast_`lcmsuffix' "Marine and coastal margins^"
  label variable home_water_`lcmsuffix' "Freshwater, wetlands and floodplains^"
  label variable home_mountain_`lcmsuffix' "Mountains, moors and heathlands^"
  label variable home_grassland_`lcmsuffix' "Semi-natural grasslands^"
  label variable home_farmland_`lcmsuffix' "Enclosed farmland^"
  label variable home_woodland_`lcmsuffix' "Woodland^"
  label variable home_suburban_`lcmsuffix' "Suburban/rural developed^"
  label variable home_inlandbare_`lcmsuffix' "Inland bare ground^"
}
foreach lcmsuffix in r1000 r3000 r10000 {
  label variable home_greens_`lcmsuffix' "LCM green spaces^"
}
label variable ln_home_mway_dist "Distance to motorway, ln(m)"
label variable ln_home_railway_dist "Distance to railway line, ln(m)"
label variable ln_home_station_dist "Distance to station, ln(m)"
label variable ln_home_coast_dist "Distance to coast, ln(m)"
label variable ln_home_river_dist "Distance to river, ln(m)"

label variable ln_home_natpark_dist "Distance to National Park, ln(m)"
label variable ln_home_aonb_dist "Distance to AONB, ln(m)"
label variable ln_home_nnr_dist "Distance to NNR, ln(m)"

label variable home_lsoa_popdens_ppha "Pop. density (LSOA, people/ha)"
label variable home_popdens_ppha "Pop. density (km2, people/ha)"
label variable home_lsoa_house_price_fe "House price (std. LSOA mean)"
label variable home_house_price_med9 "House price (std. local median)"

label variable ipaq_total_mhw "IPAQ total MET-hours/week"
label variable poor_health "Poor health"
label variable good_health "Good health"
label variable home_own_outright "Home owned outright"
label variable social_tenant "Social tenant"
label variable hh_ind_inc_ln "Equivalised household income, ln(£)"
label variable male__q "Male"
label variable age_mp "Age"
label variable age_mp_sq "Age squared"
label variable unemployed "Unemployed"
label variable lives_alone "Lives alone"
label variable religious "Religious"

* }


save "$phddatadir/uk_data_for_analsis.dta", replace
