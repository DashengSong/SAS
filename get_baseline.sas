
%macro get_baseline();
/************************************定性变量*****************************************/
%do cat_id=1 %to %sysfunc(countw(&char_list,|));
	%let str=%scan(&char_list,&cat_id,|);
	%put --------------开始处理 &str---------------------;
	/*	输出基础频数表*/
/*	weight &weight;;*/
	proc freq data=&ds ;
	%if &weight ne %then weight &weight;;
	%if &grp ne %then %do;
		table &str * &grp / chisq expected %if &miss=T %then missing; ;
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
		%if &grp ne %then class &grp ;;
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
		length variables $30 ;
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
		select ;
		when (_name_="NObs") _name_="N";
		%if &miss=T %then when (_name_="&str._NMiss") _name_="Missing";;
		when (find(_name_,"minmax")) _name_="Min,Max";
		when (find(_name_,"m_iqr"))_name_="Median(IQR)";
		when (find(_name_,"m_std"))_name_="Mean"||unicode("&#177;","ncr")||"Std";
		when (find(_name_,"m_iqr"))_name_="Median(IQR)";
		when (find(_name_,"m_cl"))_name_="CI";
		otherwise _name_="";
		end;
		rename _name_=level;
		run;
		%if &row_total=T %then %do;
		proc means data=&ds n mean std min max median qrange %if &miss=T %then nmiss; ;
		var &str ;
		ods output summary=o_desc_&q_id;
		ods select summary;
		run;
		data o_desc_&q_id;
		set o_desc_&q_id;
		m_iqr=compress(put(&str._median,32.2)||"("||put(&str._qrange,32.2)||")");
		m_std=compress(put(&str._mean,32.2)||unicode("&#177;","ncr")||put(&str._StdDev,32.2));
		drop &str._mean &str._qrange &str._stddev &str._median ;
		run;
		ods output close;
		proc transpose data=o_desc_&q_id out=o_desc_&q_id(drop=_label_);
		var _ALL_;
		run;
		proc sql ;
		alter table o_desc_&q_id add Variables char 20 ;
		insert into o_desc_&q_id set Variables=symget('str') ;
		quit;
		proc sort data=o_desc_&q_id;
		by descending variables ;
		run;
		data o_desc_&q_id ;
		length _name_ $20 ;
		set o_desc_&q_id;
		rename col1=row_overall ;
		select;
		when (_name_="NObs") _name_="N";
		%if &miss=T %then when (_name_="&str._NMiss") _name_="Missing";;
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
			alter table desc_&q_id add Variables char 20 ;
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
			when (_name_="NObs") _name_="N";
			%if &miss=T %then when (_name_="&str._NMiss") _name_="Missing";;
			when (find(_name_,"minmax")) _name_="Min,Max";
			when (find(_name_,"m_iqr"))_name_="Median(IQR)";
			when (find(_name_,"m_std"))_name_="Mean"||unicode("&#177;","ncr")||"Std";
			when (find(_name_,"m_iqr"))_name_="Median(IQR)";
			when (find(_name_,"m_cl"))_name_="CI";
			otherwise _name_="";
			end;
			rename _name_=level;
			run;
	  %end;
		%put --------------&str 处理完毕！---------------------;
		%put ;
%end;
%exit:%mend get_baseline;
