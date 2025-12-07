var xmlhttp = false;
var arr_res;

function GetHttpRequest()
{
	var xmlHttpObj = false;
	if(window.XMLHttpRequest)
	{
		// IE7+, Firefox, Chrome, Opera, Safari
		xmlHttpObj = new XMLHttpRequest();
	}
	else if(window.ActiveXObject)
	{
		// IE6, IE5
		try
		{
			xmlHttpObj = new ActiveXObject('Microsoft.XMLHTTP');
		}
		catch(e)
		{
			try
			{
				xmlHttpObj = new ActiveXObject('Msxml2.XMLHTTP');                     
			}
			catch(e){}
		}
	}
	return xmlHttpObj;
}

function AjaxGetSync(script, callback_func)
{
    if(!xmlhttp) 
    {
        xmlhttp = GetHttpRequest();
        if(!xmlhttp) return;
    }
    xmlhttp.open('GET','./gameplay/ajax/'+script, false);
    if (typeof(callback_func) == 'undefined')
    {
        xmlhttp.onreadystatechange = AjaxProcessChange;
    }
    else
    {
        xmlhttp.onreadystatechange = function() {
            if (xmlhttp.readyState == 4 && xmlhttp.status == 200) {
                var response = xmlhttp.responseText;
                callback_func(response);
            }
        }
    }
    xmlhttp.send(null);
}

function AjaxGet(script, callback_func)
{
	if(!xmlhttp) 
	{
		xmlhttp = GetHttpRequest();
		if(!xmlhttp) return;
	}
	xmlhttp.open('GET','./gameplay/ajax/'+script,true);
    if (typeof(callback_func) == 'undefined')
    {
	    xmlhttp.onreadystatechange = AjaxProcessChange;
    }
    else
    {
        xmlhttp.onreadystatechange = function() {
            if (xmlhttp.readyState == 4 && xmlhttp.status == 200) {
                var response = xmlhttp.responseText;
                callback_func(response);
            }
        }
    }
	xmlhttp.send(null);
}

function AjaxPost(script, data, callback_func)
{
    if(!xmlhttp) 
    {
        xmlhttp = GetHttpRequest();
        if(!xmlhttp) return;
    }
    xmlhttp.open('POST','./gameplay/ajax/'+script,true);
    xmlhttp.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
    xmlhttp.setRequestHeader("Content-length", data.length);
    xmlhttp.setRequestHeader("Connection", "close");
    
    if (typeof(callback_func) == 'undefined')
    {
        xmlhttp.onreadystatechange = AjaxProcessChange;
    }
    else
    {
        xmlhttp.onreadystatechange = function() {
            if (xmlhttp.readyState == 4 && xmlhttp.status == 200) {
                var response = xmlhttp.responseText;
                callback_func(response);
            }
        }
    }
    
    var data_str = '';
    data['r'] = Math.random();
    for (k in data)
        data_str += (data_str != '' ? '&' : '') + encodeURIComponent(k) + '=' + encodeURIComponent(data[k]);
    xmlhttp.send(data_str);
}

function AjaxProcessChange()
{
    if(xmlhttp.readyState == 4)
    {
        if(xmlhttp.status == 200)
        {
	        var ret = xmlhttp.responseText;
	        if(ret != 'ERR') 
            {
                arr_res = ret.split('@');
                if(arr_res[0] != 'QUEST') StateReady();
                else QuestReady();    
            }
        }
    }
}