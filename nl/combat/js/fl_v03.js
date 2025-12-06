var i,j;
var f_pl = ["������","����","�����","����"];
var magco = ['000000','000000','E80005','148101','1C60C6','14BCE0'];

function viewl(vst)
{
	d.write('<TR><TD bgcolor=#ffffff class=nick><TABLE cellspacing=0 cellpadding=4 border=0 width=100%>');
	for(i=1; i<logs.length; i++)
	{
		d.write('<TR><TD class=nick>');
		for(j=0; j<logs[i].length; j++)
		{
			if(!isNaN(parseInt(logs[i][j][0])))
			{
				switch(logs[i][j][0])
				{
					case 0: d.write('<font class=ftime>'+logs[i][j][1]+'</font> '); break;
					case 1: d.write(' '+sh_align(logs[i][j][4],0)+sh_sign_s(logs[i][j][5])+'<font color=#'+(logs[i][j][1] == 1 ? '0052A6' : '087C20')+'><b>'+logs[i][j][2]+'</b></font>['+logs[i][j][3]+']'); break;
					case 6: d.write(' <font class=fpla>('+f_pl[logs[i][j][1]]+')</font>'); break;
					case 2: d.write(' �����������'+(!logs[i][j][3] ? '' : '�')+' <font color=#E34242><b>�'+logs[i][j][1]+' '+logs[i][j][2]+'�</b></font>.'); break;
					case 3: d.write(' �����������'+(!logs[i][j][2] ? '' : '�')+' <font color=#E34242><b>�'+logs[i][j][1]+'�</b></font>.'); break;
					case 4: d.write(' <font color=#'+(logs[i][j][1] == 1 ? '0052A6' : '087C20')+'><b><i>���������</i></b></font>'); break;
					case 5: d.write(' '+sh_align(logs[i][j][3],0)+sh_sign_s(logs[i][j][4])+'<b>'+logs[i][j][1]+'</b>['+logs[i][j][2]+']'); break;
					case 7: d.write(' ��������'+(!logs[i][j][2] ? '' : '�')+' <font color=#E34242><b>�'+logs[i][j][1]+'�</b></font>'); break;
					case 8: d.write('��������� ��������: <font color=#E34242><b>�'+logs[i][j][2]+'�</b></font>.'+(!logs[i][j][3] ? '' : ' ������ <b>������</b> ���������� �� 1!')); break;
                    case 9: d.write(' ��������'+(!logs[i][j][2] ? '' : '�')+' ���������� <font color=#'+magco[logs[i][j][3]]+'><b>�'+logs[i][j][1]+'�</b></font>'); break;
                    case 10: d.write(' <font color=#'+magco[logs[i][j][2]]+'><b>�'+logs[i][j][1]+'�</b></font>'); break;
                    case 11: d.write('��������� ���������: <font color=#E34242><b>�'+logs[i][j][2]+'�</b></font>.'+(!logs[i][j][3] ? '' : ' ������ <b>����������</b> ���������� �� 1!')); break;
				} 
			}
			else d.write(logs[i][j]);
		}
		d.write('</TD></TR>');
	}
	     
	switch(vst)
	{
		case 0: break;
		case 1: if(stats[0] > 0) d.write('<TR><TD bgcolor=#ffffff class=nick width=100%><TABLE cellspacing=0 cellpadding=0 border=0 align=center><TR><TD bgcolor=#cccccc class=nick width=100%><TABLE cellspacing=1 cellpadding=4 border=0 width=100%><TR><TD align=center class=ftxt bgcolor=#ffffff rowspan=2><font color=#777777>����������<br>����</font></TD><TD colspan=6 class=ftxt bgcolor=#ffffff align=center><font color=#777777>��������������� ����</font></TD></TR><TR><TD align=center class=ftxt bgcolor=#ffffff><B>�������</B></TD><TD align=center bgcolor=#ffffff><B>'+sh_align(1,1)+'</B></TD><TD align=center bgcolor=#ffffff><B>'+sh_align(2,1)+'</B></TD><TD align=center bgcolor=#ffffff><B>'+sh_align(4,1)+'</B></TD><TD align=center bgcolor=#ffffff><B>'+sh_align(3,1)+'</B></TD><TD align=center class=ftxt bgcolor=#ffffff><B>�����</B></TD</TR><TR><TD class=nick bgcolor=#ffffff nowrap align=center>'+stats[0]+'</font></TD><TD class=nick bgcolor=#ffffff nowrap align=center>'+stats[1]+'<font class=ftxt><sup>('+stats[6]+')</sup></font></TD><TD class=nick bgcolor=#ffffff nowrap align=center>'+stats[2]+'<font class=ftxt><sup>('+stats[7]+')</sup></font></TD><TD class=nick bgcolor=#ffffff nowrap align=center>'+stats[3]+'<font class=ftxt><sup>('+stats[8]+')</sup></font></TD><TD class=nick bgcolor=#ffffff nowrap align=center>'+stats[4]+'<font class=ftxt><sup>('+stats[9]+')</sup></font></TD><TD class=nick bgcolor=#ffffff nowrap align=center>'+stats[5]+'<font class=ftxt><sup>('+stats[10]+')</sup></font></TD><TD class=nick bgcolor=#ffffff nowrap align=center>'+(stats[1]+stats[2]+stats[3]+stats[4]+stats[5])+'<font class=ftxt><sup>('+(stats[6]+stats[7]+stats[8]+stats[9]+stats[10])+')</sup></font></TD></TR></TABLE></TD></TR></TABLE></TD></TR>'); break;
		case 2:
		if(!off)
		{
			d.write('<TR><TD bgcolor=#ffffff><img src=http://image.neverlands.ru/1x1.gif width=1 height=1></TD></TR><TR><TD bgcolor=#cccccc></TD></TR><TR><TD class=nick>��������� ���: ');
			gr_det(lives_g1,1,0);
			d.write(' ������ ');
			gr_det(lives_g2,2,0);
			d.write('</TD></TR>');
		}
		d.write('<TR><TD class=nick>');
		if(params[0] > 0)
		{
			d.write('��������:');
			for(i=1; i<=params[0]; i++) d.write(' '+(i != params[3] ? '<A href="?fid='+params[2]+'&p='+i+'">'+i+'</A>' : '<B>'+i+'</B>'));
			if(off) d.write(' | <A href="?fid='+params[2]+'&stat=1">���������� ���</A>');
		}
		d.write('</TD></TR>');
		break;
	}
	     
	d.write('<TR><TD bgcolor=#ffffff align=center>'+view_t()+'</TD></TR></TABLE></TD></TR>');
}

function views(m)
{
	var stcou = list.length;
	if(stcou > 0)
	{
		d.write('<TR><TD bgcolor=#ffffff class=nick width=100%><TABLE cellspacing=0 cellpadding=0 border=0 align=center><TR><TD bgcolor=#cccccc class=nick width=100%><TABLE cellspacing=1 cellpadding=4 border=0 width=100%><TR><TD colspan=8 class=nick bgcolor=#ffffff align=center><font color=#777777>���������� ���</font></TD></TR><TR><TD align=center class=ftxt bgcolor=#ffffff><B>��������</B></TD><TD align=center class=ftxt bgcolor=#ffffff><B>�������</B></TD><TD align=center bgcolor=#ffffff><B>'+sh_align(1,1)+'</B></TD><TD align=center bgcolor=#ffffff><B>'+sh_align(2,1)+'</B></TD><TD align=center bgcolor=#ffffff><B>'+sh_align(4,1)+'</B></TD><TD align=center bgcolor=#ffffff><B>'+sh_align(3,1)+'</B></TD><TD align=center class=ftxt bgcolor=#ffffff><B>�����</B></TD><TD align=center class=ftxt bgcolor=#ffffff><B>����</B></TD></TR>');
		for(i=m; i<stcou; i++) d.write('<TR><TD class=nick bgcolor=#ffffff nowrap>'+(list[i][0] == 1 ? sh_align(list[i][4])+sh_sign_s(list[i][5])+'<font color=#'+(list[i][1] == 1 ? '0052A6' : '087C20')+'><b>'+list[i][2]+'</b></font>['+list[i][3]+']<a href="./pinfo.cgi?'+list[i][2]+'" target=_blank><img src=http://image.neverlands.ru/chat/info.gif width=11 height=12 border=0 align=absmiddle></a>' : '<font color=#'+(list[i][1] == 1 ? '0052A6' : '087C20')+'><b><i>���������</i></b></font>')+'</TD><TD class=nick bgcolor=#ffffff nowrap align=center>'+list[i][6]+'<font class=ftxt><sup>('+list[i][11]+')</sup></font></TD><TD class=nick bgcolor=#ffffff nowrap align=center>'+list[i][7]+'<font class=ftxt><sup>('+list[i][12]+')</sup></font></TD><TD class=nick bgcolor=#ffffff nowrap align=center>'+list[i][8]+'<font class=ftxt><sup>('+list[i][13]+')</sup></font></TD><TD class=nick bgcolor=#ffffff nowrap align=center>'+list[i][9]+'<font class=ftxt><sup>('+list[i][14]+')</sup></font></TD><TD class=nick bgcolor=#ffffff nowrap align=center>'+list[i][10]+'<font class=ftxt><sup>('+list[i][15]+')</sup></font></TD><TD class=nick bgcolor=#ffffff nowrap align=center>'+(list[i][6]+list[i][7]+list[i][8]+list[i][9]+list[i][10])+'<font class=ftxt><sup>('+(list[i][11]+list[i][12]+list[i][13]+list[i][14]+list[i][15])+')</sup></font></TD><TD class=nick bgcolor=#ffffff align=center>'+list[i][16]+'</TD></TR>');
		d.write('</TABLE></TD></TR></TABLE></TD></TR>');
	}
	if(m > 0) d.write('<TR><TD bgcolor=#ffffff align=center class=nick><A href="?fid='+params[2]+'&p=1">��� ���</A></TD></TR>');
}

function gr_det(garr,grn,grlive)
{
	var bgc;
	i = garr.length - 1; 
	for(j=0; j<garr.length; j++) 
	{
		bgc = grn == 1 ? '0052A6' : '087C20';
		switch(garr[j][0])
		{
			case 1:
			if(!grlive) bgc = pl_live(garr[j][7],bgc);
			d.write('<font color=#'+bgc+'>'+sh_align(garr[j][3])+sh_sign_s(garr[j][4])+'<b>'+garr[j][1]+'</b></font><a href="./pinfo.cgi?'+garr[j][1]+'" target=_blank><img src=http://image.neverlands.ru/chat/info.gif width=11 height=12 border=0 align=absmiddle></a> ['+garr[j][5]+'/'+garr[j][6]+']');
			break;
			case 3:
			if(!grlive) bgc = pl_live(garr[j][5],bgc); 
			d.write('<font color=#'+bgc+'><b>'+garr[j][1]+'</b></font><a href="./pbots.cgi?'+garr[j][4]+'" target=_blank><img src=http://image.neverlands.ru/chat/info.gif width=11 height=12 border=0 align=absmiddle></a> ['+garr[j][2]+'/'+garr[j][3]+']');
			break;
			case 4:
			if(!grlive) bgc = pl_live(garr[j][1],bgc);
			d.write('<font color=#'+bgc+'><b><i>���������</i></b></font>');
			break;
		}
		d.write((j != i ? ', ' : ''));
	}
}

function pl_live(pll,bgc)
{
	if(!pll) return '999999';
	else return bgc;
}

function viewlog()
{
	d.write('<TABLE cellspacing=0 cellpadding=10 border=0 width=100%>');
	switch(show)
	{
		case 1: viewl(2); break;
		case 2: views(1); break;
	}
	d.write('</TABLE>');
}