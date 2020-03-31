%macro get_outlier/minoperator ; 
/*添加行号*/
data temp;
set &data;
N+1;
run;
/*对于使用标准差范围的变量*/
%if %length(&std)>0 %then %do;
%let nstd=%sysfunc(countw(&std));
%do i=1 %to &nstd;
	%let std_var=%scan(&std,&i);
	proc means data=&data mean std ;
	var &std_var;
	output out=&std_var(drop=_type_ _freq_) mean=mean std=std ;
	run;
	data _null_;
	set &std_var ;
	call symput('lower',mean-%sysevalf(&n_std)*std);
	call symput('upper',mean+%sysevalf(&n_std)*std);
	run;
	proc sql noprint;
	create table count_&std_var as
	select N,count(&std_var) as n_out_range from temp where &std_var not between &lower and &upper
	and &std_var is not null;
	run;
	select N,n_out_range into :rows separated by ",",:nout from count_&std_var;
	run;
	quit;
	data count_&std_var;
	set count_&std_var(drop=N);
	variables=symget('std_var');
	record=symget('rows');
	n_out_range=symget('nout');
	range=compress(round(&lower,0.01)||"~"||round(&upper,0.01));
	if _n_=1 then output;
	run;
%end;
%end;
/*对于使用四分位数的*/
%if %length(&iqr)>0 %then %do;
%let niqr=%sysfunc(countw(&iqr));
%do i=1 %to &niqr;
	%let iqr_var=%scan(&iqr,&i);
	proc means data=&data median qrange ;
	var &iqr_var;
	output out=&iqr_var(drop=_type_ _freq_) p50=median qrange=iqr ;
	run;
	data _null_;
	set &iqr_var ;
	call symput('lower',median-%sysevalf(&n_iqr)*iqr);
	call symput('upper',median+%sysevalf(&n_iqr)*iqr);
	run;
	proc sql noprint;
	create table count_&iqr_var as
	select N,count(&iqr_var) as n_out_range from temp where &iqr_var  not between &lower and &upper
	and &iqr_var is not null;
	run;
	select N,n_out_range into :rows separated by ",",:nout from count_&iqr_var;
	run;
	quit;
	data count_&iqr_var;
	set count_&iqr_var(drop=N);
	variables=symget('iqr_var');
	record=symget('rows');
	n_out_range=symget('nout');
	range=compress(round(symget('lower'),0.01)||"~"||round(symget('upper'),0.01));
	if _n_=1 then output;
	run;
%end;
%end;
/*自定义范围变量*/
%if %length(&user_range)>0  %then %do;
%let nuser_var=%sysfunc(countw(&user_range,|));
%do i=1 %to &nuser_var;
	%let item=%scan(&user_range,&i,|);
	%let user_var=%scan(&item,1,"\");
	%let var_range=%scan(&item,2,"\");
	%let lower=%scan(&var_range,1);
	%let upper=%scan(&var_range,2);
	proc sql noprint;
	create table count_&user_var as
	select N,count(&user_var) as n_out_range from temp where &user_var  not between &lower and &upper
	and &user_var is not null;
	run;
	select N,n_out_range into :rows separated by ",",:nout from count_&user_var;
	run;
	quit;
	data count_&user_var;
	set count_&user_var(drop=N);
	variables=symget('user_var');
	record=symget('rows');
	n_out_range=symget('nout');
	range=compress(round(symget('lower'),0.01)||"~"||round(symget('upper'),0.01));
	if _n_=1 then output;
	run;
%end;
%end;
%if %length(&c_range)>0 %then %do;
	%let nvar=%sysfunc(countw(&c_range,|));
	%do i=1 %to &nvar;
		%let item=%scan(&c_range,&i,|);
		%let c_var=%scan(&item,1,"\");
		%let c_var_range=%scan(&item,2,"\");
		data temp_&c_var;
		set temp;
		if compress(&c_var) not in (&c_var_range) and missing(&c_var)=0 then out=1;
		run;
		proc sql noprint;
		create table count_&c_var as
		select N,count(out) as n_out_range from temp_&c_var where out=1;
		run;
		select N,n_out_range into :rows separated by ",",:nout from count_&c_var;
		run;
		quit;
		data count_&c_var;
		set count_&c_var(drop=N);
		variables=symget('c_var');
		record=symget('rows');
		n_out_range=symget('nout');
		range= symget('c_var_range');
		if _n_=1 then output;
		run;
	%end;
%end;
data count;
length range $100;
set count_:;
run;
proc sort data=count;
by variables;
run;
%mend;
