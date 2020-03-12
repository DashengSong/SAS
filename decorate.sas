
/*横向合并每个变量的描述和统计量*/
%macro data_merge(out,d1,d2);
data &out;
merge &d1 &d2;
run;
%mend;

/*合并每个表*/
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


/*设置显示*/
%macro display_table();
ods escapechar="^";
%if &grp ne %then %do;
proc sql noprint;
select count(&grp) into :grp_num separated by "|" 
	from &ds where &grp ne "" 
		group by &grp;
quit;
%end;
/*定义显示样式*/
proc template;
	define style styles.myjournal;
	parent=styles.journal;
	style fonts from fonts/
		'docFont'=("Arial",4)
		'headingFont'=("Arial",5,Bold)
		'titlefont'=("Arial",5);
	style data from cell/
		verticalalign=middle
		textalign=right
		font=Fonts('DocFont');
	style body from body /
		marginright = 0.5                                                      
        marginleft = 0.5;  
	style systitleandfootercontainer from container/
		font=("Microsoft YaHei UI",8);
	style Output from Container /                                           
         bordercolor = black                                         
         borderwidth = 3                                                      
         borderspacing = 1
		 frame = HSIDES                                                       
         rules = GROUPS   
         cellpadding = 5 ;                                                    
	end;
run;
%if &filetype ne %str() and &filename ne %str() %then
ods &filetype file="&filename..&filetype" style=myjournal;
%else %put 您没有输入文件路径/文件名/文件类型，因此不会输出文件 ;;
/*设置显示*/
proc report data=final split='/' ;
/*设置非简单描述*/
%if &grp ne %str() %then %do;
define variables /display style(header)=[verticalalign=middle] style(column)=[textalign=center] "Variables" ;
define level     /display left "" style(column)=[textalign=left];
%if &row_total=T %then define row_overall /display right "Overall" style(header)=[verticalalign=middle textalign=center];;
define pvalue    /display right style(header)=[fontstyle=italic verticalalign=middle ] "P";
%if %length(&col_lab)>0 %then %do;
	%do ncol=1 %to &n_level_grp;
		define col&ncol /display right "%scan(&col_lab,&ncol,|)/(N=%scan(&grp_num,&ncol,|))";
	%end;
%end;
%else %do;
	%do ncol=1 %to &n_level_grp;
		define col&ncol /display right "&ncol/(N=%scan(&grp_num,&ncol,|))";
	%end;
%end;
column variables level %if &row_total=T %then row_overall; col: pvalue;
%end;
/*设置简单描述*/
%else %do;
define variables /display left "Variables" style(column)=[textalign=center] style(header)=[verticalalign=middle];
define level     /display left "" style(column)=[textalign=left];	
%if &row_total=T %then define row_overall /display right "Overall" style(column)=[textalign=left] style(header)=[verticalalign=middle];;
define pvalue    /display right "^{style [fontstyle=itlaic] P}" style(header)=[verticalalign=middle];
define stat      /display right "Statistics" style(header)=[verticalalign=middle textalign=center];
column variables level %if &row_total=T %then row_overall; stat;
%end;
title j=c "%str(&title)";
footnote "%str(&foot)";
run;
%if &filetype ne %str() and &filename ne %str() %then
ods &filetype close;
%mend;
/*删除过程中的数据集*/
%macro kill();
proc datasets mt=data;
save final &ds;
quit;
%mend;
