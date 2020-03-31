%macro show_miss/minoperator;
/*判断数据集是否存在*/
%let rc=%sysfunc(open(&data));
%if &rc=0 %then %do;
	%put 数据集不存在，请核对数据集名称;
	%goto exit ;
%end;
	%else %do;
	%let rc=%sysfunc(close(&rc));
	%end;;
/*获取数据集变量名,创建数据集*/
proc sql;
create table variables as
select name,type 
	from dictionary.columns 
		%if %sysfunc(countw(&data))>2 %then
			where libname=%upcase(%scan(&data,1,.)) and memname=%upcase(%scan(&data,2,.));
		%else 
			where libname="WORK" and memname="%upcase(&data)";;
/**/
quit;
proc sql noprint;
select name,type into :var_name separated by " ",:var_type separated by " " from variables;
quit;
/*判断要分析的变量*/
%if &all ne T %then %do;
	%if vars eq %then %do;
		%put 您选择了清洗部分变量，请指定Vars=以指定需要分析的变量!;
		%goto exit;
		%end;
	%else %do;
		%do i=1 %to %sysfunc(countw(&vars));
			%if !%scan(&vars,&i) in (&var_name) %then %do;
				%put %scan(&vars,&i) 不在数据集中，请核实;
				%goto exit;
			%end;
		%end;
		%let var_name=&vars ;
	%end;
%end;
%let n_var=%sysfunc(countw(&var_name));

proc sql noprint;
create table miss as 
select
%do i=1 %to %eval(&n_var-1);
	sum(%scan(&var_name,&i) is null) as nmiss_%scan(&var_name,&i),
	sum(%scan(&var_name,&i) is not null) as nomiss_%scan(&var_name,&i),
%end;
sum(%scan(&var_name,&n_var) is null) as nmiss_%scan(&var_name,&n_var),
sum(%scan(&var_name,&n_var) is not null) as nomiss_%scan(&var_name,&n_var) from &data;
quit;
%str(
data nmiss;
set miss;
array vars1(*) nmiss:;
do i=1 to dim(vars1);
	variables=vname(vars1(i));
	nmiss=vars1(i);
	keep variables nmiss;
	variables=substr(variables,index(variables,"_")+1,length(variables)-index(variables,"_"));
	output;
end;
run;
data nomiss;
set miss;
array vars(*) nomiss:;
do i=1 to dim(vars);
	variables=vname(vars(i));
	nomiss=vars(i);
	keep variables nomiss;
	variables=substr(variables,index(variables,"_")+1,length(variables)-index(variables,"_"));
	output;
end;
run;
data f_miss;
merge nmiss nomiss;
miss_per=round(nmiss/(nmiss+nomiss),0.01)*100;
run;
proc sort data=f_miss;
by variables;
run;
);
%exit:
%mend;
