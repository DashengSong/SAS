/*
宏名称：get_sample_size
用  途：计算样本率和目标率的样本量
参数：
alpah: 		一类错误控制率，默认0.05
beta ： 	二类错误控制率，默认0.2
start： 	p0的起始计算率，默认0.990
p1   ：		目标率，默认0.999，多个目标率请使用|隔开
step ：     p0计算步长，默认0.001
plot ：     是否图形化展示，默认T，表示绘制图形结果
group：     在plot=T的情况下，分组变量，可选为p0或者p1
*/
%macro get_sample_size(alpha=0.05,beta=0.2,start=0.990,p1=0.999,step=0.001,plot=T,group=p1);
data sample;run;
%do i=1 %to %sysfunc(countw(&p1,|));
	%let temp_p1=%scan(&p1,&i,|);
	%do x = %sysevalf(&start*1000) %to %sysevalf(&temp_p1*1000)-1 %by %sysevalf(&step*1000) ;
		%let b= &temp_p1;
		%let a= %sysevalf(&x/1000) ;
		data temp;
		p0=symget('a');
		p1=symget('b');
		Z1=round(quantile('normal',1-symget("alpha")/2),0.01);
		Z2=round(quantile('normal',1-symget("beta")),0.01);
		N=ceil((Z1*sqrt(symget('a')*(1-symget('a')))+Z2*sqrt(symget('b')*(1-symget('b'))))**2/(symget('a')-symget('b'))**2);
		run;
		data sample; 
		set sample temp;
		run;
	%end;
%end;
data sample;
set sample;
if _n_=1 then delete;
run;
%if &plot=T %then %do;
	%if &group=p1 %then title "Sample size with P0, strata=P1";
	%else title "Sample size with P1, strata=P0";;
	proc sgplot data=sample ;
	%if &group=p1 %then 
		series x=p0 y=n/group=p1 curvelabel curvelabelpos=end; 
	%else 
		series x=p1 y=n/group=p0 curvelabel curvelabelpos=start; ;
	yaxis label="Sample size"; 
	run;
%end;
%mend;
