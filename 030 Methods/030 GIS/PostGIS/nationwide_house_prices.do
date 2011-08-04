set mem 2g
set more off


-- Import NSPD

clear
insheet using "/Users/George/GIS/Data/Borders, boundaries, codes/NSPDF_AUG_2010_UK_1M_FP.csv", comma
save "/Users/George/GIS/Data/Borders, boundaries, codes/NSPDF_AUG_2010_UK_1M_FP.dta"


-- Process NSPD

keep v2 v44 v45 v46 v50
rename v2 postcode
rename v44 lsoa
rename v45 dzone
rename v46 msoa
rename v50 izone

gen lsoa_dzone = lsoa
replace lsoa_dzone = dzone if lsoa_dzone == "" | lsoa_dzone == "Z99999999"
replace lsoa_dzone = "" if lsoa_dzone == "Z99999999"

gen msoa_izone = msoa
replace msoa_izone = izone if msoa_izone == "" | msoa_izone == "Z99999999"
replace msoa_izone = "" if msoa_izone == "Z99999999"

save "/Users/George/GIS/Data/Borders, boundaries, codes/lsoa_msoa_dzone_izone.dta"


-- Load house prices

clear
cd "/Users/George/GIS/Data/Social/House prices/NATIONWIDE"
append using dmz9504a dmz9505a dmz9506a dmz9507a dmz9508a dmz9509a dmz9510a dmz9511a dmz9512a dmz9601a dmz9602a dmz9603a dmz9604a dmz9605a dmz9606a dmz9607a dmz9608a dmz9609a dmz9610a dmz9611a dmz9612a dmz9701a dmz9702a dmz9703a dmz9704a dmz9705a dmz9706a dmz9707a dmz9708a dmz9709a dmz9710a dmz9711a dmz9712a dmz9801a dmz9802a dmz9803a dmz9804a dmz9805a dmz9806a dmz9807a dmz9808a dmz9809a dmz9810a dmz9811a dmz9812a dmz9901a dmz9902a dmz9903a dmz9904a dmz9905a dmz9906a dmz9907a dmz9908a dmz9909a dmz9910a dmz9911a dmz9912a dmz0001a dmz0002a dmz0003a dmz0004a dmz0005a dmz0006a dmz0007a dmz0008a dmz0009a dmz0010a dmz0011a dmz0012a dmz0101a dmz0102a dmz0103a dmz0104a dmz0105a dmz0106a dmz0107a dmz0108a dmz0109a dmz0110a dmz0111a dmz0112a dmz0201a dmz0202a dmz0203a dmz0204a dmz0205a dmz0206a dmz0207a dmz0208a dmz0209a dmz0210a dmz0211a dmz0212a dmz0301a dmz0302a dmz0303a dmz0304a dmz0305a dmz0306a dmz0307a dmz0308a dmz0309a dmz0310a dmz0311a dmz0312a dmz0401a dmz0402a dmz0403a dmz0404a dmz0405a dmz0406a, generate(month)
save "gm_all.dta"


-- Merge

merge m:1 postcode using "/Users/George/GIS/Data/Borders, boundaries, codes/lsoa_msoa_dzone_izone.dta", keep(match master)
duplicates report lsoa_dzone if lsoa_dzone != ""
duplicates report msoa_izone if msoa_izone != ""

save "gm_all_with_soas.dta"


-- Regress

gen floormsq = .
replace floormsq = floorsz if floormea == "M"
replace floormsq = 0.09290304 * floorsz if floormea == "F"

gen lnfloormsq = ln(floormsq)

recode dtbuilt (0/1399 = .) (1400/1799 = 0) (1800/1849 = 1) (1850/1899 = 2) (1900/1924 = 3) (1925/1949 = 4) (1950/1974 = 5) (1975/1999 = 6) (2000/2050 = 7), gen(build_date_code)

gen sale_qtr_code = floor((month - 1) / 3)

encode lsoa_dzone, gen(lsoa_dzone_code)
encode newprop, gen(newprop_code)

xtset lsoa_dzone_code

#delimit ;
xtreg lnprice 
lnfloormsq i.bedrooms i.bathroom
i.garage i.central i.tenure
i.security i.newprop_code i.build_date_code i.sale_qtr_code 
if bedrooms > 0 & bedrooms < 7
 & bathroom > 0
 & garage > 0 & central < 9
, fe vce(robust);
#delimit cr

predict house_price_lsoa_fe, u

keep lsoa_dzone house_price_lsoa_fe
duplicates drop
drop if missing(lsoa_dzone, house_price_lsoa_fe)

set scheme s1mono
hist house_price_lsoa_fe, width(0.05) xtitle("LSOA/Data Zone house price fixed effects (ln(£))")

save "/Users/George/GIS/Data/Social/House prices/NATIONWIDE/lsoa_price_fes.dta", replace
outsheet using "/Users/George/GIS/Data/Social/House prices/NATIONWIDE/lsoa_price_fes.csv", comma replace

