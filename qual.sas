/*t_����*/
%macro t_test(equal=T);
%if &equal=T %then 
%put &str ʹ�õ���T����(������);
%else %put &str ʹ�õ��ǵ�����T����;
proc ttest data=&ds;
class &grp ;
var &str ;
ods output ttests=t_&q_id(where=(variances=%if &equal=T %then "����";%else "������";) 
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
/*�������*/
%macro ftest();
%put &str ʹ�õ��Ƿ��������;
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
/*�ǲ�������*/
%macro npar(type);
proc npar1way data=&ds wilcoxon;
class &grp ;
var &str ;
%if &n_level_grp=2 %then %do;
%put &str ʹ�õ���Wilcoxon���飡;
ods output wilcoxonTest=&type._npar_&&&type._id (keep=Prob2 );
ods select wilcoxonTest ;
%end;
%else %do;
%put &str ʹ�õ��� Kruskal-Wallis ���飡;
ods output KruskalWallisTest=&type._npar_&&&type._id (keep=prob );
ods select KruskalWallisTest;
%end;
run;
ods output close;
%if &n_level_grp=2 %then %do;
	%if %sysfunc(find(&sysvlong,M6)) %then %do;
		data &type._npar_&&&type._id;
		set &type._npar_&&&type._id;
		pvalue=put(prob2,6.4);
		drop prob2;
		run;
	%end;
	%else %do;
		data &type._npar_&&&type._id;
		set &type._npar_&&&type._id;
		if _n_ ne 6 then delete;
		pvalue=put(cvalue1,6.4);
		keep pvalue;
		run;
		%end;
	%end;
%else 
	%do;
	data &type._npar_&&&type._id;
	set &type._npar_&&&type._id;
	pvalue=put(prob,6.4);
	drop prob;
	run;	
	%end;
%if &type=q %then %data_merge(qal_&q_id,desc_&q_id,q_npar_&q_id); 
%else %data_merge(cat_&cat_id,freq_table_&cat_id,cat_npar_&cat_id);
%mend;
