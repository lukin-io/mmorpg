var curTimeFor;
var curTimeInt;

function KeyInsert(number)
{
       d.FEND.code.value += number;      
}

function BackKey()
{
       var str = d.FEND.code.value;
       var leng = str.length;
       d.FEND.code.value = str.substring(0,leng-1);      
}

function KeyBlock(tfor)
{
       curTimeFor = tfor;
       curTimeInt = setInterval("KeyClock()",1000);
}

function KeyClock()
{
       if(curTimeFor > 0)
       {
	      d.getElementById('fkey').innerHTML = '<font color=#CC0000><B>������ �� ������� [ ��� '+curTimeFor+' ��� ]</B></font>';
	      curTimeFor = curTimeFor - 1;
       }
       else
       {
              clearInterval(curTimeInt);
	      window.location = "./main.php";
       }
}