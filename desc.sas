
/********************************************************************/
/* macor: DESC                                                                       */
/* 用途：定量变量基线描述                                                        */
/* 参数说明：                                                                           */
/* 必填参数:                                                                              */
/* data:         分析的数据集                                                        */
/* group:       分组变量，一次只能输入一个                                 */
/* var :           将要分析的定量变量，可以一次性输入多个              */
/* 可选参数:                                                                               */
/*	ylabel:        分组变量标签                                                        */
/*********************************************************************/
%macro  desc(data=,var=,group=,ylabel=);
proc sql noprint;
select count(distinct &group) into :nlevel from &data;
select distinct &group into :gvalue separated by " "  from &data;
select count(&group) into :ngroup separated by " " from &data group by &group ; 
quit;

%let i=1;
%let str=%scan(&var,&i);
%do %while(&str ne);
ods output table=table&i ;
proc tabulate data=&data ;
class &group ;
var &str ;
tables  &str *(n nmiss mean std min max lclm uclm median  p25 p75 ), &group ;
run; 
ods output close;

/*合并指标*/
%macro hebing(str);
	&str._nn=compress(cat(put(&str._n,8.2),'(',put(&str._NMiss,8.2),')'));
	&str._ms=compress(cat(put(&str._mean,8.2),'±',put(&str._std,8.2)));
    &str._mm=compress(cat(put(&str._min,8.2), '-',put(&str._max,8.2)));
	&str._mp=compress(cat(put(&str._median,8.2),'(',put(&str._p25,8.2),'-',put(&str._p75,8.2),')'));
	drop &str._n &str._mean &str._min &str._median &str._nmiss &str._std &str._max &str._p25 &str._p75 &str._lclm  &str._uclm;
	drop &group  _type_   _page_   _table_;
%mend;

data table&i;
set table&i ;
%hebing(&str );
run;

proc transpose data=table&i out=table&i.1 prefix=level;
var _all_;
run;

proc sql;
insert into table&i.1
set level1="";
quit;

%macro lg();
%do num=1 %to &nlevel;
level&num=lag(level&num);
%end;
%mend;

data table&i.2 ;
length _name_ $15;
set table&i.1 ;
%lg();
_name_=scan(_name_,1,"_");
if _n_=2 then _name_='N(MISS)';
if _n_=3 then _name_='Mean±SD';
if _n_=4 then _name_='Min-Max';
if _n_=5 then _name_='Median(IQR)';
if _n_>1 then do;
	_name_=right(_name_);
end;
label _name_='指标';
rename _name_=variable;
run;

%macro addlabel(ylabel);
%if &ylabel ne %then %do;
%do x=1 %to &nlevel;
label level&x=%scan(&ylabel,&x)'(N='%scan(&ngroup,&x)')';
%end;
%end;
%else %do;
%do x=1 %to &nlevel;
label level&x=%scan(&gvalue,&x)'(N='%scan(&ngroup,&x)')';
%end;
%end;
%mend;

data table&i.2;
set table&i.2;
%addlabel(&ylabel); 
run;

%if %eval(&i) >1 %then %do;
	%let j=%eval(&i-1);
	proc append base=table12 data=table&i.2 force;
	run;
	proc sql noprint;
	drop table  table&i  , table&i.1,table&i.2 , table11;
	quit;
	%symdel j/nowarn ;
%end;

%let i=%eval(&i+1);
%let str=%scan(&var,&i);
%end;

data finalfreq;
set table12 ;
run;
proc sql noprint;
drop table table12,table1 ;
quit;
%symdel i a/ nowarn;
%mend;

/*例子*/
%desc(data=zhenjiu.desc,group=gender,var=age weight);

