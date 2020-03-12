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
