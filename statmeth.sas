 
/********************************************************************/
/* macor: STATMETH                                                               */
/* 用途：定量变量基线描述                                                        */
/* 参数说明：                                                                           */
/* 必填参数:                                                                              */
/* data:         分析的数据集                                                        */
/* group:       分组变量，一次只能输入一个                                 */
/* var :           将要分析的定量变量，可以一次性输入多个              */
/* 可选参数:                                                                               */
/* wtmk:        两水平分组变量 wilcoxon统计量标记                      */
/* kwmk:       多水平Kruskal-Wallis检验统计量标记                      */
/* tmk:          2水平分组变量t检验标记                                         */
/* tpmk:        2水平分组变量t‘检验标记                                        */
/* fmk:          多水平分组变量方差分析标记                                  */
/*********************************************************************/

%macro statmeth(data=,group=,var=,wtmk='*' ,kwmk='*',tmk='',tpmk='',fmk='');
%if ^%sysfunc(exist(&data,data)) %then %goto exit;
proc sql noprint;
select count(distinct &group) into :nglevel from &data ;
create table finalstat 
(variable char(15),
value char,
prob char
);
quit;

%let nvar=1;
%let vstr=%scan(&var,1);
%do %while(&vstr ne);
/*判断正态性*/
ods output TestsForNormality=normality_&vstr (where=(TestLab='W') keep=varname pvalue testlab);
ods select TestsForNormality;
proc univariate data=&data normal;
class &group ;
var &vstr ;
run;
ods output close;

/*将正态p值传递给宏变量: pnorm*/
proc sql noprint;
select pvalue into :pnorm from normality_&vstr where pvalue<0.05 ;
quit;

/*如果存在p<0.05 跳转非参数检验*/
%if %symexist(pnorm) %then %goto npar;
 %else %do;
/*方差齐检验*/
ods output hovftest=hov_&vstr  (where=(ProbF>0 ) keep=Dependent ProbF) ;
ods select hovftest ;
proc glm data=&data ;
class &group ; 
model &vstr = &group ;
means &group /hovtest;
run;
quit;
ods output close;
%end;

/*将方差齐p值传递给宏变量: phov*/
proc sql noprint;
select probf into :phov from hov&nvar where probf<0.05 ;
quit;

%if %symexist(phov) %then %do;
	%if &nglevel>2 %then %goto npar;
		%else %goto tt ;
	%end;
    %else %do;
          %if &nglevel>2 %then %goto glmtest;
		  %else %goto tt ;
	 %end;
%goto next;
/* ttest过程*/
%tt:%if %symexist(phov) %then %do;
	 ods output ttests=tp_&vstr (where=(Variances='不等于') drop=method df);
     ods select ttests;
     proc ttest data=&data ;
     class &group ;
     var &vstr ;
     run;
     ods output close;
     data tp_&vstr ;
     set tp_&vstr  (drop=variances rename=(probt=prob tvalue=value ));
     run;
	 data tp_&vstr;
	 set tp_&vstr;
	 value1=compress(input(value,$7.)||&tpmk) ;
     drop value;
	 rename value1=value ;
     run;
     proc sql noprint;
     create table tp_&vstr._1  as
		select variable,value,prob from tp_&vstr ;
		drop table tp_&vstr ;
     run;
	 %end;
	 %else %do ;
     ods output ttests=t_&vstr (where=(Variances='等于') drop=method df);
    ods select ttests;
    proc ttest data=&data ;
    class &group ;
    var &vstr ;
    run;
    ods output close;
    data t_&vstr ;
    set t_&vstr  (drop=variances rename=(probt=prob tvalue=value ));
  	value1=compress(input(value,$7.)||&tmk) ;
     drop value;
	 rename value1=value;
     run;
     proc sql noprint;
     create table t_&vstr._1  as
		select variable,value,prob from t_&vstr ;
	drop table  t_&vstr;
     run;
	%end;
%goto next;
/*方差分析过程*/
 %glmttest: ods output overallanova=f_&vstr ( where=(source='模型')drop=df--ms rename=(dependent=variable));
				  ods select overallanova;
                  proc glm data=&data ;
                  class &group ;
                  model &vstr = &group ;
                  run;
                  quit;
                  ods output close;
                 data f_&vstr ;
                 set f_&vstr ;
                 drop source;
                 rename fvalue=value probf=prob ;
                 run;
				 data f_&vstr;
	             set f_&vstr;
	              value1=compress(input(value,$7.)||&fmk) ;
                  drop value;
	              rename value1=value ;
                  run;
                 proc sql noprint;
                 create table f_&vstr._1  as
		         select variable,value,prob from f_&vstr ;
				 drop table f_&vstr;
                 run;
%goto next;
/*非参数分析过程*/
%npar:%if &nglevel > 2 %then %do;
            ods output KruskalWallisTest=kw_&vstr ;
            ods select KruskalWallisTest ;
            proc npar1way data=&data wilcoxon;
            class &group ;
            var &vstr ;
           run;
           ods output close;
           data kw_&vstr;
           set kw_&vstr;
           if _n_=2 then delete;
           keep cvalue1;
           proc transpose data=kw_&vstr out=kw_&vstr ;
           var cvalue1;
           run;
           data kw_&vstr ;
           set kw_&vstr (rename=(_name_=variable col1=value col2=prob));
           if variable='cValue1' then variable=symget('vstr');
           run;
		   data kw_&vstr;
	       set kw_&vstr;
	      value1=compress(input(value,$7.)||&kwmk) ;
          drop value ;
	      rename value1=value ;
          run; 
          proc sql noprint;
         create table kw_&vstr._1  as
		 select variable,value,prob from kw_&vstr ;
		 drop table kw_&vstr;
          run;
	  %end;
	  %else %do;
            ods output wilcoxonTest=wt_&vstr (where=(Name1='Z_WIL' | Name1='P2_WIL') drop=label1);
			ods select  wilcoxonTest;
            proc npar1way data=&data wilcoxon;
            class &group ;
            var &vstr ;
           run;
           ods output close;
           data wt_&vstr ;
           set wt_&vstr ;
           drop nvalue1 variable name1;
           proc transpose data=wt_&vstr out=wt_&vstr ;
          var cvalue1;
           run;
          data wt_&vstr;
          set wt_&vstr (rename=(_name_=variable col1=value col2=prob));
		   if variable='cValue1' then variable=symget('vstr');
          run;
		   data wt_&vstr;
	       set wt_&vstr;
	       value1=compress(input(value,$7.)||&wtmk) ;
            drop value;
	        rename value1=value ;
            run;
            proc sql noprint;
            create table wt_&vstr._1  as
		    select variable,value,prob from wt_&vstr ;
			drop table wt_&vstr;
            run;
%end;
%next: proc sql noprint;
           drop table normality_&vstr;
		   %if %sysfunc(exist(hov_&vstr)) %then
		   	drop table hov_&vstr ;
           quit;
proc append base=finalstat data=
%if %sysfunc(exist(wt_&vstr._1)) %then wt_&vstr._1 ; %else 
	%do ;
	 %if %sysfunc(exist(kw_&vstr._1)) %then kw_&vstr._1;%else
	 	%do;
		   %if %sysfunc(exist(t_&vstr._1)) %then t_&vstr._1;%else
		      %do;
			  		%if %sysfunc(exist(tp_&vstr._1)) %then tp_&vstr._1;%else
						 f_&vstr._1 ;
			%end;
		%end;
	%end;
	force;
run;
proc sql noprint;
insert into finalstat
set variable='';
insert into finalstat
set variable='';
insert into finalstat
set variable='';
insert into finalstat
set variable='';
drop table %if %sysfunc(exist(wt_&vstr._1)) %then wt_&vstr._1 ; %else 
	%do ;
	 %if %sysfunc(exist(kw_&vstr._1)) %then kw_&vstr._1;%else
	 	%do;
		   %if %sysfunc(exist(t_&vstr._1)) %then t_&vstr._1;%else
		      %do;
			  		%if %sysfunc(exist(tp_&vstr._1)) %then tp_&vstr._1;%else
						 f_&vstr._1 ;
			%end;
		%end;
	%end; ;
quit;
%symdel pnorm phov/NOWARN;
%let nvar=%eval(&nvar+1);
%let vstr=%scan(&var,&nvar);
%end;
%symdel i /nowarn;
%exit:%mend;

/*例子*/
/*%statmeth(data=zhenjiu.desc,group=gender,var=age weight);*/
