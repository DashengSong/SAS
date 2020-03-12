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
