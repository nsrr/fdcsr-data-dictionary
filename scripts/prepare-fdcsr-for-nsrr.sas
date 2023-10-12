*******************************************************************************;
* Program           : prepare-fdcsr-for-nsrr.sas
* Project           : National Sleep Research Resource (sleepdata.org)
* Author            : Michael Rueschman (mnr)
* Date Created      : 20230607
* Purpose           : Prepare Forced Desynchrony with and without Chronic Sleep
*                       Restriction (FD-CSR) dataset.
*******************************************************************************;

*******************************************************************************;
* establish options and libnames ;
*******************************************************************************;
  options nofmterr;
  data _null_;
    call symput("sasfiledate",put(year("&sysdate"d),4.)||put(month("&sysdate"d),z2.)||put(day("&sysdate"d),z2.));
  run;

  *set data dictionary version;
  %let version = 0.1.0;

  *set nsrr csv release path;
  %let releasepath = \\rfawin.partners.org\bwh-sleepepi-nsrr-staging\20230418-klerman-fdcsr\nsrr-prep\_releases;

*******************************************************************************;
* create dataset ;
*******************************************************************************;
  *import source spreadsheet;
  proc import datafile="\\rfawin.partners.org\bwh-sleepepi-nsrr-staging\20230418-klerman-fdcsr\nsrr-prep\_source\FD-info_nsrr 2023a.xls"
    out=fdcsr_in
    dbms=xls
    replace;
  run;

  data fdcsr;
    set fdcsr_in;

    *only retain subjects for which data have been transferred;
  *  if subject in ("20A4DX","20C1DX","21A4DX","21B3DX","24B7GXT3","25R8GXT2",
      "26N2GXT2","26O2GXT2","27D9GX","27Q9GX","2065DX","2072DX","2150DX",
      "2173DX","2238DX","2760GXT2","2823GX","2844GX","3227GX","3228GX",
      "3232GX","3233GX","3237GX","3241GX63","3315GX32","3319GX","3335GX",
      "3339GX","3353GX","3411GX52","3433GX","3441GX","3450GX","3525GX",
      "3531GX","3540GX","3562GX61");

	     *only retain subjects in Oct23 release (GX);
    if subject in ("24B7GXT3","25R8GXT2",
      "26N2GXT2","26O2GXT2","27D9GX","27Q9GX","2760GXT2","2823GX","2844GX","3227GX","3228GX",
      "3232GX","3233GX","3237GX","3241GX63","3315GX32","3319GX","3335GX",
      "3339GX","3353GX","3411GX52","3433GX","3441GX","3450GX","3525GX",
      "3531GX","3540GX","3562GX61");

    *create placeholder visitnumber for Spout;
    visitnumber = 1;

    *create nsrr id variable;
	nsrrid=subject;

    *fix/clean variable names;
    rename 
      var7 = drug_placebo
      end_analysis_spn__included_ = end_analysis_spn
      ;

    *drop variables;
    drop
      hab_bed /* missing for all subjects */
      actigraphy_files_in_nsrr_
      sleep_files_in_nsrr_
      edf_files_in_nsrr_
      ;
  run;

*******************************************************************************;
* create harmonized dataset ;
*******************************************************************************;
data fdcsr_nsrr;
set fdcsr_in;

 if subject in ("24B7GXT3","25R8GXT2",
      "26N2GXT2","26O2GXT2","27D9GX","27Q9GX","2760GXT2","2823GX","2844GX","3227GX","3228GX",
      "3232GX","3233GX","3237GX","3241GX63","3315GX32","3319GX","3335GX",
      "3339GX","3353GX","3411GX52","3433GX","3441GX","3450GX","3525GX",
      "3531GX","3540GX","3562GX61");

*demographics
*age;
*use age;
  format nsrr_age 8.2;
  if age gt 89 then nsrr_age=90;
  else if age le 89 then nsrr_age = age;

*sex;
*use gender;
  format nsrr_sex $10.;
  if gender = "M" then nsrr_sex = 'male';
  else if gender = "F" then nsrr_sex = 'female';
  else if gender = . then nsrr_sex = 'not reported';

**add in ID so can merge;
  format id 8.2;
  nsrrid=subject;

  keep 
    nsrrid
    nsrr_age
    nsrr_sex
	;
run;

*******************************************************************************;
* checking harmonized datasets ;
*******************************************************************************;
/* Checking for extreme values for continuous variables */
proc means data=fdcsr_nsrr;
VAR   nsrr_age
      ;
run;

/* Checking categorical variables */
proc freq data=fdcsr_nsrr;
table   nsrr_sex;
run;

*******************************************************************************;
* make all variable names lowercase ;
*******************************************************************************;
  options mprint;
  %macro lowcase(dsn);
       %let dsid=%sysfunc(open(&dsn));
       %let num=%sysfunc(attrn(&dsid,nvars));
       %put &num;
       data &dsn;
             set &dsn(rename=(
          %do i = 1 %to &num;
          %let var&i=%sysfunc(varname(&dsid,&i));    /*function of varname returns the name of a SAS data set variable*/
          &&var&i=%sysfunc(lowcase(&&var&i))         /*rename all variables*/
          %end;));
          %let close=%sysfunc(close(&dsid));
    run;
  %mend lowcase;

  %lowcase(fdcsr);

*******************************************************************************;
* export nsrr csv datasets ;
*******************************************************************************;
  proc export data=fdcsr
    outfile="&releasepath\&version\fdcsr-dataset-&version..csv"
    dbms=csv
    replace;
  run;
  proc export
    data=fdcsr_nsrr	
	outfile="&releasepath\&version\fdcsr-harmonized-dataset-&version..csv"
    dbms=csv
    replace;
  run;
