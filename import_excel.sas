/***********************************************/
/*宏名：import_excel                           */
/*用途: 导入一个目录下的所有excel文件          */
/*作者：dasheng       						   */
/*邮箱：b380154969@163.com                     */
/*时间：2020/03/07                             */
/***********************************************/

/*******************宏参数说明******************************************/
/*path：    目录的路径                                                 */
/*all:      是否要导入全部的excel，T表示Ture，F表示False               */
/*item：    如果all=F，则需要用item指定需要导入的文件顺序号            */
/*	        文件名用|隔开，目录下含有的文件可在日志下查看              */
/*merge：   是否将导入的数据集合并到一个数据集                         */
/*by：      用来merge的键                                              */
/*outlib：  输出的数据集的逻辑库                                       */
/*use_name: 是否使用原文件的文件名，如果F，则需要在names中指定文件名   */
/*names：   自定义的数据集名                                           */
/*宏使用注意事项                                                       */
/*该宏使用前会删除所有在指定逻辑库下的数据集，请知悉！！！             */
/***********************************************************************/


%macro import_excel(path=,all=T,item=,merge=F,by=,outlib=work,use_name=T,names=)/minoperator;
/*判断逻辑库是否存在*/
%if &outlib ne work and %sysfunc(fileref(&outlib)) ^= 0   %then %do;
	 %put 逻辑库不存在，请核实！;
	 %goto exit;
%end;
%let fileref=dir;
%let rc=%sysfunc(filename(fileref,&path));
%put rc;
/*判断是否分配文件引用成功*/
%if &rc ^= 0 %then %do;
	%put 目录不存在或不正确！请核对!;  
	%goto exit ;
%end;
%put --------------------a--------------;
/*如果分配成功，打开目录*/
%let dir_id=%sysfunc(dopen(&fileref));
%put %sysfunc(dinfo(&dir_id,dsname));
/*该目录下的成员数*/
%let count_item=%sysfunc(dnum(&dir_id));
/*产生文件名*/
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
%if %length(&file_list) = 0 %then %do;
	%put 该文件夹下并没有excel文件！;
	%goto exit;
%end;	
%put -----------------------我是分割线----------------------------;
%put;
%put 该文件夹下共有这些excel文件(|分隔)：&file_list;
%put;
%put -----------------------我是分割线----------------------------;
/*删除所有指定逻辑库下的数据集*/
proc datasets lib=&outlib kill memtype=data; run; quit;
/*导入数据*/
%if &all=F %then 
	%do;
	 	%do id=1 %to %sysfunc(countw(&item,|));
		%let file_to_imp=%scan(&file_list,%scan(&item,&id,|));
		%put ----------------------------------------------------;
		%put 现在开始导入第 &id 个文件,文件名是 &file_to_imp ;
		proc import datafile="&file_to_imp" out=%if &use_name=T %then &outlib..data_&id ; %else
			&outlib..%scan(&names,&id); dbms=data_&id replace;
		run;
		%if &syserr in (0 4) %then %put 导入成功！; %else &file_to_imp 导入出现错误，稍后查看;
		%end;
	%end;
%else %do; 
	%do id=1 %to %sysfunc(countw(&file_list,|));
		%let file_to_imp=%scan(&file_list,&id,|);
		%put ----------------------------------------------------;
		%put 现在开始导入第 &id 个文件,文件名是 &file_to_imp ;
		proc import datafile="&file_to_imp" out=%if &use_name=T %then &outlib..data_&id ; %else
			&outlib..%scan(&names,&id);
			dbms=%scan(&file_to_imp,2,.) replace;
		run;
		%if &syserr in (0 4) %then %put 导入成功！; %else &file_to_imp 导入出现错误，稍后查看;
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
