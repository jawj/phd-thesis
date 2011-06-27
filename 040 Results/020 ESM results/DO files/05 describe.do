
set more off
set notifyuser on
clear
clear matrix
set mem 3000m
use "s:\all_data_2011_06_15_augmented.dta"


set scheme s1mono


* feelings

preserve
keep if valid

hist feel_hpy_100 if valid, width(2) xtitle("Happy: self-rating")
graph export "S:\happy_dist.ps", as(ps) replace

gen feel_rlx_100 = feel_rlx * 100
hist feel_rlx_100 if valid, width(2) xtitle("Relaxed: self-rating")
graph export "S:\relaxed_dist.ps", as(ps) replace

gen feel_awk_100 = feel_awk * 100
hist feel_awk_100 if valid, width(2) xtitle("Awake: self-rating")
graph export "S:\awake_dist.ps", as(ps) replace

restore

sum feel_hpy_100 if valid
sum feel_rlx_100 if valid
sum feel_awk_100 if valid


* beep settings

\a
\f '\t'
select 
  count(1) as c, 
  round(count(1) / 21947.0 * 100, 2) as p,
  beeps_not_before || ' -- ' || (beeps_not_after + interval '10 minutes') as t
from users u, xtreg_user_ids x 
where u.id = x.user_id 
group by t order by c desc;

select 
  count(beeps_per_day) as c,
  round(count(1) / 21947.0 * 100, 2) as p,
  beeps_per_day b
from users u, xtreg_user_ids x 
where u.id = x.user_id 
group by b order by c desc; 

select 
  count(beeps_sound) as c,
  round(count(1) / 21947.0 * 100, 2) as p,
  beeps_sound b
from users u, xtreg_user_ids x 
where u.id = x.user_id 
group by b order by c desc;


* response vars

set notifyuser off
#delimit ;
fsum 
  lctout_* b_lctout_conturb 
  do_*
  with_*
  at_home at_work elsewhere
  indoors vehicle outdoors
  rseq_0 rseq_10 rseq_50
  wkdayhour_* wkendhour_*
  is_daylight_out
  sunny_out rain_out snow_out fog_out b_temp_*_out temp_*_out b_wind_*_out wind_*_out 
  
if valid
,
  pctvar(*)
  stats(mean sum)
  format(%10.2f)
  decsum
  uselabel
;
#delimit cr

then, replace: 
^ *([^|]+) \| +[0-9]+ +([0-9.]+) +([0-9]+)\..*
$1\t$3\t$2


* in/out by season

foreach v in 10-08 10-09 10-10 10-11 10-12 11-01 11-02 {
  tab place if valid & regexm(_start, "^20`v'")
}


* alone
count if valid & ! with_partner & ! with_child & ! with_relative & ! with_peers & ! with_client & ! with_friend & ! with_other


* photos

tab pic_received if valid
tab pic_received if valid & indoors
tab pic_received if valid & outdoors
tab pic_received if valid & vehicle


* device

tab device
tab device if valid
encode device, generate(device_code)


* noise

count if valid & missing(vol_pk_90)
count if valid & missing(vol_pk_90) & (do_music | do_speech)

set scheme s1mono
hist vol_pk_90 if valid & vol_pk_90 > -70, width(2) xtitle("90th percentile peak volume (dB)") ylabel(#5)

count if valid & vol_pk_90 <= -70 


* demographics

preserve
keep if valid
duplicates drop user_id, force

gen incchange = .
replace incchange = 0 if missing(incchangeany)
replace incchange = incchangeup if !missing(incchangeup)
replace incchange = - incchangedown if !missing(incchangedown)
replace incchange = . if !missing(incchangedown) & !missing(incchangeup)

tab1 health asthma male mrg rel work adults kids hhinc incchange, missing

set scheme s1mono
hist ls, discrete frequency xtitle("Life satisfaction") ylabel(#10) xlabel(1(1)10)
hist born if born > 1900, discrete frequency xtitle("Year of birth") ylabel(#10) xlabel(1920(10)2000)

restore


* participation rate

select count(1) from users where created_at < '14-02-2011';
select count(distinct user_id) from esm_answer_sets e, users u where e.user_id = u.id and e.sent_beep_id is not null and u.created_at < '14-02-2011';


* response rate

\t
\a
\f ',' 
select user_id, xtreg_responses, num_active_beeps, active_beep_response_rate from xtreg_response_rates \g response_rates.csv

-- in R...

data = read.csv('/Users/gjm06/Desktop/response_rates.csv', header=FALSE)

hist(data[,4][data[,4] <= 1][data[,3] >= 10], breaks = 15, xlab = "Proportion of signals resulting in a valid response (participants signalled 10× or more)", main = NA, col = 'gray')

hist(data[,4][data[,4] <= 1][data[,3] >= 0], breaks = 15, xlab = "Proportion of signals resulting in a valid response (all participants with > 0 valid responses)", main = NA, col = 'gray')

