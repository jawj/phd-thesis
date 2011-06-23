
set more off
set notifyuser on
clear
clear matrix
clear mata
set mem 3000m
use "s:\all_data_2011_03_10.dta"

gen feel_hpy_100 = feel_hpy * 100

gen response_seqsq = response_seq * response_seq

gen rseq_0   = response_seq ==   0
gen rseq_10  = response_seq >=   1 & response_seq <=  10
gen rseq_50  = response_seq >=  11 & response_seq <=  50
gen rseq_100 = response_seq >=  51 & response_seq <= 100
gen rseq_500 = response_seq >= 101 & response_seq <= 500
gen rseq_mny = response_seq >= 501

gen indoors  = place == "in"
replace indoors = . if missing(place)
gen outdoors = place == "out"
replace outdoors = . if missing(place)
gen vehicle  = place == "vehicle"
replace vehicle = . if missing(place)

encode place, gen(in_out_vehicle)

gen vol_av50_in  = vol_ave_50 * indoors
gen vol_av50_out = vol_ave_50 * outdoors
gen vol_av50_veh = vol_ave_50 * vehicle 

gen vol_pk90_in  = vol_pk_90 * indoors
gen vol_pk90_out = vol_pk_90 * outdoors
gen vol_pk90_veh = vol_pk_90 * vehicle

gen at_home     =  place2 == "home"
replace at_home = . if missing(place2)
gen at_work     =  place2 == "work"
replace at_work = . if missing(place2)
gen elsewhere   =  place2 == "other"
replace elsewhere = . if missing(place2)

encode place2, gen(home_work_other)

gen weekday = inlist(day_of_week, 1, 2, 3, 4, 5)
gen weekend = inlist(day_of_week, 6, 7)

gen hoursq = hour * hour
gen weekdayhour = hour * weekday
gen weekdayhoursq = hoursq * weekday
gen weekendhour = hour * weekend
gen weekendhoursq = hoursq * weekend

forvalues h = 0(3)21 {
  gen wkdayhour_`h' = weekday & hour >= `h' & hour < `h' + 3
  gen wkendhour_`h' = weekend & hour >= `h' & hour < `h' + 3
}

egen num_activities = rowtotal(do_*)
 // drop if num_activities == 0 | num_activities > 12  // either missing data from interruption, or crazy combos

egen num_company_types = rowtotal(with_*)

encode device, gen(device_enc)
encode sound, gen(beep_sound)

gen lct_marine   = inlist(lcm_dn, 221, 201, 211, 212, 181, 191) 
gen lct_watery   = inlist(lcm_dn, 131, 111)
gen lct_mountain = inlist(lcm_dn, 121, 101, 102, 151, 91)
gen lct_grassy   = inlist(lcm_dn, 61, 71, 81)
gen lct_farmland = inlist(lcm_dn, 41, 42, 43, 51, 52)
 // gen lct_conifers = inlist(lcm_dn, 21)
 // gen lct_woody    = inlist(lcm_dn, 11)
gen lct_allwood  = inlist(lcm_dn, 11, 21)
gen lct_bare     = inlist(lcm_dn, 161)
gen lct_suburb   = lcm_dn == 171
gen lct_conturb  = lcm_dn == 172

foreach v in rural aonb natpark nnr {
  gen `v'_enc = .
  replace `v'_enc = 0 if `v' == "f"
  replace `v'_enc = 1 if `v' == "t"
}

foreach v in rural_enc aonb_enc natpark_enc nnr_enc {  
  gen `v'_in = `v' * indoors
  gen `v'_veh = `v' * vehicle
  gen `v'_out = `v' * outdoors
}

foreach suffix in marine watery mountain grassy farmland allwood bare suburb conturb {
  replace lct_`suffix' = . if missing(lcm_dn)
  gen lctin_`suffix'  = lct_`suffix' * indoors
  gen lctveh_`suffix' = lct_`suffix' * vehicle
  gen lctout_`suffix' = lct_`suffix' * outdoors
}

foreach v of varlist lctout_* {
  gen r`v' = `v' * rural_enc
  gen u`v' = `v' * (1 - rural_enc)
}

replace windspeed = . if windspeed > 100

gen snow = strmatch(conditions, "*Snow*")

gen sunny = clear * is_daylight
gen tempK = temp + 273.15
gen tempKsq = tempK * tempK
gen windspeedsq = windspeed * windspeed

gen b_temp_0  =              temp <  0 if ! missing(temp)
gen   temp_8  = temp >=  0 & temp <  8 if ! missing(temp)
gen   temp_16 = temp >=  8 & temp < 16 if ! missing(temp)
gen   temp_24 = temp >= 16 & temp < 24 if ! missing(temp)
gen   temp_hi = temp >= 24             if ! missing(temp)

gen b_wind_5  =                   windspeed <  5 if ! missing(windspeed)
gen   wind_15 = windspeed >=  5 & windspeed < 15 if ! missing(windspeed)
gen   wind_25 = windspeed >= 15 & windspeed < 25 if ! missing(windspeed)
gen   wind_hi = windspeed >= 25                  if ! missing(windspeed)

foreach v of varlist is_daylight sunny rain fog snow temp_* b_temp_0 wind_* b_wind_5 windspeed windspeedsq tempK tempKsq {
  gen `v'_out = `v' * outdoors
}

replace rel = 1 if mrg == "mrd"

gen age = 2010 - born
gen agesq = age * age
encode work, gen(work_enc)
encode mrg, gen(mrg_enc)

gen singleparent = kids > 0 & adults < 2

gen hhsizefactor = sqrt(adults + (0.7 * kids))

gen hhinc_orig = hhinc
replace hhinc = . if hhinc < 0
gen hhinck = hhinc * 1000
gen lnhhinck = ln(hhinck)
gen lnpcinck = ln(hhinck / hhsizefactor)

gen incchangeup_orig = incchangeup
gen incchangedown_orig = incchangedown
replace incchangeup = . if incchangeup < 0
replace incchangedown = . if incchangedown < 0
gen hhinccchangeupk = incchangeup * 1000
gen hhinccchangedownk = incchangedown * 1000
gen lnhhinccchangeupk = ln(hhinccchangeupk)
gen lnhhinccchangedownk = ln(hhinccchangedownk)
gen lnpcinccchangeupk = ln(hhinccchangeupk / hhsizefactor)
gen lnpcinccchangedownk = ln(hhinccchangedownk / hhsizefactor)

replace lnpcinccchangedownk = 0 if missing(lnpcinccchangedownk) & ! missing(lnpcinccchangeupk)
replace lnpcinccchangeupk   = 0 if missing(lnpcinccchangeupk)   & ! missing(lnpcinccchangedownk)

gen lnpcincchange = lnpcinccchangeupk - lnpcinccchangedownk

* baselines
foreach v in  lct_conturb lctout_conturb wkdayhour_6 {
  rename `v' b_`v'
}

save "s:\all_data_2011_06_15_augmented.dta", replace   // all activity counts kept
