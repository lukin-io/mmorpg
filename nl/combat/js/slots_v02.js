d = document;
function slots_inv(image,nick,sl_main,sl_uids,sl_vcod,sl_csol,wsize)
{
       var main = sl_main.split("@");
       var uids = sl_uids.split("@");
       var vcod = sl_vcod.split("@");
       var csol = sl_csol.split("@");
       if (!main[16]) main[16] = 'sl_l_6.gif';
       if (!main[17]) main[17] = 'sl_r_7.gif';
       if (!main[18]) main[18] = 'sl_r_5.gif';
       if (!main[19]) main[19] = 'sl_r_5.gif';
       for(var i = 16; i <= 19; i++) {
          if (!uids[i]) uids[i] = ''; if (!vcod[i]) vcod[i] = ''; if (!csol[i]) csol[i] = '';
       }
       d.write(sl_html(2)+
           '<tr><td>'+sl_butt(main[0],uids[0],vcod[0],csol[0],62,65)+'</td></tr>'+
           '<tr><td>'+sl_butt(main[1],uids[1],vcod[1],csol[1],62,35)+'</td></tr>'+
           '<tr><td>'+sl_butt(main[2],uids[2],vcod[2],csol[2],62,91)+'</td></tr>'+
           '<tr><td>'+sl_butt(main[16],uids[16],vcod[16],csol[16],62,81)+'</td></tr>'+
           '<tr><td>'+sl_butt(main[7],uids[7],vcod[7],csol[7],62,63)+'</td></tr>'+
           '</table></td>');
       d.write(sl_html(1) + '<td valign=top><table><tr><td align="center">'+inv_sl_image(image,nick,wsize)+'</td></tr>'+
           '<tr><td align="center">'+sl_butt(main[13],uids[13],vcod[13],csol[13],31,31)+sl_butt(main[14],uids[14],vcod[14],csol[14],31,31)+sl_butt(main[18],uids[18],vcod[18],csol[18],31,31)+sl_butt(main[19],uids[19],vcod[19],csol[19],31,31)+'</td></tr>'+
           '<tr><td align="center">'+sl_butt(main[4],uids[4],vcod[4],csol[4],20,20)+sl_html(3)+sl_butt(main[5],uids[5],vcod[5],csol[5],20,20)+sl_html(3)+sl_butt(main[6],uids[6],vcod[6],csol[6],20,20)+'</td></tr>'+
           '</table></td>');
       d.write(sl_html(1) + sl_html(2)+
           '<tr><td>'+sl_butt(main[8],uids[8],vcod[8],csol[8],20,20)+sl_butt(main[9],uids[9],vcod[9],csol[9],42,20)+'</td></tr>'+
           '<tr><td>'+sl_butt(main[10],uids[10],vcod[10],csol[10],62,40)+'</td></tr>'+
           '<tr><td>'+sl_butt(main[11],uids[11],vcod[11],csol[11],62,40)+'</td></tr>'+
           '<tr><td>'+sl_butt(main[12],uids[12],vcod[12],csol[12],62,91)+'</td></tr>'+
           '<tr><td>'+sl_butt(main[15],uids[15],vcod[15],csol[15],62,83)+'</td></tr>'+
           '<tr><td>'+sl_butt(main[3],uids[3],vcod[3],csol[3],62,30)+'</td></tr>'+
           '<tr><td>'+sl_butt(main[17],uids[17],vcod[17],csol[17],62,31)+'</td></tr>'+
           '</table></td>');
}

function slots_pla(image,nick,sl_main,sl_csol,wsize)
{
       var main = sl_main.split("@");
       var csol = sl_csol.split("@");
       if (!main[16]) main[16] = 'sl_l_6.gif';
       if (!main[17]) main[17] = 'sl_r_7.gif';
       if (!main[18]) main[18] = 'sl_r_5.gif';
       if (!main[19]) main[19] = 'sl_r_5.gif';
       for(var i = 16; i <= 19; i++) {
           if (!csol[i]) csol[i] = '';
       }
       d.write(sl_html(2)+
           '<tr><td>'+sl_view(main[0],csol[0],62,65)+'</td></tr>'+
           '<tr><td>'+sl_view(main[1],csol[1],62,35)+'</td></tr>'+
           '<tr><td>'+sl_view(main[2],csol[2],62,91)+'</td></tr>'+
           '<tr><td>'+sl_view(main[16],csol[16],62,81)+'</td></tr>'+
           '<tr><td>'+sl_view(main[7],csol[7],62,63)+'</td></tr>'+
           '</table></td>');
       d.write(sl_html(1) + '<td valign=top><table><tr><td align="center">'+inv_sl_image(image,nick,wsize)+'</td></tr>'+
           '<tr><td align="center">'+sl_view(main[13],csol[13],31,31)+sl_view(main[14],csol[14],31,31)+sl_view(main[18],csol[18],31,31)+sl_view(main[19],csol[19],31,31)+'</td></tr>'+
           '<tr><td align="center">'+sl_view(main[4],csol[4],20,20)+sl_html(3)+sl_view(main[5],csol[5],20,20)+sl_html(3)+sl_view(main[6],csol[6],20,20)+'</td></tr>'+
           '</table></td>');
       d.write(sl_html(1) + sl_html(2)+
           '<tr><td>'+sl_view(main[8],csol[8],20,20)+sl_view(main[9],csol[9],42,20)+'</td></tr>'+
           '<tr><td>'+sl_view(main[10],csol[10],62,40)+'</td></tr>'+
           '<tr><td>'+sl_view(main[11],csol[11],62,40)+'</td></tr>'+
           '<tr><td>'+sl_view(main[12],csol[12],62,91)+'</td></tr>'+
           '<tr><td>'+sl_view(main[15],csol[15],62,83)+'</td></tr>'+
           '<tr><td>'+sl_view(main[3],csol[3],62,30)+'</td></tr>'+
           '<tr><td>'+sl_view(main[17],csol[17],62,31)+'</td></tr>'+
           '</table></td>');
}

function slots_fight(image,nick,sl_main,sl_uids,sl_csol,vc1,vc2,vc3,wsize)
{
       var main = sl_main.split("@");
       var uids = sl_uids.split("@");
       var csol = sl_csol.split("@");
       if (!main[16]) main[16] = 'sl_l_6.gif';
       if (!main[17]) main[17] = 'sl_r_7.gif';
       if (!main[18]) main[18] = 'sl_r_5.gif';
       if (!main[19]) main[19] = 'sl_r_5.gif';
       for(var i = 16; i <= 19; i++) {
              if (!uids[i]) uids[i] = ''; if (!csol[i]) csol[i] = '';
       }

       d.write(sl_html(2)+
           '<tr><td>'+sl_view(main[0],csol[0],62,65)+'</td></tr>'+
           '<tr><td>'+sl_view(main[1],csol[1],62,35)+'</td></tr>'+
           '<tr><td>'+sl_view(main[2],csol[2],62,91)+'</td></tr>'+
           '<tr><td>'+sl_view(main[16],csol[16],62,81)+'</td></tr>'+
           '<tr><td>'+sl_view(main[7],csol[7],62,63)+'</td></tr>'+
           '</table></td>');
       d.write(sl_html(1) + '<td valign=top><table><tr><td align="center">'+inv_sl_image(image,nick,wsize)+'</td></tr>'+
           '<tr><td align="center">'+sl_view(main[13],csol[13],31,31)+sl_view(main[14],csol[14],31,31)+sl_view(main[18],csol[18],31,31)+sl_view(main[19],csol[19],31,31)+'</td></tr>'+
           '<tr><td align="center">'+sl_fight(main[4],uids[4],csol[4],vc1,20,20,4)+sl_html(3)+sl_fight(main[5],uids[5],csol[5],vc2,20,20,5)+sl_html(3)+sl_fight(main[6],uids[6],csol[6],vc3,20,20,6)+'</td></tr>'+
           '</table></td>');
       d.write(sl_html(1) + sl_html(2)+
           '<tr><td>'+sl_view(main[8],csol[8],20,20)+sl_view(main[9],csol[9],42,20)+'</td></tr>'+
           '<tr><td>'+sl_view(main[10],csol[10],62,40)+'</td></tr>'+
           '<tr><td>'+sl_view(main[11],csol[11],62,40)+'</td></tr>'+
           '<tr><td>'+sl_view(main[12],csol[12],62,91)+'</td></tr>'+
           '<tr><td>'+sl_view(main[15],csol[15],62,83)+'</td></tr>'+
           '<tr><td>'+sl_view(main[3],csol[3],62,30)+'</td></tr>'+
           '<tr><td>'+sl_view(main[17],csol[17],62,31)+'</td></tr>'+
           '</table></td>');
}

function sl_html(cs)
{
       var temp;
       switch(cs)
       {
              case 1: temp = '<td width=2 valign=top><img src=http://image.neverlands.ru/1x1.gif width=2 height=1></td>'; break;
              case 2: temp = '<td width=62 valign=top><table cellpadding=0 cellspacing=0 border=0 width=62>'; break;
              case 3: temp = '<img src=http://image.neverlands.ru/weapon/slots/1x1gr.gif width=1 height=20>'; break;
       }
       return temp;
}

function inv_sl_image(image,nick,wsize)
{
       return '<img src=http://image.neverlands.ru/obrazy/'+image+' border=0 width='+wsize+' height=255 alt="'+nick+'" title="'+nick+'" />';
}

function sl_image(image,nick,wsize)
{
       return '<td width='+wsize+' valign=top><img src=http://image.neverlands.ru/1x1.gif width=1 height=23><br><img src=http://image.neverlands.ru/obrazy/'+image+' border=0 width='+wsize+' height=255 alt="'+nick+'" title="'+nick+'" /></td>';
}

function sl_butt(m,u,v,s,w,h)
{
       var arr = m.split(":");
       var alt = arr[1];
       if(arr[2]) alt += sl_alts(arr[2],s);
       return '<input type=image src=http://image.neverlands.ru/weapon/'+arr[0]+' width='+w+' height='+h+' alt="'+alt+'" title="'+alt+'" '+(v ? 'onclick="location=\'main.php?get_id=57&uid='+u+'&s=0&vcode='+v+'\'"' : 'style="cursor: default"')+'>';
}

function sl_view(m,s,w,h)
{
       var arr = m.split(":");
       var alt = arr[1];
       if(arr[2]) alt += sl_alts(arr[2],s);
       return '<img src=http://image.neverlands.ru/weapon/'+arr[0]+' width='+w+' height='+h+' alt="'+alt+'" title="'+alt+'">';
}

function sl_fight(m,u,s,v,w,h,p)
{
       var arr = m.split(":");
       var alt = arr[1];
       if(arr[2]) alt += sl_alts(arr[2],s);
       return '<input type=image src=http://image.neverlands.ru/weapon/'+arr[0]+' width='+w+' height='+h+' alt="'+alt+'" title="'+alt+'" '+(v ? 'onclick="location=\'main.php?get_id=44&uid='+u+'&vcode='+v+'&p='+p+'&wsol='+s+'\'"' : 'style="cursor: default"')+'>';
}

function sl_alts(p,curs)
{
       var temp = '';
       var params = p.split("|");
       params[4] = parseInt(params[4]);
       if(params[0]) temp += ' ('+params[0]+')';
       if(parseInt(params[1]) !== 0) temp += "\n"+'����: '+params[1]+'-'+params[2];
       if(parseInt(params[3]) !== 0) temp += "\n"+'����� �����: +'+params[3];
       if(params[4] > 0) temp += "\n"+'������ �����: +'+params[4];
       else if(params[4] < 0) temp += "\n"+'������ �����: '+params[4];
       if(parseInt(params[5]) !== 0) temp += "\n"+'HP: +'+params[5];
       if(parseInt(params[6]) !== 0) temp += "\n"+'����: +'+params[6];
       if(curs) temp += "\n"+'�������������: '+curs+'/'+params[7];
       return temp; 
}