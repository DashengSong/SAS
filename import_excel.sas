/***********************************************/
/*������import_excel                           */
/*��;: ����һ��Ŀ¼�µ�����excel�ļ�          */
/*���ߣ�dasheng       						   */
/*���䣺b380154969@163.com                     */
/*ʱ�䣺2020/03/07                             */
/***********************************************/

/*******************�����˵��******************************************/
/*path��    Ŀ¼��·��                                                 */
/*all:      �Ƿ�Ҫ����ȫ����excel��T��ʾTure��F��ʾFalse               */
/*item��    ���all=F������Ҫ��itemָ����Ҫ������ļ�˳���            */
/*	        �ļ�����|������Ŀ¼�º��е��ļ�������־�²鿴              */
/*merge��   �Ƿ񽫵�������ݼ��ϲ���һ�����ݼ�                         */
/*by��      ����merge�ļ�                                              */
/*outlib��  ��������ݼ����߼���                                       */
/*use_name: �Ƿ�ʹ��ԭ�ļ����ļ��������F������Ҫ��names��ָ���ļ���   */
/*names��   �Զ�������ݼ���                                           */
/*��ʹ��ע������                                                       */
/*�ú�ʹ��ǰ��ɾ��������ָ���߼����µ����ݼ�����֪Ϥ������             */
/***********************************************************************/


%macro import_excel(path=,all=T,item=,merge=F,by=,outlib=work,use_name=T,names=)/minoperator;
/*�ж��߼����Ƿ����*/
%if &outlib ne work and %sysfunc(fileref(&outlib)) ^= 0   %then %do;
	 %put �߼��ⲻ���ڣ����ʵ��;
	 %goto exit;
%end;
%let fileref=dir;
%let rc=%sysfunc(filename(fileref,&path));
%put rc;
/*�ж��Ƿ�����ļ����óɹ�*/
%if &rc ^= 0 %then %do;
	%put Ŀ¼�����ڻ���ȷ����˶�!;  
	%goto exit ;
%end;
%put --------------------a--------------;
/*�������ɹ�����Ŀ¼*/
%let dir_id=%sysfunc(dopen(&fileref));
%put %sysfunc(dinfo(&dir_id,dsname));
/*��Ŀ¼�µĳ�Ա��*/
%let count_item=%sysfunc(dnum(&dir_id));
/*�����ļ���*/
%let work_dir=%sysfunc(dlgcdir(&path));
%let file_list=;
%do file_id = 1 %to &count_item;
	%put %sysfunc(dread(&dir_id,&file_id));
	%if %scan(%sysfunc(dread(&dir_id,&file_id)),2,.)=xlsx |
		%scan(%sysfunc(dread(&dir_id,&file_id)),2,.)=xls %then 
	%do;
		%let file=%sysfunc(dread(&dir_id,&file_id));
		%let file_list= &file_list.&file|;
	%end;
%end;
%let rc=%sysfunc(dclose(&dir_id));
%let r=%sysfunc(filename(fileref,));
%put &r ;
%if %length(&file_list) = 0 %then %do;
	%put ���ļ����²�û��excel�ļ���;
	%goto exit;
%end;	
%put -----------------------���Ƿָ���----------------------------;
%put;
%put ���ļ����¹�����Щexcel�ļ�(|�ָ�)��&file_list;
%put;
%put -----------------------���Ƿָ���----------------------------;
/*ɾ������ָ���߼����µ����ݼ�*/
proc datasets lib=&outlib kill memtype=data; run; quit;
/*��������*/
%if &all=F %then 
	%do;
	 	%do id=1 %to %sysfunc(countw(&item,|));
		%let file_to_imp=%scan(&file_list,%scan(&item,&id,|));
		%put ----------------------------------------------------;
		%put ���ڿ�ʼ����� &id ���ļ�,�ļ����� &file_to_imp ;
		proc import datafile="&file_to_imp" out=%if &use_name=T %then &outlib..data_&id ; %else
			&outlib..%scan(&names,&id); dbms=data_&id replace;
		run;
		%if &syserr in (0 4) %then %put ����ɹ���; %else &file_to_imp ������ִ����Ժ�鿴;
		%end;
	%end;
%else %do; 
	%do id=1 %to %sysfunc(countw(&file_list,|));
		%let file_to_imp=%scan(&file_list,&id,|);
		%put ----------------------------------------------------;
		%put ���ڿ�ʼ����� &id ���ļ�,�ļ����� &file_to_imp ;
		proc import datafile="&file_to_imp" out=%if &use_name=T %then &outlib..data_&id ; %else
			&outlib..%scan(&names,&id);
			dbms=%scan(&file_to_imp,2,.) replace;
		run;
		%if &syserr in (0 4) %then %put ����ɹ���; %else &file_to_imp ������ִ����Ժ�鿴;
	%end;
%end;
%if &merge=T %then %do;
proc sql noprint;
select distinct memname into: tables separated by " " from dictionary.columns 
	where libname="&outlib" and memtype="DATA" ;
quit;
data data_merged ;
merge &tables ;
by &by ;
run;
%end;
%exit:
%mend import_excel;
