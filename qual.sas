/*t_检验*/
%macro t_test(equal=T);
%if &equal=T %then 
%put &str 使用的是T检验(方差齐);
%else %put &str 使用的是调整后T检验;
proc ttest data=&ds;
class &grp ;
var &str ;
ods output ttests=t_&q_id(where=(variances=%if &equal=T %then "等于";%else "不等于";) 
					  		keep=variances probt);
ods select ttests;
run;
ods output close;
data t_&q_id ;
set t_&q_id ;
drop varicances;
pvalue=put(probt,6.4);
drop probt ;
run;
%data_merge(qal_&q_id,freq_table_&q_id,t_&q_id);
%mend;
/*方差分析*/
%macro ftest();
%put &str 使用的是方差分析！;
proc glm data=&ds;
class &grp ;
model &str = &grp;
ods output modelanova=ftest_&q_id(where=(HypothesisType=3) 
								 keep=HypothesisType probf 
								 );
ods select modelanova ;
quit;
ods output close;
data ftest_&q_id;
set ftest_&q_id (drop=HypothesisType);
pvalue=put(probf,6.4);
drop probf;
run;
%data_merge(qal_&q_id,desc_&q_id,ftest_&q_id);
%mend;
/*非参数检验*/
%macro npar(type);
%put &str 使用的是非参数检验！;
proc npar1way data=&ds wilcoxon;
class &grp ;
var &str ;
%if &n_level_grp=2 %then %do;
ods output wilcoxonTest=&type._npar_&&&type._id (keep=Prob2 );
ods select wilcoxonTest ;
%end;
%else %do;
ods output KruskalWallisTest=&type._npar_&&&type._id (keep=prob );
ods select KruskalWallisTest;
%end;
run;
ods output close;
%if &n_level_grp=2 %then %do;
	data &type._npar_&&&type._id;
	set &type._npar_&&&type._id;
	pvalue=put(prob2,6.4);
	drop prob2;
	run;
	%end;%else %do;
	data &type._npar_&&&type._id;
	set &type._npar_&&&type._id;
	pvalue=put(prob,6.4);
	drop prob;
	run;	
	%end;
%if &type=q %then %data_merge(qal_&q_id,desc_&q_id,q_npar_&q_id); 
%else %data_merge(cat_&cat_id,freq_table_&cat_id,cat_npar_&cat_id);

%mend;
