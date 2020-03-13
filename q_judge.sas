%macro q_judge();
%put 现在判断的定量变量是: &str ;
/*正态性判断*/
proc univariate data=&ds normal;
class &grp ;
var &str ;
ods output TestsForNormality=norm_&q_id (where=(testlab="W") keep= testlab pvalue);
ods select TestsForNormality;
run;
ods output close;
proc sql noprint;
select count(*) into :n_p from norm_&q_id where pvalue<0.05;
quit;
%if &n_p >=1 %then 
	%npar(q);
%else 
/*方差齐性分析*/
	%do;
		proc glm data=&ds ;
		class &grp ;
		model &str = &grp ;
		means &grp /hovtest;
		ods output hovftest=hov_&q_id;
		ods select hovftest;
		quit;
		ods output close;
		proc sql noprint;
		select count(*) into :n_h from hov_&q_id where probf<0.05;
		quit;
		%if &n_h = 0 and &n_level_grp =2 %then %ttest(equal=T) ;
		%else %if &n_h=0 and &n_level_grp > 2 %then %f_test();
		%else %if &n_level_grp=2 %then %ttest(equal=F);
		%else %if &n_level_grp>2 %then  %npar(q) ;
	%end;
%mend;
