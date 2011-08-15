clear matrix
clear
set mem 100m
set more off
set scrollbufsize 100000

insheet using "$lseqdir/Survey data/Processed CSV/final_09_28.csv"
keep if finished_survey == "true" | thanks_page_first_look__datum != ""
keep if quota_excluded != "true"
keep if regexm(referral_data, "^toluna\?id=") & quota_class != ""
drop if regexm(ip, "^158\.143\.90\.") | ip == "78.86.122.51"

* Location cleaning {

gen home_pc_std = upper(regexs(1)) + " " + upper(regexs(2)) ///
	if regexm(home_postcode__q, "^\s*([A-Za-z][A-Za-z]?[0-9][0-9]?[A-Za-z]?) *([0-9][A-Za-z][A-Za-z])\s*$")
replace home_pc_std = "CR0 2EA" if home_postcode__q == "cro 2ea"
replace home_pc_std = "N3 3JD" if home_postcode__q == "N3 3 JD"
replace home_pc_std = "N8 0BE" if home_postcode__q == "n8 obe"
replace home_pc_std = "UB5 6YH" if home_postcode__q == "UB5 6\\yh"
replace home_pc_std = "N1 0QX" if home_postcode__q == "N1 OQX"
replace home_pc_std = "N4 1SA" if home_postcode__q == "N4 !sa"

gen home_pc_valid = home_pc_std != ""
gen home_loc_valid = inlist(home_map_status__q, "confirmed", "approximate") & home_map_location__q != ""
gen home_loc_zoom = regexs(1) if regexm(home_map_location__q, ",([0-9]+)$")

gen other_pc_std = upper(regexs(1)) + " " + upper(regexs(2)) ///
  if regexm(other_postcode__q, "^\s*([A-Za-z][A-Za-z]?[0-9][0-9]?[A-Za-z]?) *([0-9][A-Za-z][A-Za-z])\s*$")
replace other_pc_std = "WC2A 8RA" if other_postcode__q == "wc2 a 8ra" 
replace other_pc_std = "E15 2JB" if other_postcode__q == "E15 2JB."
replace other_pc_std = "E5 0PA" if other_postcode__q == "E5 OPA"
replace other_pc_std = "SE5 0AJ" if other_postcode__q == "SE5 oAJ"
replace other_pc_std = "TW3 1NE" if other_postcode__q == "tw3 ine"

* }

* Export location/import geodata/import weather {

gen hour_of_year = (start_time_days_since_dec_31 - 1) * 24 + start_time_hour_of_day

preserve

keep id home_pc_std home_street_name__q home_map_location__q home_map_status__q other_pc_std other_street_name__q other_map_location__q other_map_status__q
rename home_pc_std home_postcode__q    // NB. previously exported wrong variables here => missing a few valid postcodes in pg data set
rename other_pc_std other_postcode__q
outsheet using "$phddatadir/london_location_data.csv", comma replace

clear
insheet using "$phddatadir/pg_data_london.csv", comma
save "$phddatadir/pg_data_london.dta", replace

clear
insheet using "$lseqdir/Web scraped data/Weather - Met Office/scripts/weather.csv"
save "$phddatadir/weather_data.dta", replace

restore

merge 1:1 id using "$phddatadir/pg_data_london.dta", generate(_pgmerge)
keep if home_map_poly_distance < 200 & home_is_valid == "t"

merge m:1 hour_of_year using "$phddatadir/weather_data.dta", generate(_weathermerge) keep(match master)

* }

* Create ESS composites {

generate num_e33 = real(ess_family_time_enjoyable__q)
generate num_e34 = real(ess_family_time_stressful__q)
generate std_c1 = (ess_happy__q + 0)
generate std_e11 = (ess_week_happy__q + 0)
generate std_e13 = (ess_week_enjoyed_life__q + 0)
generate std_e8 = 5 - (ess_week_depressed__q + 0)
generate std_e14 = 5 - (ess_week_sad__q + 0)
generate std_b24 = (life_sat__q + 0)
generate std_e31 = (ess_satisfied_life_so_far__q + 0)
generate std_e32 = (ess_standard_of_living__q + 0)
generate std_e7 = 6 - (ess_nearly_ideal__q + 0)
generate std_e18 = 5 - (ess_week_tired__q + 0)
generate std_e9 = 5 - (ess_week_effort__q + 0)
generate std_e15 = 5 - (ess_week_not_get_going__q + 0)
generate std_e10 = 5 - (ess_week_restless_sleep__q + 0)
generate std_e16 = (ess_week_much_energy__q + 0)
generate std_e22 = (ess_week_rested__q + 0)
generate std_c15 = (self_reported_health__q + 1)
generate std_e30 = 6 - (ess_physical_activity__q + 0)
generate std_e5 = 6 - (ess_positivity__q + 0)
generate std_e6 = (ess_failure__q + 0)
generate std_e4 = 6 - (ess_optimistic__q + 0)
generate std_e29 = (ess_long_time_normal__q + 0)
generate std_e25 = (ess_no_chance_capable__q + 0)
generate std_e27 = 6 - (ess_accomplishment__q + 0)
generate std_e24 = (ess_seldom_enjoy__q + 0)
generate std_e23 = 6 - (ess_free_decide__q + 0)
generate std_e21 = 5 - (ess_week_bored__q + 0)
generate std_e19 = (ess_week_absorbed__q + 0)
generate std_e35 = (ess_chance_to_learn__q + 0)
generate std_e39 = (ess_recognition__q + 0)
generate std_e40 = 6 - (ess_do_valuable__q + 0)
generate std_e33 = (num_e33 + 0)
generate std_e34 = 6 - (num_e34 + 0)
generate std_c2 = (social_meeting__q + 0)
generate std_e43 = 6 - (ess_cared_for__q + 0)
generate std_c3 = (close_friend__q + 1)
generate std_e12 = 5 - (ess_week_lonely__q + 0)
generate std_e36 = (ess_local_help__q + 0)
generate std_e37 = (ess_respected__q + 0)
generate std_e45 = 6 - (ess_close_local__q + 0)
generate std_e38 = 6 - (ess_unfairly_treated__q + 0)
generate std_a8 = (ess_trust__q + 0)
generate std_e48 = (ess_job_satisfaction__q + 0)
generate std_e49 = (ess_work_life_balance__q + 0)
generate std_e50 = (ess_job_interesting__q + 0)
generate std_e51 = 6 - (ess_job_stressful__q + 0)
generate std_e52 = (ess_unemployment_likelihood__q + 0)
generate std_e53 = 6 - (ess_paid_appropriately__q + 0)

zscore std_c1 std_e11 std_e13 std_e8 std_e14 std_b24 std_e31 std_e32 std_e7 std_e18 std_e9 std_e15 std_e10 std_e16 std_e22 std_c15 std_e30 std_e5 std_e6 std_e4 std_e29 std_e25 std_e27 std_e24 std_e23 std_e21 std_e19 std_e35 std_e39 std_e40 std_e33 std_e34 std_c2 std_e43 std_c3 std_e12 std_e36 std_e37 std_e45 std_e38 std_a8 std_e48 std_e49 std_e50 std_e51 std_e52 std_e53, stub(z_)

replace z_std_e33 = 0 if ess_family_time_enjoyable__q == "na"
replace z_std_e34 = 0 if ess_family_time_stressful__q == "na"

generate esswb_positive_feelings = (z_std_c1 + z_std_e11 + z_std_e13) / 3
generate esswb_absence_of_negative_feelin = (z_std_e8 + z_std_e14) / 2
generate esswb_self_esteem = (z_std_e5 + z_std_e6) / 2
generate esswb_optimism = (z_std_e4) / 1
generate esswb_resilience = (z_std_e29) / 1
generate esswb_competence = (z_std_e25 + z_std_e27) / 2
generate esswb_autonomy = (z_std_e24 + z_std_e23) / 2
generate esswb_engagement = (z_std_e21 + z_std_e19 + z_std_e35) / 3
generate esswb_meaning_and_purpose = (z_std_e39 + z_std_e40) / 2
generate esswb_emotional_wellbeing = (esswb_positive_feelings + esswb_absence_of_negative_feelin) / 2
generate esswb_satisfying_life = (z_std_b24 + z_std_e31 + z_std_e32 + z_std_e7) / 4
generate esswb_vitality = (z_std_e18 + z_std_e9 + z_std_e15 + z_std_e10 + z_std_e16 + z_std_e22 + z_std_c15 + z_std_e30) / 8
generate esswb_resilience_and_self_esteem = (esswb_self_esteem + esswb_optimism + esswb_resilience) / 3
generate esswb_positive_functioning = (esswb_competence + esswb_autonomy + esswb_engagement + esswb_meaning_and_purpose) / 4
generate esswb_supportive_relationships = (z_std_e33 + z_std_e34 + z_std_c2 + z_std_e43 + z_std_c3 + z_std_e12) / 6
generate esswb_trust_and_belonging = (z_std_e36 + z_std_e37 + z_std_e45 + z_std_e38 + z_std_a8) / 5
generate esswb_personal = (esswb_emotional_wellbeing + esswb_satisfying_life + esswb_vitality + esswb_resilience_and_self_esteem + esswb_positive_functioning) / 5
generate esswb_social = (esswb_supportive_relationships + esswb_trust_and_belonging) / 2
generate esswb_personal_and_social = (esswb_personal + esswb_social) / 2
generate esswb_work = (z_std_e48 + z_std_e49 + z_std_e50 + z_std_e51 + z_std_e52 + z_std_e53) / 6

* }

* General unpacking {

gen esswb_all_weighted = ((esswb_personal * 2) + esswb_social) / 3

*** platform

gen platform = ""
replace platform = "linux" if regexm(user_agent, "Linux")
replace platform = "mac" if regexm(user_agent, "Mac")
replace platform = "win" if regexm(user_agent, "Windows")
replace platform = "iphone" if regexm(user_agent, "iPhone")

gen non_win = platform != "win"


*** nat rel

* reverse score nat_rel questions 
* reverse scored items are: 2, 3, 10, 11, 13, 14, 15, 18
* which are: na, na, nat_rel_rarely_in_nature__q, na, nat_rel_woods_scary__q, nat_rel_nature_no_effect__q, na, na

gen nat_rel_rarely_in_nature_rev = 6 - nat_rel_rarely_in_nature__q
gen nat_rel_woods_scary_rev = 6 - nat_rel_woods_scary__q
gen nat_rel_nature_no_effect_rev = 6 - nat_rel_nature_no_effect__q

* nr_self items are: 5, 7, 8, 12, 14, 16, 17, 21
* which are: nat_rel_think_environment__q nat_rel_spiritual_part__q nat_rel_env_aware__q nat_rel_not_separate__q 
*   nat_rel_nature_no_effect_rev nat_rel_notice_city_nature__q nat_rel_identity__q nat_rel_connectedness__q

* nr_experience items are: 1, 4, 6, 9, 10, 13
* which are: nat_rel_enjoy_outdoors__q nat_rel_wild_vacation__q nat_rel_digger__q nat_rel_notice_wildlife__q 
*   nat_rel_rarely_in_nature_rev nat_rel_woods_scary_rev

* nat_rel_think_suffering__q is the only nr_perspective item

gen nr_self = (nat_rel_think_environment__q + nat_rel_spiritual_part__q + nat_rel_env_aware__q + nat_rel_not_separate__q + ///
	nat_rel_nature_no_effect_rev + nat_rel_notice_city_nature__q + nat_rel_identity__q + nat_rel_connectedness__q) / 8

gen nr_experience = (nat_rel_enjoy_outdoors__q + nat_rel_wild_vacation__q + nat_rel_digger__q + nat_rel_notice_wildlife__q + ///
	nat_rel_rarely_in_nature_rev + nat_rel_woods_scary_rev) / 6

gen nr = nr_self + nr_experience


*** accommodation

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

gen own_garden = garden__q == "own"
replace own_garden = . if missing(garden__q)

gen dblglazing = .
replace dblglazing = 0 if double_glazing__q == "none"
replace dblglazing = 1 if double_glazing__q == "some"
replace dblglazing = 2 if double_glazing__q == "all"

gen nodblglazing = !dblglazing

gen num_house_problems = housing_problems__q_mould + housing_problems__q_cold + housing_problems__q_insects


*** location

gen other_pc_valid = other_pc_std != ""
gen other_loc_valid = inlist(other_map_status__q, "confirmed", "approximate") & other_map_location__q != ""
gen other_loc_zoom = regexs(1) if regexm(other_map_location__q, ",([0-9]+)$")

gen airnoise012 = 3 - aircraft_noise__q  
gen rrnoise012 = 3 - road_rail_noise__q
gen airpoll012 = 3 - air_pollution__q
gen crime012 = 3 - crime__q

gen inner_london = regexm(quota_class, "inner_london")


*** health

gen poor_health = self_reported_health__q < 3
replace poor_health = . if missing(self_reported_health__q)
gen good_health = self_reported_health__q > 3
replace good_health = . if missing(self_reported_health__q)


*** demographics

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

gen child_under_2 = any_children__q != 0 & (child_of_age__q == "0" | children_of_ages__q_0)
gen child_under_5 = any_children__q != 0 & (child_of_age__q == "0" | child_of_age__q == "2" | children_of_ages__q_0 | children_of_ages__q_2)
gen child_under_16 = any_children__q != 0 & (child_of_age__q == "0" | child_of_age__q == "2" | child_of_age__q == "5" | child_of_age__q == "11" | ///
	children_of_ages__q_0 | children_of_ages__q_2 | children_of_ages__q_5 | children_of_ages__q_11)
gen child_under_21 = any_children__q != 0 & (child_of_age__q == "0" | child_of_age__q == "2" | child_of_age__q == "5" | child_of_age__q == "11" | child_of_age__q == "16" | ///
	children_of_ages__q_0 | children_of_ages__q_2 | children_of_ages__q_5 | children_of_ages__q_11 | children_of_ages__q_16)

gen two_kids_plus = any_children__q == 2
replace two_kids_plus = . if missing(any_children__q) 
gen single_parent = any_children__q != 0 & household_sixteen_plus__q == 1
replace single_parent = . if missing(any_children__q, household_sixteen_plus__q) 

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


gen long_hours_normal = work_hours_forty_eight__q == 4 | work_hours_forty_eight__q == 5

gen desk = job_activity__q_desk == 1
gen computer = job_activity__q_computer == 1
gen outside = job_activity__q_outside == 1
gen communicating = job_activity__q_communicating == 1
gen active = job_activity__q_active == 1
gen travelling = job_activity__q_travelling == 1

gen v_long_commute = commute_time__q == 80 /* one hour+ */
gen long_commute = commute_time__q == 60 | commute_time__q == 80 /* 45 mins+ */

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

gen only_child = sisters__q == 0 & brothers__q == 0
replace only_child = . if missing(sisters__q, brothers__q)
gen two_sibs_plus = (sisters__q != 0 & brothers__q != 0) | sisters__q == 2 | brothers__q == 2
replace two_sibs_plus = . if missing(sisters__q, brothers__q)
gen eldest_child = !only_child & (birth_pos_two__q == "oldest" | birth_pos_many__q == "oldest")
gen only_or_eldest = only_child | eldest_child
gen sisters = sisters__q != 0
replace two_sibs_plus = . if missing(sisters__q)

*** time
gen weekend = (start_time_days_since_sunday == 0 | start_time_days_since_sunday == 6)


*** other

gen groupie = clubs_groups_etc__q < 3
replace groupie = . if missing(clubs_groups_etc__q)
gen meditator = meditation__q > 2
replace meditator = . if missing(meditation__q)

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

gen on_period = period__q == "on"
replace on_period = . if period__q == "refused"

gen pregnant = pregnant__q == "1"
replace pregnant = . if pregnant__q == "refused"

gen ln_sleep_last_night = ln(sleep_last_night__q)
gen ln_sleep_got = ln(sleep_got__q)

gen slept_lt_6h_last_night = sleep_last_night__q < 6
replace slept_lt_6h_last_night = . if missing(sleep_last_night__q)
gen sleeps_lt_6h = sleep_got__q < 6
replace sleeps_lt_6h = . if missing(sleep_got__q)

* }

* Spatial variable derivatives {

foreach loc in home other {
  gen `loc'_lsoa_popdens = home_lsoa_pop / home_lsoa_area * 1000000
  
  gen `loc'_aod_01 = .
  replace `loc'_aod_01 = 1 if `loc'_aod == "t"
  replace `loc'_aod_01 = 0 if `loc'_aod == "f"
  
  gen `loc'_tube_or_station_dist  = min(`loc'_tube_dist, `loc'_station_dist)
  
  foreach thing in z1 z1tube tube mway railway station coast river tube_or_station {
    capture drop ln_`loc'_`thing'_dist
    gen  ln_`loc'_`thing'_dist = `loc'_`thing'_dist
  }
  
  gen `loc'_rb_per_khh = (`loc'_rb  * 1000) / `loc'_lsoa_hh_count
  gen `loc'_vap_per_kp = (`loc'_vap * 1000) / `loc'_lsoa_pop
  gen `loc'_tno_per_kp = (`loc'_tno * 1000) / `loc'_lsoa_pop
  
  gen `loc'_road_quiet  = `loc'_noise_road_lden == 2
  gen `loc'_rail_quiet  = `loc'_noise_rail_lden == 2
  gen `loc'_lhr09_quiet = `loc'_lhr09_leq == 0
  
  gen `loc'_road_quietish  = `loc'_noise_road_lden <= 3
  gen `loc'_rail_quietish  = `loc'_noise_rail_lden <=3
  gen `loc'_lhr09_quietish = `loc'_lhr09_leq <= 1
  
  foreach lcm in coast water mountain grassland farmland woodland suburban inlandbare {
    replace `loc'_`lcm'_lsoaprop = 0 if missing(`loc'_`lcm'_lsoaprop)
  }
}

foreach lcm in coast water mountain grassland farmland woodland suburban inlandbare {
  gen ln_home_`lcm'_sd1000 = ln(home_`lcm'_sd1000 + 1)
}

foreach lcmsuffix in r200 r1000 r3000 r10000 {
  gen home_greens_`lcmsuffix' = home_mountain_`lcmsuffix' + home_grassland_`lcmsuffix' + home_farmland_`lcmsuffix' + home_woodland_`lcmsuffix' 
}

* weather
gen sunny = weather_code == 1
replace sunny = . if missing(weather_code) | weather_code == 99

* interactions
gen home_road_noise_x_nodblglaz = home_noise_road_lden * nodblglazing

* }

save "$phddatadir/london_data_for_analsis.dta", replace

