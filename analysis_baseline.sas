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
ʱ�䣺2020/03/14
�仯�����������塢�ֺš�С��λ�������뷽ʽ���Զ���ѡ��	
===================================================================================================
����˵��

1.���������ز���
saspath�� 			���SAS����ļ���·��	
filetype��			Ҫ����Ľ���ļ������ͣ���ѡpdf/rtf											
filename: 			ָ��Ҫ������ļ���	
kill��				�Ƿ��������м���������ݼ���Ĭ��T����ʾɾ�������в��������ݼ�	
-----------------------------------------------------------------------------------------
2.�����������	
ds��				Ҫ���з��������ݼ�																
var��				�б���������б�����Ҫ|����
grp��				�б���,��Ϊ��,��ֻ���м�����
use_type:			�Ƿ�ʹ�ñ����жϵı������ͽ�����Ӧ����,Ĭ��T									
def_type:			��use_type=F�����,�г�ÿ�������ķ�������,N��ʾ����,C��ʾ����					
per_type:			����������Ҫ���ǵİٷֱ�����,��ѡֵΪrow �� col																								
row_order:			ָ�г�����������б�������ʹ��|����												
col_order:			�б����Ƿ�����																	
both_order_test:    ���б������б���������,ָ������������P:�������飬N���ǲ������� K��kappa	
match��				�г���Ҫ��Լ���ı�������ʹ��|����												
CA:					��2R����2Cʱ�Ƿ���Ҫ����CA���Ƽ���																														
weight:   			��Ȩ												
miss��				�Ƿ�ͳ��ȱʧֵ																		
row_total:			�Ƿ�ͳ���У�T:�ڷ������ˮƽ֮ǰ���һ�б�ʾ������������ˮƽͳ��ֵ
norm_p:				��̬�Ա�׼��pֵ��Ĭ��0.05. 
------------------------------------------------------------------------------------------
3. ��������ʽ 
title:    			ָ��Ҫ����ı��ı��⣬Ĭ�ϣ����߷������															
footer:   			ָ��Ҫ����ı��Ľ�ע
dec:        		����С��λ����Ĭ��2λ
font:       		����������ļ��ı������壬Ĭ��Arial	
size��				ָ�������С��Ĭ��12pt(С�ĺ�)
col_lab:			�б�����ǩ��ʹ��|����
col_align:  		�ж��뷽ʽ����ѡleft/center/right
color				С��0.05��Pֵ��������ɫ��Ĭ�Ϻ�ɫ������ָ��������ɫ��ͻ����ʾ
var_wid             �����п��
lev_wid				ˮƽ�п��
p_wid				Pֵ�п��
logfile             �����־�ļ���·������Ϊ�գ������
=================================================================================================
*/	
%macro analysis_baseline(ds=,var=,grp=,use_type=T,def_type=,
						per_type=row,col_lab=,row_order=,
						col_order=F,both_order_test=P,match=,
						CA=,kill=T,filetype=,filename=,row_total=F,
						weight=,miss=F,title=���߷������,foot=,dec=2,
						alpha=0.05,row_lab=����,font=Arial,
						col_align=right,size=12pt,color=black,norm_p=0.05,
						logfile=);
options nomprint nosource nonotes;
/*�����ǰ����־�ͽ��ҳ��*/
dm log"clear" continue;
dm odsresults 'clear' continue;
%if &logfile ne %then %do;
proc printto log="&logfile";
run;
%end;
/*�ж���������ݼ��Ƿ����*/
%let did=%sysfunc(open(&ds,,,D));
%if &did=0 %then %do;
	%put ����������ݼ������ڣ����ʵ��;
	%goto exit;
	%end;
%else %do ;%put ;%put ����������ݼ���: &ds; %put ; %end;
/*�жϴ򿪵����ݼ��ı�������*/
%let char_list=;        
%let num_list=;
%if &use_type=T %then %do;
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
%end;
%else %do;
	%if %sysfunc(countw(&var,|)) ne %sysfunc(countw(&def_type,|)) %then
		%do;
			%put Var��������%sysfunc(countw(&var,|)) ��;
			%put �Զ���ı�����������%sysfunc(countw(&def_type,|)) ��;
			%put ������Ŀ��ָ���ı������Ͳ�ƥ�䣬���������룡;
			%goto exit;
		%end;
	%do type_i=1 %to %sysfunc(countw(&var,|));
		%let str=%scan(&var,&type_i,|);
		%let var_num=%sysfunc(varnum(&did,&str));
		%if &var_num=0 %then %do;						 /*�жϷ��������Ƿ������ݼ���*/
			%put &str ���������ݼ� &ds ��! ;
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
/*��ʼ�������ݼ�*/
%put ��������������;
%put &=num_list;
%put �������������;
%put &=char_list   ;
/*��ȡ�����ı��ͳ����*/
/*�ж��Ǽ�����������Ҫͳ�Ƽ���*/
%if &grp ne %then %do;
	proc sql noprint;
	select distinct &grp,count(distinct &grp) into :grp_level separated by "|", :n_level_grp 
	from &ds ;                     
	quit;
	%if &miss=T %then %let grp_level=Miss&grp_level;
%end;
/*�����Ӻ�*/
/*%include "&saspath\decorate.sas";*/
/*---------------------------------------decorate-------------------------------------*/
/*����ϲ�ÿ��������������ͳ����*/
%macro data_merge(out,d1,d2);
data &out;
merge &d1 &d2;
run;
%mend;

/*�ϲ�ÿ����*/
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
/*������ʾ*/
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
/*������ʾ��ʽ*/
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

/*������п��*/
%let n_cols=%eval((&row_total=T)+(&miss=T)+&n_level_grp+1);
%let wid=%sysevalf((100-27)/&n_cols)%;
%if &filetype ne %str() and &filename ne %str() %then %do;
ods &filetype file="&filename..&filetype" style=myjournal %if &filetype=rtf %then nokeepn;; %end;
%else %put ��û�������ļ�·��/�ļ���/�ļ����ͣ���˲�������ļ� ;;
/*������ʾ*/
proc report data=final split='/' style=[outputwidth=100%];
/*���÷Ǽ�����*/
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
/*���ü�����*/
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
/*ɾ�������е����ݼ�*/
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
%put &str ʹ�õķ��������ǿ���(δ����);
%else %put &str ʹ�õ��ǵ����󿨷�;
proc freq data=&ds;
table &str * &grp /chisq ;
ods output chisq=chisq_&cat_id(where=(Statistic=%if &adj=F %then "����"; 
							  %else "������������";) keep=statistic prob);
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
%put &str ʹ�õ���Fisherȷ�и��ʷ�!;
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
%put &str ʹ�õ���CA���Ƽ���;
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
%put &str ʹ�õ�����Լ���(�Գ��Լ���);
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
%put &str ʹ�õ���Kappa��;
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
%put �����жϵķ������:&str ;
%if %eval(&n_level_grp) * %eval(&n_level_str)=4 %then 
/*�ĸ���ж�*/
		%do;
			/*��Կ�������*/
			%if &match ne %then
				%do;
				%if %sysfunc(find(%upcase(&str),%upcase(&match))) %then %match_test();
				%end;
			%else %do;
			/*�����С����Ƶ������5 ���� ��Ƶ������40��pearson����*/
			%if &min_expect >=5 and &total >40 %then %chisq(adj=F);
			 	%else %if  &min_expect>=1 and &total>40 %then %chisq(adj=T);
				%else %fisher();
			%end;
		%end;
%else
/*RC���ж� */
%do;
	/*���2R����2C,�����б�����CA�У�����CA���Ƽ���*/ 
	%if (&n_level_str =2 or &n_level_grp =2) and (%sysfunc(find(%upcase(&str),%upcase(&CA))) ne 0) %then 
		%ca_test(); 
	/*���R=C,�Ƿ�������*/
	%else %if &n_level_str=&n_level_grp and %sysfunc(find(%upcase(&str),%upcase(&match))) ^= 0 %then
		%match_test();
	/*��������� & ������ �ǲ�������*/
	%else %if &col_order = T and (%sysfunc(find(%upcase(&str),%upcase(&row_order))) = 0) %then 
		%npar(cat) ;
	/*��������� & ������ �Զ������*/
	%else %if &col_order=T and (%sysfunc(find(%upcase(&str),%upcase(&row_order))) > 0) %then
		%do;
			%if &both_order_test=P %then %chisq();
			%else %if &both_order_test=N %then %npar(cat);
			%else %if &both_order_test=K %then %kappa();
			%else %put ��ѡ��ļ��鷽ʽ��ʱ��δ���룡�������ע��; 
		%end;
	%else %do;
		/*��ȡС��5������Ƶ������*/
		proc sql noprint;
		select count(expected)/%eval(&n_level_str * &n_level_grp) into :proportion 
				from temp_freq_&cat_id where 0< expected < 5 ;
		quit;
		/*�ж��Ƿ���Ҫfisher*/
		%if &proportion <=0.2 %then %chisq(); %else %fisher(); 
	%end;
%end;	
%mend;

/*------------------------------------------cat_judge--------------------------------*/
/*%include "&saspath\qual.sas";*/
/*------------------------------------------qual-------------------------------------*/
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
%if %sysfunc(find(&sysvlong,M6)) %then
ods output wilcoxonTest=&type._npar_&&&type._id (keep=Prob2 );
%else 
ods output wilcoxonTest=&type._npar_&&&type._id (keep=cvalue1);;
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
/*-------------------------------------qual---------------------------------*/
/*-------------------------q_dudge-----------------------*/
/*%include "&saspath\q_judge.sas";*/
%macro q_judge();
%put �����жϵĶ���������: &str ;
/*��̬���ж�*/
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
/*�������Է���*/
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
/************************************���Ա���*****************************************/
%do cat_id=1 %to %sysfunc(countw(&char_list,|));
	%let str=%scan(&char_list,&cat_id,|);
	%put --------------��ʼ���� &str---------------------;
	/*	�������Ƶ����*/
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
	/*	��ȡ����������ˮƽ�� n_level_str ��ˮƽֵ str_level*/
	proc sql noprint;
	select distinct(&str), count(distinct &str) into :str_level separated by "|", :n_level_str
		from &ds ;
	/*	��ȡ��С����Ƶ����������*/
	select min(Expected),max(Frequency) into :min_expect,:total from Temp_freq_&cat_id;
	quit;
	/*	�������Ƶ����*/
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
	/*����judge���жϷ�������*/
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
	label stat="ͳ����";
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
	%put --------------&str �������---------------------;
	%put ;
%end;
/********************************************��������************************************/
%do q_id=1 %to %sysfunc(countw(&num_list,|));
		/*������������*/
		%let str=%scan(&num_list,&q_id,|);
    	%put --------------��ʼ����&str---------------------;
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
		/*����judge���жϷ�������*/
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
		%put --------------&str ������ϣ�---------------------;
		%put ;
%end;
%mend get_baseline;
/*--------------------------------getbaseline------------------------------------*/
%get_baseline();
/*����ϲ���*/
%data_stack();
/*��ʾ���*/
%display_table();
/*ɾ���ӹ������ݼ�*/
%if &kill = T %then %kill();
%exit:
proc printto log=log;
run;
options source notes mprint ;
%mend;
