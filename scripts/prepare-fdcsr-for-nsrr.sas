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
  %let version = 0.1.0.pre;

  *set nsrr csv release path;
  %let releasepath = \\rfawin.partners.org\bwh-sleepepi-nsrr-staging\20230418-klerman-fdcsr\nsrr-prep\_releases;

*******************************************************************************;
* create dataset ;
*******************************************************************************;
  *import source spreadsheet;
  proc import datafile="\\rfawin.partners.org\bwh-sleepepi-nsrr-staging\20230418-klerman-fdcsr\nsrr-prep\_source\FD-info_nsrr 2023a.xls"
    out=fdcsr_in
    dbms=csv
    replace;
  run;

*******************************************************************************;
* create harmonized dataset ;
*******************************************************************************;


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
