/*查找缺失值、异常值*/
/*
宏名称：clean
用途：  显示各变量缺失值，异常值信息
时间：  2020/03/26
参数说明：
		data：要清洗的数据集
		all： 是否需要显示全部变量的缺失值信息，T表示全部，默认选项
		vars：再all不等于T的情况下，指定要显示缺失值的变量，变量之间空格分隔
		std： 指定使用均数加减标准差筛选异常值范围的变量，空格隔开
		iqr： 指定使用中位数加减四分数间距筛选异常值范围的变量，空格隔开
		n_std: 用于计算上下限值的标准差的倍数，默认2.5
		n_iqr: 用于计算上下限值得四分位数间距得倍数，默认2.5
		user_range:用户自行指定上下限范围变量，以变量名\范围得形式表示，比如A\1 2|B\3 4
		c_range:针对分类变量，指定变量名和范围，比如A\1 2|B\3 4
		rec_wiedth:设置异常值行号变量显示得宽度，默认20,若异常值行数过多，可能显示不全
		miss_col: 显示缺失比例大于miss_pro值的变量名的背景色
		miss_pro: 指定考虑的缺失比例，默认5，即5%	
*/
%macro clean(data=,all=T,vars=,std=,iqr=,n_std=2.5,n_iqr=2.5,
			user_range=,c_range=,rec_width=20,miss_col=blue,miss_pro=5)/minoperator secure;
%show_miss;
%get_outlier;

data final;
merge f_miss count;
by variables;
run;

proc datasets;
%if %sysfunc(countw(&data))=1 %then
save &data final(memtype=data);
%else 
save final(memtype=data);;
quit;
title "&data 初步筛选结果";
proc report data=final;
define variables   /display "变量";
define nmiss       /display "缺失数";
define nomiss      /display "非缺失数";
define miss_per   /display "缺失比例(%)";
define n_out_range /display "异常值数目";
define record      /display "异常值案例号" format=$&rec_width..;
define range       /display "正常值范围";
compute miss_per;
if miss_per > &miss_pro then 
call define('variables',"style","style=[backgroundcolor=&miss_col]");
endcomp;
column variables nmiss nomiss miss_per n_out_range record range;
run;
title ;
%mend;
