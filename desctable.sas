


%macro desctable(data=,group=,var=,ylabel=,wtmk=,kwmk=,tmk=,tpmk=,fmk=,title='基线描述表',footnote=,filepath=,style=journal2a);

%statmeth(data=&data,group=&group,var=&var,wtmk=&wtmk ,kwmk=&kwmk,tmk=&tmk,tpmk=&tpmk,fmk=&fmk );
%desc(data=&data,group=&group,var=&var,ylabel=&ylabel );

data finaldesc;
merge finalfreq finalstat(keep=value prob);
label variable='指标';
run;

data final finaldesc;
set finaldesc;
if mod(_n_,5) ^=1 then do;
  varvalue=variable;
  variable="";
  end;
run;

data finaldesc;
merge finaldesc(keep=variable varvalue) finaldesc(drop=variable varvalue);
run;

%if &filepath ne %then %do;
ods rtf file= &filepath style=journal2a;
%end;
title &title;
proc sql ;
select variable, varvalue, from finaldesc;
quit;
footnote &foot ;
%if filepath ne %then %do;
ods rtf close;
%end;

proc sql noprint;
drop table finalstat,finalfreq;
quit;

%mend;

/*例子*/
/*libname zhenjiu "K:\work\针灸";*/

