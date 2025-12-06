var align_ar = ["0;0","darks.gif;���� ����","lights.gif;���� �����","sumers.gif;���� �������","chaoss.gif;���� �����","light.gif;�������� ����","dark.gif;�������� ����","sumer.gif;����������� �������","chaos.gif;���������� ����","angel.gif;�����"];
var reg_exp = /[f]\d\d\d/i;

function sh_align(alid,mode)
{
    if(alid > 0)
    {
        split_ar = align_ar[alid].split(";");
        return '<img src=http://image.neverlands.ru/signs/'+split_ar[0]+' width=15 height=12 border=0 align=absmiddle alt="'+split_ar[1]+'">'+(!mode ? '&nbsp;' : '');
    }
    return '';
}

function sh_sign(sign,signn,signs)
{
    if(reg_exp.test(sign)) sign = 'fami.gif';
    if(sign && sign!='none' && sign!='n') return '<img src=http://image.neverlands.ru/signs/'+sign+' width=15 height=12 border=0 align=absmiddle alt=" '+signn+(signs ? ' ('+signs+')' : '')+' ">&nbsp;';
    else return '';
}

function sh_sign_s(sign)
{
    if(reg_exp.test(sign)) sign = 'fami';
    if(sign && sign!='n') return '<img src=http://image.neverlands.ru/signs/'+sign+'.gif width=15 height=12 border=0 align=absmiddle>&nbsp;';
    else return '';
}

function fsign(sftype,sftime,sftrav)
{
    fst = '';
    switch(sftype)
    {
        case 0:
            ftmp_pic = '2';
	        ftmp = '��� ����������';
	    break;
        case 1:
            ftmp_pic = '1';
            ftmp = '������������';
        break;
        case 2:
            ftmp_pic = '1';
            ftmp = '���� �� ����';
        break;
        case 3:
            ftmp_pic = '1';
            ftmp = '���������� �� ����������';
        break;
        case 4:
            ftmp_pic = '1';
            ftmp = '���� ������ ����';
        break;
        case 5:
            ftmp_pic = '1';
            ftmp = '���������� ������ ����';
        break;
        case 6:
            ftmp_pic = '1';
            ftmp = '�������� ��� (10 �� 10)';
        break;
        case 7:
            ftmp_pic = '3';
            ftmp = '��� ����������';
        break;
        case 8:
            ftmp_pic = '4';
            ftmp = '������������ ���������';
        break;
	    default:
	        ftmp_pic = '1';
	        ftmp = '������������'; 
    }
    fst += '<img src=http://image.neverlands.ru/gameplay/fight'+ftmp_pic+'.gif alt="��� ���: '+ftmp+'" title="��� ���: '+ftmp+'" width=17 height=17 align=absmiddle> ';
    switch(sftime)
    {
        case 120:
	        ftmp_pic = '2';
	        ftmp = '2 ������';
	    break;
        case 180:
	        ftmp_pic = '3';
	        ftmp = '3 ������';
	    break;
        case 240:
	        ftmp_pic = '4';
	        ftmp = '4 ������';
	    break;
        case 300:
	        ftmp_pic = '5';
	        ftmp = '5 �����';
	    break;
    }
    fst += '<img src=http://image.neverlands.ru/gameplay/time'+ftmp_pic+'.gif alt="�������: '+ftmp+'" title="�������: '+ftmp+'" width=17 height=17 align=absmiddle>';
    switch(sftrav)
    {
        case 10:
	ftmp_pic = '4';
	ftmp = '������'; 
	break;
	case 30:
	ftmp_pic = '3';
	ftmp = '�������';  
	break;
	case 50:
	ftmp_pic = '2';
	ftmp = '�������';  
	break;
	case 80:
	ftmp_pic = '1';
	ftmp = '��. �������';  
	break;
	case 100:
	ftmp_pic = '1';
	ftmp = '��. �������';  
	break;
	case 110:
	ftmp_pic = '0';
	ftmp = '������';  
	break;  
    }
    fst += '<img src=http://image.neverlands.ru/gameplay/injury'+ftmp_pic+'.gif alt="% ��������������: '+ftmp+'" title="% ��������������: '+ftmp+'" width=17 height=17 align=absmiddle>';
    return fst;
}

function ltxt(lid)
{
    switch(lid)
    {
        case 2: return '�����';
        case 3: return '�������';
        case 7: return '�������';
        default: return '�����';
    }
}

function UpButton(lid)
{
    switch(lid)
    {
        case 1: return '�������';
        case 2: return '�����';
        case 3: return '�������';
        case 4: return '�����';
    }    
}