/*
====================================================================================================
������:analysis_baseline													  				    
��;�������������,�Զ��ж��ʺϵĻ��߷�����������������߱�                               
	  �Զ��жϵķ���������������������(�Ƿ����)��fisher��t����(�Ƿ���Ҫ����)������������ǲ�������          
	  ��ѡ�ķ���������kappa��CA���Ƽ��飬��Կ������Գ��Լ����																						
���ߣ�dasheng															                    
ʱ�䣺2020/03/09							                                                
�汾��1.0									                                                
�汾˵�����״�����						                                                
===================================================================================================
ʱ�䣺2020/03/09/																		
�仯�����ȱʧֵ����ͳ��   																
ʱ�䣺2020/03/12																			
�仯��������rtf��pdf�ĸ�ʽ����ʾ																
===================================================================================================
����˵��																					
ds��		Ҫ���з��������ݼ�																
var��		�б���������б�����Ҫ|����														
grp��		�б���,��Ϊ��,��ֻ���м�����																														/
use_type:	�Ƿ�ʹ�ñ����жϵı������ͽ�����Ӧ����,Ĭ��T									
def_type:	��use_type=F�����,�г�ÿ�������ķ�������,N��ʾ����,C��ʾ����					
per_type:	����������Ҫ���ǵİٷֱ�����,��ѡֵΪrow �� col									
col_lab:	�б�����ǩ��ʹ��|����															
row_order:	ָ�г�����������б�������ʹ��|����												
col_order:	�б����Ƿ�����																	
both_order_test: ���б������б���������,ָ������������P:�������飬N���ǲ������� K��kappa	
match��		�г���Ҫ��Լ���ı�������ʹ��|����												
CA:			��2R����2Cʱ�Ƿ���Ҫ����CA���Ƽ���												
kill��		�Ƿ��������м���������ݼ���Ĭ��T����ʾɾ�������в��������ݼ�																			
filetype��	Ҫ����Ľ���ļ������ͣ���ѡpdf/rtf												
filename: 	ָ��Ҫ������ļ���																
weight:   	�����������ĸ��ָ����Ȩ�ı���												
miss��		�Ƿ�ͳ��ȱʧֵ																		
row_total:	�Ƿ�ͳ���У�T:�ڷ������ˮƽ֮ǰ���һ�б�ʾ������������ˮƽͳ��ֵ                                                  
title:    	ָ��Ҫ����ı��ı���															
footer:   	ָ��Ҫ����ı��Ľ�ע														
=================================================================================================
*/	
%macro analysis_baseline(saspath=,ds=,var=,grp=,use_type=T,def_type=,
						per_type=row,col_lab=,row_order=,
						col_order=F,both_order_test=P,match=,
						CA=F,kill=T,filetype=,filename=,row_total=F,
						weight=,miss=F,title=���߷������,foot=);

/*�����ǰ����־�ͽ��ҳ��*/
dm log"clear" continue;
dm odsresults 'clear' continue;
/*�ж���������ݼ��Ƿ����*/
%let did=%sysfunc(open(&ds,,,D));
%if &did=0 %then %do;
	%put ����������ݼ������ڣ����ʵ��;
	%goto exit;
	%end;
%else %do ;%put ;%put ����������ݼ���: &ds; %put ; %end;
/*�жϴ򿪵����ݼ��ı�������*/
/*1.����2��ȫ�ֺ����,����ʢ���ַ���������ֵ�����б�*/
%global char_list num_list;
%let char_list=;        
%let num_list=;
/*2.��ʼ��ӱ����б�*/
%do var_i=1 %to %sysfunc(countw(&var,|));
	%let var_name=%scan(&var,&var_i,|);
	%let var_num=%sysfunc(varnum(&did,&var_name));
	%if &var_num=0 %then %do;						 /*�жϷ��������Ƿ������ݼ���*/
		%put &var_name ���������ݼ� &ds ��! ;
		%goto exit;
	%end;
	%if &grp ne %then %do;
		%if %sysfunc(varnum(&did,&grp))=0 %then %do; /*�жϷ�������Ƿ������ݼ���*/
			%put &grp ���������ݼ� &ds ��! ;
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
/*��ʼ�������ݼ�*/
/*1.ʹ��Ĭ�ϱ������ͻ����Զ�������ķ�������*/
%if &use_type=T %then %goto getbaseline;
%else %do;
/*��ȫ�ֱ������*/
/*ȷ�������ķ�����������������Ƕ���*/
%let char_list=;
%let num_list=;
%if %sysfunc(countw(&var,|)) ne %sysfunc(countw(&def_type,|)) %then
	%do;
		%put ������Ŀ��ָ���ı������Ͳ�ƥ�䣬���������룡;
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

/*��ȡ�����ı��ͳ����*/
%getbaseline:
/*�ж��Ǽ�����������Ҫͳ�Ƽ���*/
%if &grp ne %then %do;
proc sql noprint;
select distinct(&grp), count(distinct &grp) into :grp_level separated by "|", :n_level_grp 
	from &ds ;                     
quit;
%end;
/*�����Ӻ�*/
%include "&saspath\cat.sas";
%include "&saspath\cat_judge.sas";
%include "&saspath\decorate.sas";
%include "&saspath\get_baseline.sas";
%include "&saspath\q_judge.sas";
%include "&saspath\qual.sas";
%get_baseline();
/*����ϲ���*/
%data_stack();
/*��ʾ���*/
%display_table();
/*ɾ���ӹ������ݼ�*/
%if &kill = T %then %kill();
%exit:%mend;
