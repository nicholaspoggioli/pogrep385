*** Interstate conflict data
*	Data: GIGA Sanctions Dataset (http://dx.doi.org/10.7802/1346)
*	Data published: 2012
*	Time coverage: 1990 - 2010
*	Source: GIGA German Institute of Global and Area Studies (https://datorium.gesis.org/xmlui/handle/10.7802/1346)
*	Downloaded: October 29, 2018 by Nicholas Poggioli (poggi005@umn.edu)
*	Code by: Nicholas Poggioli (poggi005@umn.edu)
***

***	IMPORT RAW DATA
import excel "C:\Dropbox\Peace&FDI\data\sanctions\GIGA_Sanctions_Data_Set_121127.xlsx", ///
	sheet("episodes dataset") firstrow case(lower) allstring clear
	
drop o	
	
***	FORMAT VARIABLES
format goals source n %20s
format source %20s

***	TRIM
foreach variable of varlist _all {
	replace `variable'=trim(`variable')
}

***	SEPARATE NESTED VARIABLES
split(timeframe), gen(timeframe) parse(-)

foreach variable of varlist maingoals measures {
	split(`variable'), gen(`variable') parse(,)
}

***	CREATE INDEX
gen id=_n
order id

***	CREATE INDICATOR VARIABLES
gen democ=(democratisation=="Y")

***	LABEL
label var code "unique sanction ID"
label var sender "sender of sanctions"
label var target "target of sanctions"
label var timeframe "year of sanction imposition to year of lifting, or ongoing as of 2010"
label var goals "sanctions goals stated in sender documents"
label var democratisation "was democratisation a goal?"
label var maingoals "GIGA interpretation of main sanctions goals"
label var measures "measures imposed"
label var eco "economic character of the measures"
label var multi "combination of senders"
label var intensity "formal intensity of sanctions"
label var gradualism "are measures gradually intensified?"
label var source "identity of information source used to create data"
label var n "comments"

label define yesno 1 "yes" 0 "no"
label values democ yesno

***	CREATE PANEL
rename (timeframe1 timeframe2) (year_start year_end)
replace year_end="" if year_end=="ongoing"

destring(year_start), replace
destring(year_end), replace

expand 2
sort id

gen duration=.
bysort id: replace duration=year_start if _n==1
by id: replace duration=year_end if _n==2

*	Drop duplicate obs of 1-year sanctions
sort id duration
gen rt_censor=(year_end==.)
label var rt_censor "=1 if sanctions ongoing at data creation in 2010"

replace duration=2010 if (year_end==. & duration==.)
replace year_end=2010 if year_end==.

by id: gen years=year_end-year_start
by id: drop if years==0 & _n==2

xtset id duration, y
tsfill

sort id duration
foreach variable in code years id sender target measures eco multi intensity ///
	maingoals1 maingoals2 maingoals3 maingoals4 measures1 measures2 measures3 ///
	measures4 measures5 measures6 democ rt_censor {
	by id: replace `variable'=`variable'[_n-1] if _n!=1
}

***	DROP UNNEEDED VARIABLES
drop code timeframe goals measures democratisation maingoals gradualism source ///
	n year_start year_end maingoals

***	TIDY
order id duration years sender target rt_censor						

***	LABEL
label var id "unique sanction episode id"
label var duration "years sanction active"
label var years "total years sanction active"
label var democ "was democratization a stated goal of sanction?"

***	SAVE
compress
save data\sanctions\sanctions-clean.dta













*END
