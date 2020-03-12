%macro import_sheets(outlib=work,path=,sheets=,ds=,);
/*�ж��߼����Ƿ����*/
%if &outlib ne work and %sysfunc(fileref(&outlib)) ^= 0   %then %do;
	 %put �߼��ⲻ���ڣ����ʵ��;
	 %goto exit;
%end;
/*�ж��ļ��Ƿ����*/
%if %sysfunc(fileexist(&path))=0 %then %do;
%put %str(==============================================================================);
%put &path.�����ڣ���ȷ���ļ�·���Լ��ļ�����;
%put %str(==============================================================================);
%goto exit;
%end;
/*�������ݼ�*/
%do i=1 %to %sysfunc(countw(&sheets,|));
	%put ------------------------------------------;
	%put ���ڿ�ʼ����sheet: %scan(&sheets,&i,|);
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
		%put  %scan(&sheets,&i,|)����ɹ������������ݼ��� &ex_ds ;
	%else %put %scan(&sheets,&i,|) ����������⣡;
	%put --------------------------------------------;
%end;
%exit:%mend;

