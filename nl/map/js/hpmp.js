var interv;

function ins_HP()
{
    interv = setInterval("cha_HP()",1000);
    if(inshp[0] < 0) inshp[0] = 0;
    if(inshp[3] < 7) inshp[3] = 7;
}

function cha_HP()
{
    if(inshp[0] < 0) inshp[0] = 0;
    if(inshp[0] > inshp[1]) inshp[0] = inshp[1];
    if(inshp[2] > inshp[3]) inshp[2] = inshp[3];
    if(inshp[0] >= inshp[1] && inshp[2] >= inshp[3]) clearInterval(interv);
    
    s_hp_f = Math.round(160*(inshp[0]/inshp[1]));
    s_ma_f = Math.round(160*(inshp[2]/inshp[3]));

    document.getElementById('fHP').width = s_hp_f;
    document.getElementById('eHP').width = 160 - s_hp_f;
    document.getElementById('fMP').width = s_ma_f;
    document.getElementById('eMP').width = 160 - s_ma_f;
    document.getElementById('hbar').innerHTML = '&nbsp;[<font color=#bb0000><b>'+Math.round(inshp[0])+'</b>/<b>'+inshp[1]+'</b></font> | <font color=#336699><b>'+Math.round(inshp[2])+'</b>/<b>'+inshp[3]+'</b></font>]';

    inshp[0] += inshp[1]/inshp[4];
    inshp[2] += inshp[3]/inshp[5];
}