/*
�����ƣ�get_sample_size
��  ;�����������ʺ�Ŀ���ʵ�������
������
alpah: 		һ���������ʣ�Ĭ��0.05
beta �� 	�����������ʣ�Ĭ��0.2
start�� 	p0����ʼ�����ʣ�Ĭ��0.990
p1   ��		Ŀ���ʣ�Ĭ��0.999�����Ŀ������ʹ��|����
step ��     p0���㲽����Ĭ��0.001
plot ��     �Ƿ�ͼ�λ�չʾ��Ĭ��T����ʾ����ͼ�ν��
group��     ��plot=T������£������������ѡΪp0����p1
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
