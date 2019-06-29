/******************************************************************************************/
/* coeded by Song   日期：2019.6.27                                                                       */
/* MACRO NAME : CLASSTABLE                                                                              */
/* 用途：       分类变量制作初步三线表                                                                       */
/* 参数说明:                                                                                                             */
/* 必填参数:                                                                                                             */
/* data         :指定需要分析的数据集                                                                          */
/* group       :分组变量，可以是一组也可以是多组，类似x                                           */
/* var            :分析变量 ，类似于y                                                                             */
/* 可选参数:                                                                                                             */
/* varlabel     :分析变量在表头显示的标签,需要与分析变量的水平一致,中间以空格隔开    */
/* vartype      :分析变量类型,0-非等级变量，1-等级变量                                              */
/* title           :表格的标题                                                                                         */
/* filepath     :文件输出路径,输出格式为rtf                                                                  */
/* miss          :是否要在频数表显示缺失值行                                                                */
/* style          :定义输出到rtf文件的样式                                                                      */
/*******************************************************************************************/
%macro classtable(data=,group=,var=,vartype=0,ylabel=,miss=0,title=,foot=, filepath=,style=journal2);
/*检查数据集存在*/
%if  ^%sysfunc(exist(&data,data)) %then %do;
%put 请检查您的数据集是否存在！;
 %goto exit;
%end;
%else %do;
proc sql noprint;
select  distinct &var into :vvalue  separated by " " from &data ;
select  count(distinct &var )  into :vlevel  separated by " " from  &data  ;
select count( &var ) into :nvar separated by " " from &data group by &var ; 
quit;
%let parms=0;
%if  &ylabel ne %then %do;
	%do %while(%scan(&ylabel,%eval(&parms+1)) ne );
		%let parms=%eval(&parms+1);
    %end;
   %if &parms ^= &vlevel %then %do;
		%put 请检查var标签数是否与var水平数 一致！;
         %goto exit; 
     %end;
 %end;
%let i=1;
%let gstr=%scan(&group,&i);
%do %while(&gstr ne);
/*分别获得分组变量和分析变量的水平数、水平值、分析变量的例数 */
proc sql noprint  ;
select  distinct &gstr into :gvalue separated by " " from &data %if &miss=0 %then where &gstr is not null ; ;
select  count(distinct &gstr ) into :glevel separated by " " from &data %if &miss=0 %then where &gstr is not null; ;
quit;
/*生成频数数据*/
proc freq data=&data;
tables  &gstr * &var  / norow nopercent expect %if &miss= 1 %then missing ; ;
ods output crosstabfreqs=freq&i ;
ods select crosstabfreqs;
run;
%if &vartype=1 %then %goto npar;
/*取得总频数、格子数目、期望频数*/
proc sql noprint;
select count(distinct &gstr),count(distinct(&var)) into :ncell1, :ncell2 from &data ;
select Frequency into :total from freq&i where _TYPE_='00' ;
select expected into :minp from freq&i  where expected <1;
quit;
%if &ncell1=&ncell2=2  %then %goto fourcell ; %else %goto multcell;
%fourcell:%if &total<40 | %symexist(minp)  %then %goto fisher ; %else %goto chisqtest ;
%multcell:proc sql noprint;
               select count(expected)/%eval(&ncell1 * &ncell2 ) into :mult from  freq&i where expected<5 ;
               quit;
		      %if &mult >0.2  %then %goto fisher ; %else %goto chisqtest ;
%chisqtest:ods output chisq=chisq&i (where=(statistic="卡方") drop=table);
                   ods select chisq ;
                   proc freq data=&data;
                   tables &gstr * &var  / chisq ;
                   run;
				   %goto level;
%fisher:ods output fishersExact=fisher&i (where=(name1='XP2_FISH') rename=(cvalue1=Prob) drop=table nValue1 label1) ;
                   ods select fishersExact ;
                   proc freq data=&data;
                   tables &gstr * &var  / fisher  ;
                   run;
				   data fisher&i ;
				    value=. ;
				   set fisher&i (drop=name1 );
				   run;
				   %goto level;
%npar: ods output KruskalWallisTest=kw&i ;
            ods select KruskalWallisTest ;
            proc npar1way data=&data wilcoxon;
            class &gstr ;
            var &var ;
           run;
           ods output close;
           data kw&i ;
           set kw&i ;
           if _n_=2 then delete;
           keep cvalue1;
		   run;
           proc transpose data=kw&i  out=kw&i ;
           var cvalue1;
           run;
           data kw&i ;
           set kw&i (rename=(_name_=variable col1=value col2=prob));
           if variable='cValue1' then variable=symget('gstr');
           run;
          proc sql noprint;
          create table kw&i.1  as
		  select value,prob from kw&i ;
		   drop table kw&i;
          run;
%goto level;
%level:proc sql noprint ;
create table var&i (variable char label='指标' );
insert into var&i 
set variable =symget('gstr')  ; 
create table group&i as
select distinct &gstr  as  varvalue from &data %if &miss=0 %then where &gstr is not null ; ;
insert into group&i 
set varvalue=. ;
quit;
data group&i;
set group&i;
varvalue1=left(lag(varvalue)) ;
drop varvalue;
rename varvalue1=varvalue;
run;
/*分析变量水平*/
%macro var_level(vlevel); 
%do x=1 %to &vlevel ;
merge freq&i (where=( &var =%scan(&vvalue,&x)) rename=(colpercent=Percent&x Frequency=N&x ) );
keep   Percent&x N&x Percent&X N&x ;
if  percent&x =. then delete;
%end;
%mend;
%macro npercent(vlevel);
%do x=1 %to &vlevel;
	varl&x =trim(n&x)||'('||trim(left(put(percent&x,8.2)))||")"; 
	varlevel&x =lag(varl&x);
	drop n&x percent&x varl&x;
%end;
%mend;
/*制作表格频数部分*/
data med&i;
%var_level(&vlevel);
run;
/*插入一行用于盛放后滞的变量值*/
proc sql noprint;
insert into med&i
set n1=. ;
quit;
/*滞后变量值*/
data med&i ;
set med&i;
%npercent(&vlevel);
run;
/*处理分析变量的标签*/
%macro label(ylabel);
%if &ylabel ne %then %do;
%do z=1 %to &vlevel;
label varlevel&z = %sysfunc(cat(%scan(&ylabel,&z ) , '(N=' , %scan(&nvar,&z) , ')' ));
  %end;
%end;
%else %do;
%do z=1 %to &vlevel;
label varlevel&z =%sysfunc(cat(%scan(&vvalue,&z ) , '(N=' , %scan(&nvar,&z) , ')' ));
%end;
%end;
%mend;
/*整合表格*/
data final&i;
merge var&i group&i med&i  %if %sysfunc(exist(chisq&i,data)) %then chisq&i (drop=statistic df) ; %else %do;
	%if %sysfunc(exist(fisher&i,data)) %then  fisher&i ; %do;
		%if %sysfunc(exist(wt&i.1,data)) %then wt&i.1 ; %else kw&i.1 ;
		%end;
	 %end; ;
%label(&ylabel);
label variable='指标' varvalue="水平" value='统计量' prob='P';
run;
%symdel ncell1ncell2 total mult gvalue vvalue glevel vlevel nvar minp /nowarn;
%let i=%eval(&i+1);
%let gstr=%scan(&group,&i);
%end;
proc sql noprint;
create table final like final1;
quit;
/*最终处理*/
%let m=1;
%let ds=%scan(&group,1);
%do %while(&ds ne );
proc append base=final data=final&m force;
run;
proc sql noprint;
drop table final&m , freq&m,med&m,group&m,var&m, 
%if %sysfunc(exist(chisq&m,data)) %then chisq&m  ; %else %do;
	%if %sysfunc(exist(fisher&m,data)) %then  fisher&m ; %do;
		%if %sysfunc(exist(wt&m.1,data)) %then wt&m.1 ; %else kw&m.1 ;
		%end;
	 %end;;
quit; 
%let m=%eval(&m+1);
%let ds=%scan(&group,&m);
%end;

%if &title= %then 
title &var 基线描述表 ;
%else 
title &title ;;
footnote  &foot  ;
%if &filepath ne %then %do;
ods rtf file=&filepath style=&style ;
%end;
proc sql ;
select * from final;
quit;
%if &filepath ne %then %do;
ods rtf close;
%end;
%end;
%exit:%mend;


libname zhenjiu "K:\work\针灸" ;
 %classtable(data=zhenjiu.desc,group=zxbh,var=gender)
