%macro import_sheets(outlib=work,path=,sheets=,ds=,);
/*判断逻辑库是否存在*/
%if &outlib ne work and %sysfunc(fileref(&outlib)) ^= 0   %then %do;
	 %put 逻辑库不存在，请核实！;
	 %goto exit;
%end;
/*判断文件是否存在*/
%if %sysfunc(fileexist(&path))=0 %then %do;
%put %str(==============================================================================);
%put &path.不存在，请确认文件路径以及文件名！;
%put %str(==============================================================================);
%goto exit;
%end;
/*导入数据集*/
%do i=1 %to %sysfunc(countw(&sheets,|));
	%put ------------------------------------------;
	%put 现在开始导入sheet: %scan(&sheets,&i,|);
	%if %length(&ds) eq 0 %then %let ex_ds=&outlib..data&i ; 
	%else %let ex_ds= &outlib..%scan(&ds,&i,|);
	proc import datafile="&path"  
	out= &ex_ds
	dbms=%scan(&path,2,.)
	replace;
	%if %scan(%scan(&sheets,&i,|),2,\) ne %str() %then %do;
		range="%scan(%scan(&sheets,&i,|),2,\)"; 
		sheet="%scan(%scan(&sheets,&i,|),1,\)";
	%end;
	%else 
	sheet="%scan(&sheets,&i,|)";;	
	run;
	%if &syserr =0 or &syserr =4 %then
		%put  %scan(&sheets,&i,|)导入成功！导入后的数据集是 &ex_ds ;
	%else %put %scan(&sheets,&i,|) 导入出现问题！;
	%put --------------------------------------------;
%end;
%exit:%mend;

