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
===================================================================================================
参数说明																					
ds：		要进行分析的数据集																
var：		行变量，多个行变量需要|隔开														
grp：		列变量,若为空,则只进行简单描述																														/
use_type:	是否使用本宏判断的变量类型进行相应分析,默认T									
def_type:	在use_type=F情况下,列出每个变量的分析类型,N表示定量,C表示定性					
per_type:	列联表中需要考虑的百分比类型,可选值为row 和 col									
col_lab:	列变量标签，使用|隔开															
row_order:	指列出考虑有序的行变量名，使用|隔开												
col_order:	列变量是否有序																	
both_order_test: 若行变量和列变量均有序,指定分析方法。P:卡方检验，N：非参数检验 K：kappa	
match：		列出需要配对检验的变量名，使用|隔开												
CA:			当2R或者2C时是否需要进行CA趋势检验												
kill：		是否保留过程中间产生的数据集，默认T，表示删除过程中产生的数据集																			
filetype：	要输出的结果文件的类型，可选pdf/rtf												
filename: 	指定要输出的文件名																
weight:   	若是整理后的四格表，指定加权的变量												
miss：		是否统计缺失值																		
row_total:	是否统计行，T:在分组变量水平之前添加一列表示分析变量各个水平统计值                                                  
title:    	指定要输出的表格的标题															
footer:   	指定要输出的表格的脚注														
=================================================================================================
*/	
%macro analysis_baseline(saspath=,ds=,var=,grp=,use_type=T,def_type=,
						per_type=row,col_lab=,row_order=,
						col_order=F,both_order_test=P,match=,
						CA=F,kill=T,filetype=,filename=,row_total=F,
						weight=,miss=F,title=基线分析结果,foot=);

/*清除以前的日志和结果页面*/
dm log"clear" continue;
dm odsresults 'clear' continue;
/*判断输入的数据集是否存在*/
%let did=%sysfunc(open(&ds,,,D));
%if &did=0 %then %do;
	%put 您输入的数据集不存在，请核实！;
	%goto exit;
	%end;
%else %do ;%put ;%put 您输入的数据集是: &ds; %put ; %end;
/*判断打开的数据集的变量类型*/
/*1.生成2个全局宏变量,用来盛放字符变量和数值变量列表*/
%global char_list num_list;
%let char_list=;        
%let num_list=;
/*2.开始添加变量列表*/
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
%let rc=%sysfunc(close(&did));
/*开始处理数据集*/
/*1.使用默认变量类型还是自定义变量的分析类型*/
%if &use_type=T %then %goto getbaseline;
%else %do;
/*将全局变量清空*/
/*确定变量的分析类别，用作定量还是定性*/
%let char_list=;
%let num_list=;
%if %sysfunc(countw(&var,|)) ne %sysfunc(countw(&def_type,|)) %then
	%do;
		%put 变量数目和指定的变量类型不匹配，请重新输入！;
		%goto exit;
	%end;
%do type_i=1 %to %sysfunc(countw(&var,|));
	%if %upcase(%scan(&def_type,&type_i,|))=N %then %do;
		%let str=%scan(&var,&type_i,|);
		%let num_list=&num_list.&str|;
	%end;
	%else;%do;
		%let str=%scan(&var,&type_i,|);
		%let char_list=&char_list.&str|;
	%end;
%end;	
%end;

/*获取基本的表和统计量*/
%getbaseline:
/*判断是简单描述还是需要统计检验*/
%if &grp ne %then %do;
proc sql noprint;
select distinct(&grp), count(distinct &grp) into :grp_level separated by "|", :n_level_grp 
	from &ds ;                     
quit;
%end;
/*编译子宏*/
%include "&saspath\cat.sas";
%include "&saspath\cat_judge.sas";
%include "&saspath\decorate.sas";
%include "&saspath\get_baseline.sas";
%include "&saspath\q_judge.sas";
%include "&saspath\qual.sas";
%get_baseline();
/*竖向合并表*/
%data_stack();
/*显示表格*/
%display_table();
/*删除子过程数据集*/
%if &kill = T %then %kill();
%exit:%mend;
