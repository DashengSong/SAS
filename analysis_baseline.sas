/*
====================================================================================================
宏名称:analysis_baseline													  				    
用途：处理基线数据,自动判断适合的基线分析方法并输出成三线表                               
	  自动判断的分析方法包括：卡方检验(是否调整)，fisher，t检验(是否需要调整)，方差分析，非参数检验          
	  可选的分析方法：kappa，CA趋势检验，配对卡方，对称性检验等																						
作者：dasheng															                    
时间：2020/03/09							                                                
版本：1.0									                                                
版本说明：首次制作						                                                
===================================================================================================
时间：2020/03/09/																		
变化：添加缺失值和行统计   																
时间：2020/03/12																			
变化：增加了rtf和pdf的格式化显示	
时间：2020/03/14
变化：增加了字体、字号、小数位数、对齐方式的自定义选项	
===================================================================================================
参数说明

1.输入输出相关参数
saspath： 			存放SAS宏的文件夹路径	
filetype：			要输出的结果文件的类型，可选pdf/rtf											
filename: 			指定要输出的文件名	
kill：				是否保留过程中间产生的数据集，默认T，表示删除过程中产生的数据集	
-----------------------------------------------------------------------------------------
2.描述检验参数	
ds：				要进行分析的数据集																
var：				行变量，多个行变量需要|隔开
grp：				列变量,若为空,则只进行简单描述
use_type:			是否使用本宏判断的变量类型进行相应分析,默认T									
def_type:			在use_type=F情况下,列出每个变量的分析类型,N表示定量,C表示定性					
per_type:			列联表中需要考虑的百分比类型,可选值为row 和 col																								
row_order:			指列出考虑有序的行变量名，使用|隔开												
col_order:			列变量是否有序																	
both_order_test:    若行变量和列变量均有序,指定分析方法。P:卡方检验，N：非参数检验 K：kappa	
match：				列出需要配对检验的变量名，使用|隔开												
CA:					当2R或者2C时是否需要进行CA趋势检验																														
weight:   			加权												
miss：				是否统计缺失值																		
row_total:			是否统计行，T:在分组变量水平之前添加一列表示分析变量各个水平统计值
norm_p:				正态性标准的p值，默认0.05. 
------------------------------------------------------------------------------------------
3. 定义表格样式 
title:    			指定要输出的表格的标题，默认：基线分析结果															
footer:   			指定要输出的表格的脚注
dec:        		保留小数位数，默认2位
font:       		定义输出到文件的表格的字体，默认Arial	
size：				指定字体大小，默认12pt(小四号)
col_lab:			列变量标签，使用|隔开
col_align:  		列对齐方式，可选left/center/right
color				小于0.05的P值的字体颜色，默认黑色，可以指定起他颜色以突出显示
var_wid             变量列宽度
lev_wid				水平列宽度
p_wid				P值列宽度
logfile             输出日志文件的路径，若为空，则不输出
=================================================================================================
*/	
%macro analysis_baseline(ds=,var=,grp=,use_type=T,def_type=,
						per_type=row,col_lab=,row_order=,
						col_order=F,both_order_test=P,match=,
						CA=,kill=T,filetype=,filename=,row_total=F,
						weight=,miss=F,title=基线分析结果,foot=,dec=2,
						alpha=0.05,row_lab=变量,font=Arial,
						col_align=right,size=12pt,color=black,norm_p=0.05,
						logfile=);
options nomprint nosource nonotes;
/*清除以前的日志和结果页面*/
dm log"clear" continue;
dm odsresults 'clear' continue;
%if &logfile ne %then %do;
proc printto log="&logfile";
run;
%end;
/*判断输入的数据集是否存在*/
%let did=%sysfunc(open(&ds,,,D));
%if &did=0 %then %do;
	%put 您输入的数据集不存在，请核实！;
	%goto exit;
	%end;
%else %do ;%put ;%put 您输入的数据集是: &ds; %put ; %end;
/*判断打开的数据集的变量类型*/
%let char_list=;        
%let num_list=;
%if &use_type=T %then %do;
	%do var_i=1 %to %sysfunc(countw(&var,|));
		%let var_name=%scan(&var,&var_i,|);
		%let var_num=%sysfunc(varnum(&did,&var_name));
		%if &var_num=0 %then %do;						 /*判断分析变量是否在数据集中*/
			%put &var_name 并不在数据集 &ds 中! ;
			%goto exit;
		%end;
		%if &grp ne %then %do;
			%if %sysfunc(varnum(&did,&grp))=0 %then %do; /*判断分组变量是否在数据集中*/
				%put &grp 并不在数据集 &ds 中! ;
				%goto exit;
			%end;
		%end;
	%let type=%sysfunc(vartype(&did,&var_num));
 	%if &type=C %then 
		%let char_list=&char_list.&var_name| ;
	%else 
		%let num_list=&num_list.&var_name|;
	%end;
%end;
%else %do;
	%if %sysfunc(countw(&var,|)) ne %sysfunc(countw(&def_type,|)) %then
		%do;
			%put Var变量共：%sysfunc(countw(&var,|)) 个;
			%put 自定义的变量类型数：%sysfunc(countw(&def_type,|)) 个;
			%put 变量数目和指定的变量类型不匹配，请重新输入！;
			%goto exit;
		%end;
	%do type_i=1 %to %sysfunc(countw(&var,|));
		%let str=%scan(&var,&type_i,|);
		%let var_num=%sysfunc(varnum(&did,&str));
		%if &var_num=0 %then %do;						 /*判断分析变量是否在数据集中*/
			%put &str 并不在数据集 &ds 中! ;
			%goto exit;
		%end;
		%if %upcase(%scan(&def_type,&type_i,|))=N %then %do;
			%let num_list=&num_list.&str|;
		%end;
		%else %do;
			%let char_list=&char_list.&str|;
		%end;
	%end;	
%end;
%let rc=%sysfunc(close(&did));
/*开始处理数据集*/
%put 定量变量包括：;
%put &=num_list;
%put 分类变量包括：;
%put &=char_list   ;
/*获取基本的表和统计量*/
/*判断是简单描述还是需要统计检验*/
%if &grp ne %then %do;
	proc sql noprint;
	select distinct &grp,count(distinct &grp) into :grp_level separated by "|", :n_level_grp 
	from &ds ;                     
	quit;
	%if &miss=T %then %let grp_level=Miss&grp_level;
%end;
/*编译子宏*/
/*%include "&saspath\decorate.sas";*/
/*---------------------------------------decorate-------------------------------------*/
/*横向合并每个变量的描述和统计量*/
%macro data_merge(out,d1,d2);
data &out;
merge &d1 &d2;
run;
%mend;

/*合并每个表*/
%macro data_stack();
data final;
%if &grp ne %then %do;
set 
%if %length(&num_list)>0  %then qal: ;
%if %length(&char_list) >0 %then cat: ;
;;
%end;
%else %do;
set 
%if %length(&num_list)>0 %then desc: ;
%if %length(&char_list) >0 %then one_way: ;
;;
%end;
format level $20.;
run;
%mend;
/*设置显示*/
%macro display_table();
options nodate ;
ods escapechar="^";
/*%if &grp ne %then %do;*/
/*proc sql noprint;*/

/*quit;*/
/*%end;*/
%if &grp ne %then %do;
	proc sql noprint;
	%if &miss=T %then %do;
		select sum(&grp is null or &grp is not null) into :grp_num separated by "|"
			from &ds group by &grp ;
			quit;
	%end;
	%else %do;
		select count(&grp) into :grp_num separated by "|" 
		from &ds where &grp is not null group by &grp;
		quit;
	%end;
%end;
/*定义显示样式*/
proc template;
	define style styles.myjournal;
	parent=styles.journal;
	style fonts from fonts/
		'docFont'=("&font",&size)
		'headingFont'=("&font",&size,Bold)
		'titlefont'=("&font",&size);
	style data from cell/
		verticalalign=middle
		textalign= right
		font=Fonts('DocFont');
	 style Output from Container /                                           
         bordercolor = colors('fgA1')                                         
         borderwidth = 3                                                      
         borderspacing = 0                                                    
         cellpadding = 7                                                      
         frame = HSIDES                                                       
         rules = GROUPS; 
     style Continued from TitlesAndFooters/                                          
         font = fonts('headingFont')                                          
         cellpadding = 0                                                      
         borderspacing = 0                                                    
         pretext = text('continued')                                          
         width = 100%                                                         
         textalign = left;     
	end;
run;

/*计算各列宽度*/
%let n_cols=%eval((&row_total=T)+(&miss=T)+&n_level_grp+1);
%let wid=%sysevalf((100-27)/&n_cols)%;
%if &filetype ne %str() and &filename ne %str() %then %do;
ods &filetype file="&filename..&filetype" style=myjournal %if &filetype=rtf %then nokeepn;; %end;
%else %put 您没有输入文件路径/文件名/文件类型，因此不会输出文件 ;;
/*设置显示*/
proc report data=final split='/' style=[outputwidth=100%];
/*设置非简单描述*/
%if &grp ne %str() %then %do;
define variables /display style(header)=[verticalalign=middle] style(column)=[textalign=left] "&row_lab" style=[outputwidth=8%];
define level     /display left "" style(column)=[textalign=left] style=[outputwidth=12%];
%if &row_total=T %then define row_overall /display &col_align "Overall" style(header)=[verticalalign=middle textalign=center] style=[outputwidth=&wid];;
define pvalue    /display right style(header)=[fontstyle=italic verticalalign=middle ] "P" style=[outputwidth=7%];
%if %length(&col_lab)>0 %then %do;
	%if &miss=T %then %do;
		%do ncol=1 %to &n_level_grp+1;
		define col&ncol /display &col_align "%scan(&col_lab,&ncol,|)/(N=%scan(&grp_num,&ncol,|))" style=[outputwidth=&wid];
		%end;
	%end;%else %do;
		%do ncol=1 %to &n_level_grp;
		define col&ncol /display &col_align "%scan(&col_lab,&ncol,|)/(N=%scan(&grp_num,&ncol,|))" style=[outputwidth=&wid];
		%end;
	%end;
%end;
%else %do;
	%if &miss=T %then %do;
		%do ncol=1 %to &n_level_grp+1;
		define col&ncol /display &col_align "%scan(&grp_level,&ncol,|)/(N=%scan(&grp_num,&ncol,|))" style=[outputwidth=&wid];
		%end;
	%end;%else %do;
		%do ncol=1 %to &n_level_grp;
		define col&ncol /display &col_align "%scan(&grp_level,&ncol,|)/(N=%scan(&grp_num,&ncol,|))" style=[outputwidth=&wid] ;
		%end;
	%end;
%end;
column variables level %if &row_total=T %then row_overall; col: pvalue;
compute pvalue;
if input(substr(pvalue,1,6),6.)<0.05 then call define("pvalue","style","style=[color=&color]");
endcomp;
%end;
/*设置简单描述*/
%else %do;
define variables /display left "Variables" style(column)=[textalign=center] style(header)=[verticalalign=middle] ;
define level     /display left "" style(column)=[textalign=left];	
%if &row_total=T %then define row_overall /display right "Overall" style(column)=[textalign=left] style(header)=[verticalalign=middle];;
define stat      /display right "Statistics" style(header)=[verticalalign=middle textalign=center];
column variables level %if &row_total=T %then row_overall; stat;
%end;
title j=c "%str(&title)";
footnote "%str(&foot)";
run;
%if &filetype ne %str() and &filename ne %str() %then
ods &filetype close;
%mend;
/*删除过程中的数据集*/
%macro kill();
proc datasets mt=data;
%if %sysfunc(countw(&ds,.))=2 %then save final;
%else save final &ds; ;
quit;
%mend;
/*------------------------------------decorate--------------------------------*/
/*%include "&saspath\cat.sas";*/
/*-----------------------------------cat-------------------------------------*/
/*chisq*/
%macro chisq(adj=F);
%if &adj eq F %then 
%put &str 使用的分析方法是卡方(未调整);
%else %put &str 使用的是调整后卡方;
proc freq data=&ds;
table &str * &grp /chisq ;
ods output chisq=chisq_&cat_id(where=(Statistic=%if &adj=F %then "卡方"; 
							  %else "连续调整卡方";) keep=statistic prob);
ods select chisq ;
run;
ods output close;
data chisq_&cat_id;
set chisq_&cat_id(drop=statistic);
pvalue=put(prob,6.4);
drop prob;
run;
%data_merge(cat_&cat_id,freq_table_&cat_id,chisq_&cat_id);
%mend;
/*fisher*/
%macro fisher();
%put &str 使用的是Fisher确切概率法!;
proc freq data=&ds ;
table &str * &grp ;
exact fisher /maxtime=20;
ods output fishersexact=fisher_&cat_id(where=(name1="XP2_FISH")keep=name1 cvalue1);
ods select fishersexact;
run;
ods output close;
data fisher_&cat_id;
set fisher_&cat_id(drop=name1);
pvalue=cvalue1||"*";
drop cvalue1;
run;
%data_merge(cat_&cat_id,freq_table_&cat_id,fisher_&cat_id);
%mend;
/*CA*/
%macro ca_test();
%put &str 使用的是CA趋势检验;
proc freq data=&ds;
table &str*&grp /trend;
ods output trendtest=trend_&cat_id (where=(Name1="P2_TREND") keep=Name1 cvalue1);
ods select trendtest;
run;
ods output close;
data trend_&cat_id;
set trend_&cat_id(drop=name1);
pvalue=cvalue1||"**";
drop cvalue1;
run;
%data_merge(cat_&cat_id,freq_table_&cat_id,trend_&cat_id);
%mend;
/*match*/
%macro match_test();
%put &str 使用的是配对检验(对称性检验);
proc freq data=&ds;
table &str * &grp /agree;
%if &n_level_grp = 2 %then %do;
ods output mcnemarsTest=agree_&cat_id(keep=prob);
ods select mcnemarsTest;
%end;
%else %do;
ods output SymmetryTest=agree_&cat_id(keep=prob);
ods select SymmetryTest;
run;
%end;
run;
ods output close;
data agree_&cat_id;
set agree_&cat_id;
pvalue=prob||"***";
drop prob;
run;
%data_merge(cat_&cat_id,freq_table_&cat_id,agree_&cat_id);
%mend;
/*kappa*/
%macro agree();
%put &str 使用的是Kappa！;
proc freq data=&ds;
table &str * &grp /agree;
ods output kappaStatistics=kappa_&cat_id(keep=Value);
ods select kappaStatistics;
run;
ods output close;
data kappa_&cat_id;
set kappa_&cat_id;
pvalue=value||"$";
drop value;
run;
%data_merge(cat_&cat_id,freq_table_&cat_id,kappa_&cat_id);
%mend;
/*-----------------------------------cat-------------------------------------*/
/*%include "&saspath\cat_judge.sas";*/
/*------------------------------------------cat_judge--------------------------------*/
%macro cat_judge();
%put 现在判断的分类变量:&str ;
%if %eval(&n_level_grp) * %eval(&n_level_str)=4 %then 
/*四格表判断*/
		%do;
			/*配对卡方检验*/
			%if &match ne %then
				%do;
				%if %sysfunc(find(%upcase(&str),%upcase(&match))) %then %match_test();
				%end;
			%else %do;
			/*如果最小理论频数大于5 并且 总频数大于40，pearson检验*/
			%if &min_expect >=5 and &total >40 %then %chisq(adj=F);
			 	%else %if  &min_expect>=1 and &total>40 %then %chisq(adj=T);
				%else %fisher();
			%end;
		%end;
%else
/*RC表判断 */
%do;
	/*如果2R或者2C,并且行变量在CA中，进行CA趋势检验*/ 
	%if (&n_level_str =2 or &n_level_grp =2) and (%sysfunc(find(%upcase(&str),%upcase(&CA))) ne 0) %then 
		%ca_test(); 
	/*如果R=C,是否进行配对*/
	%else %if &n_level_str=&n_level_grp and %sysfunc(find(%upcase(&str),%upcase(&match))) ^= 0 %then
		%match_test();
	/*如果列有序 & 行无序 非参数检验*/
	%else %if &col_order = T and (%sysfunc(find(%upcase(&str),%upcase(&row_order))) = 0) %then 
		%npar(cat) ;
	/*如果列有序 & 行有序 自定义检验*/
	%else %if &col_order=T and (%sysfunc(find(%upcase(&str),%upcase(&row_order))) > 0) %then
		%do;
			%if &both_order_test=P %then %chisq();
			%else %if &both_order_test=N %then %npar(cat);
			%else %if &both_order_test=K %then %kappa();
			%else %put 您选择的检验方式暂时还未加入！请后续关注！; 
		%end;
	%else %do;
		/*获取小于5的理论频数比例*/
		proc sql noprint;
		select count(expected)/%eval(&n_level_str * &n_level_grp) into :proportion 
				from temp_freq_&cat_id where 0< expected < 5 ;
		quit;
		/*判断是否需要fisher*/
		%if &proportion <=0.2 %then %chisq(); %else %fisher(); 
	%end;
%end;	
%mend;

/*------------------------------------------cat_judge--------------------------------*/
/*%include "&saspath\qual.sas";*/
/*------------------------------------------qual-------------------------------------*/
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
proc npar1way data=&ds wilcoxon;
class &grp ;
var &str ;
%if &n_level_grp=2 %then %do;
%put &str 使用的是Wilcoxon检验！;
%if %sysfunc(find(&sysvlong,M6)) %then
ods output wilcoxonTest=&type._npar_&&&type._id (keep=Prob2 );
%else 
ods output wilcoxonTest=&type._npar_&&&type._id (keep=cvalue1);;
ods select wilcoxonTest ;
%end;
%else %do;
%put &str 使用的是 Kruskal-Wallis 检验！;
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
/*-------------------------------------qual---------------------------------*/
/*-------------------------q_dudge-----------------------*/
/*%include "&saspath\q_judge.sas";*/
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
select count(*) into :n_p from norm_&q_id where pvalue< &norm_p ;
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
/*-------------------------q_dudge-----------------------*/
/*%include "&saspath\get_baseline.sas";*/
%macro get_baseline();
/************************************定性变量*****************************************/
%do cat_id=1 %to %sysfunc(countw(&char_list,|));
	%let str=%scan(&char_list,&cat_id,|);
	%put --------------开始处理 &str---------------------;
	/*	输出基础频数表*/
	proc freq data=&ds ;
	%if &weight ne %then weight &weight;;
	%if &grp ne %then %do;
		table &str * &grp / chisq expected %if &miss=T %then missing;;
		ods output crosstabfreqs=Temp_freq_&cat_id;
		ods select crosstabfreqs;;
		%end;
	%else %do;
		table &str %if &miss=T %then /missing; ;
		ods output onewayfreqs=one_way_&cat_id;
		ods select onewayfreqs;;
		%end;
	run;
	ods output close;
	%if &grp ne %then %do;
	/*	获取分析变量的水平数 n_level_str 和水平值 str_level*/
	proc sql noprint;
	select distinct(&str), count(distinct &str) into :str_level separated by "|", :n_level_str
		from &ds ;
	/*	获取最小期望频数和总例数*/
	select min(Expected),max(Frequency) into :min_expect,:total from Temp_freq_&cat_id;
	quit;
	/*	整理基础频数表*/
	data ll_&cat_id;
	set Temp_freq_&cat_id;
	if _type_ ="11" then do;
	n_&per_type._per=compress(Frequency||"("||put(&per_type.percent,20.2)||")");
	table="";
	output;
	end;
	run;
	proc sort data=ll_&cat_id out=ll_&cat_id(keep=&str table n_&per_type._per where=(n_&per_type._per ne ""));
	by  _type_  &str ;
	run;
	proc transpose data=ll_&cat_id out=ll_&cat_id (where=(col1 ne "") drop=_name_ );
	by &str ;
	var n_row_per;
	copy table ;
	run;
	proc sql;
	insert into ll_&cat_id set table=symget('str');
	quit;
	proc sort data=ll_&cat_id ;
	by descending table &str ;
	run;

	%if &row_total = T %then %do;
	data lo_&cat_id ;
	set Temp_freq_&cat_id ;
	if _type_="10" then 
	row_overall=compress(Frequency||"("||put(percent,20.2)||")");
	if row_overall ne ""  then do ;
	keep &str row_overall ;
	output;
	end;
	run;
	proc sql;
	insert into lo_&cat_id set row_overall="";
	quit;
	proc sort data=lo_&cat_id;
	by &str row_overall;
	run;
	data ll_&cat_id ;
	merge ll_&cat_id lo_&cat_id  ;
	run;;
	%end;

	data freq_table_&cat_id;
	set ll_&cat_id;
	rename table=Variables ;
	level=put(&str,$20.);
	drop &str ;
	run;
	/*调用judge宏判断分析方法*/
	%cat_judge();
	%end;
	%else %do;
	data one_way_&cat_id;
	set one_way_&cat_id;
	stat=compress(put(percent,32.&dec)||"("||put(percent,32.&dec)||")");
	drop frequency percent &str cum: ;
	label f_&str="level";
	rename f_&str=level;
	rename table=Variables;
	label stat="统计量";
	run;
	proc sql noprint;
	insert into one_way_&cat_id set variables=symget("str");
	quit;
	data one_way_&cat_id;
	set one_way_&cat_id;
	if variables ne symget('str') then variables="";
	run;
	proc sort data=one_way_&cat_id;
	by descending variables;
	run;
	%end;
	%put --------------&str 处理结束---------------------;
	%put ;
%end;
/********************************************定量变量************************************/
%do q_id=1 %to %sysfunc(countw(&num_list,|));
		/*定量变量描述*/
		%let str=%scan(&num_list,&q_id,|);
    	%put --------------开始处理&str---------------------;
		proc means data=&ds mean std min max median qrange %if &miss=T %then nmiss; uclm lclm alpha=&alpha;
		var &str ;
		%if &grp ne %then %do;
			%if &miss=T %then %do;
				class &grp /missing;
			%end;
			%else %do;
				class &grp;
			%end;
		%end;
		ods output summary=desc_&q_id;
		ods select summary;
		quit;
		ods output close;
		data desc_&q_id;
		set desc_&q_id;
		m_minmax=compress(put(&str._min,32.&dec)||","||put(&str._max,32.&dec));
		m_iqr=compress(put(&str._median,32.&dec)||"("||put(&str._qrange,32.&dec)||")");
		m_std=compress(put(&str._mean,32.&dec)||unicode("&#177;","ncr")||put(&str._StdDev,32.&dec));
		m_cl=compress(put(&str._lclm,32.&dec)||unicode("&#126;","ncr")||put(&str._uclm,32.&dec));
		drop &str._mean &str._qrange &str._stddev &str._median &str._min &str._max &str._lclm &str._uclm;
		run;
		%if &grp ne %then %do;
		data temp;
		length variables $256 ;
		variables=symget('str');
		run;
		proc transpose data=desc_&q_id out=desc_&q_id(drop=_label_);
		var _all_ ;
		run;
		data desc_&q_id ;
		length _name_ $20;
		merge temp desc_&q_id ;
		array col{*} $ col:;
		if _n_=1 then
			do i=1 to dim(col);
			col(i)="";
			end;
		drop i;
		select;
		%if &miss=T %then when(_name_="&str._NMiss") _name_="Missing";;
		when(_name_="NObs") _name_="N";
		when(find(_name_,"minmax")) _name_="Min,Max";
		when(find(_name_,"m_iqr"))_name_="Median(IQR)";
		when(find(_name_,"m_std"))_name_="Mean"||unicode("&#177;","ncr")||"Std";
		when(find(_name_,"m_iqr"))_name_="Median(IQR)";
		when(find(_name_,"m_cl"))_name_="CI";
		otherwise _name_="";
		end;
		rename _name_=level;
		run;
		%if &row_total=T %then %do;
		proc means data=&ds n mean std min max median qrange %if &miss=T %then nmiss; uclm lclm alpha=&alpha;
		var &str ;
		ods output summary=o_desc_&q_id;
		ods select summary;
		run;
		data o_desc_&q_id;
		set o_desc_&q_id;
		m_minmax=compress(put(&str._min,32.&dec)||","||put(&str._max,32.&dec));
		m_iqr=compress(put(&str._median,32.&dec)||"("||put(&str._qrange,32.&dec)||")");
		m_std=compress(put(&str._mean,32.&dec)||unicode("&#177;","ncr")||put(&str._StdDev,32.&dec));
		m_cl=compress(put(&str._lclm,32.&dec)||unicode("&#126;","ncr")||put(&str._uclm,32.&dec));
		drop &str._mean &str._qrange &str._stddev &str._median &str._min &str._max &str._lclm &str._uclm;
		run;
		ods output close;
		proc transpose data=o_desc_&q_id out=o_desc_&q_id(drop=_label_);
		var _ALL_;
		run;
		proc sql ;
		alter table o_desc_&q_id add Variables char 256 ;
		insert into o_desc_&q_id set Variables=symget('str') ;
		quit;
		proc sort data=o_desc_&q_id;
		by descending variables ;
		run;
		data o_desc_&q_id ;
		length _name_ $20 ;
		set o_desc_&q_id;
		rename col1=row_overall ;
		select ;
		%if &miss=T %then when(_name_="&str._NMiss") _name_="Missing";;
		when (_name_="&str._N") _name_="N";
		when (find(_name_,"minmax")) _name_="Min,Max";
		when (find(_name_,"m_iqr"))_name_="Median(IQR)";
		when (find(_name_,"m_std"))_name_="Mean"||unicode("&#177;","ncr")||"Std";
		when (find(_name_,"m_iqr"))_name_="Median(IQR)";
		when (find(_name_,"m_cl"))_name_="CI";
		otherwise _name_="";
		end;
		rename _name_=level;
		run;
		data desc_&q_id;
		merge desc_&q_id o_desc_&q_id ;
		run;
		%end;
		/*调用judge宏判断分析方法*/
		%q_judge();
		%end;%else %do;
	    	proc transpose data=desc_&q_id out=desc_&q_id;
			var _ALL_;
			run;
			proc sql ;
			alter table desc_&q_id add Variables char 256 ;
			insert into desc_&q_id set Variables=symget('str') ;
			quit;
			proc sort data=desc_&q_id;
			by descending variables ;
			run;
			data desc_&q_id ;
			length _name_ $20;
			set desc_&q_id(drop=_label_);
			rename col1=stat ;
			select ;
			when(_name_="NObs") _name_="N";
			%if &miss=T %then when (_name_="&str._NMiss") _name_="Missing";;
			when(find(_name_,"minmax")) _name_="Min,Max";
			when(find(_name_,"m_iqr"))_name_="Median(IQR)";
			when(find(_name_,"m_std"))_name_="Mean"||unicode("&#177;","ncr")||"Std";
			when(find(_name_,"m_iqr"))_name_="Median(IQR)";
			when(find(_name_,"m_cl"))_name_="CI";
			otherwise _name_="";
			end;
			rename _name_=level;
			run;
	  %end;
		%put --------------&str 处理完毕！---------------------;
		%put ;
%end;
%mend get_baseline;
/*--------------------------------getbaseline------------------------------------*/
%get_baseline();
/*竖向合并表*/
%data_stack();
/*显示表格*/
%display_table();
/*删除子过程数据集*/
%if &kill = T %then %kill();
%exit:
proc printto log=log;
run;
options source notes mprint ;
%mend;
