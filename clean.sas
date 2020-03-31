/*����ȱʧֵ���쳣ֵ*/
/*
�����ƣ�clean
��;��  ��ʾ������ȱʧֵ���쳣ֵ��Ϣ
ʱ�䣺  2020/03/26
����˵����
		data��Ҫ��ϴ�����ݼ�
		all�� �Ƿ���Ҫ��ʾȫ��������ȱʧֵ��Ϣ��T��ʾȫ����Ĭ��ѡ��
		vars����all������T������£�ָ��Ҫ��ʾȱʧֵ�ı���������֮��ո�ָ�
		std�� ָ��ʹ�þ����Ӽ���׼��ɸѡ�쳣ֵ��Χ�ı������ո����
		iqr�� ָ��ʹ����λ���Ӽ��ķ������ɸѡ�쳣ֵ��Χ�ı������ո����
		n_std: ���ڼ���������ֵ�ı�׼��ı�����Ĭ��2.5
		n_iqr: ���ڼ���������ֵ���ķ�λ�����ñ�����Ĭ��2.5
		user_range:�û�����ָ�������޷�Χ�������Ա�����\��Χ����ʽ��ʾ������A\1 2|B\3 4
		c_range:��Է��������ָ���������ͷ�Χ������A\1 2|B\3 4
		rec_wiedth:�����쳣ֵ�кű�����ʾ�ÿ�ȣ�Ĭ��20,���쳣ֵ�������࣬������ʾ��ȫ
		miss_col: ��ʾȱʧ��������miss_proֵ�ı������ı���ɫ
		miss_pro: ָ�����ǵ�ȱʧ������Ĭ��5����5%	
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
title "&data ����ɸѡ���";
proc report data=final;
define variables   /display "����";
define nmiss       /display "ȱʧ��";
define nomiss      /display "��ȱʧ��";
define miss_per   /display "ȱʧ����(%)";
define n_out_range /display "�쳣ֵ��Ŀ";
define record      /display "�쳣ֵ������" format=$&rec_width..;
define range       /display "����ֵ��Χ";
compute miss_per;
if miss_per > &miss_pro then 
call define('variables',"style","style=[backgroundcolor=&miss_col]");
endcomp;
column variables nmiss nomiss miss_per n_out_range record range;
run;
title ;
%mend;
