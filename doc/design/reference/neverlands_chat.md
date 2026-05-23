# Neverlands Chat System — Detailed Analysis

Status: historical Neverlands reference. Canonical social/chat design lives in
`doc/design/features/social_chat_presence.md` and `doc/design/gdd.md`.

> **Source**: Live analysis from `http://www.neverlands.ru` (December 2024)
> **Purpose**: Reference for implementing Elselands chat mechanics

---

## Table of Contents
1. [Frame Structure](#frame-structure)
2. [Chat Message Processing](#chat-message-processing)
3. [Emoji System](#emoji-system)
4. [User Context Menu](#user-context-menu)
5. [Player List](#player-list)
6. [Chat Refresh System](#chat-refresh-system)
7. [CSS Styles](#css-styles)

---

## Frame Structure

### Game Frameset (game.js)

```javascript
function view_frames() {
  document.write('<frameset rows="*,8,1,240,1,30,0" FRAMEBORDER=0 FRAMESPACING=0 BORDER=0 id=mainframes>');
  document.write('<frame src="./main.php" name=main_top scrolling=YES>');           // Main game area
  document.write('<frame src="./ch/resize.html" name=resize scrolling=NO NoResize>'); // Resize handle
  document.write('<frame src="./ch/temp.html" name=temp_f scrolling=NO NoResize>');   // Temp frame
  document.write('<frameset cols="*,300">');
  document.write('<frame src="./ch/msg.php" name=chmain scrolling=YES MARGINWIDTH=2 MARGINHEIGHT=2>'); // Chat messages
  document.write('<frame src="./ch.php?lo=1" name=ch_list scrolling=YES FRAMEBORDER=0 BORDER=0 FRAMESPACING=0 MARGINWIDTH=3 MARGINHEIGHT=0>'); // Player list
  document.write('</frameset>');
  document.write('<frame src="./ch/tempw.html" name=temp_s scrolling=NO noResize>');  // Temp frame
  document.write('<frame src="./ch/but.php" name=ch_buttons scrolling=NO noResize>'); // Chat input
  document.write('<FRAME target="_top" name=ch_refr src="./ch/refr.html" noResize scrolling="no">'); // Refresh frame
  document.write('</frameset>');
}
```

### Frame Layout

```
+--------------------------------------------------+
|              main_top (main.php)                 |
|                Game content                       |
+--------------------------------------------------+
|                  resize handle                    |  8px
+--------------------------------------------------+
|                    temp_f                         |  1px
+------------------------+-------------------------+
|     chmain (msg.php)   |  ch_list (ch.php?lo=1) | 240px
|     Chat messages      |  Player list (300px)   |
+------------------------+-------------------------+
|                    temp_s                         |  1px
+--------------------------------------------------+
|              ch_buttons (but.php)                 |  30px
|              Chat input + buttons                 |
+--------------------------------------------------+
```

---

## Chat Message Processing

### Message Handler (ch_msg_v01.js)

```javascript
// Process and add chat message with emoji replacement
function add_msg(text) {
  var myRe = /script/ig;
  var pr = /^\s(\%\<[^\>]{2,20}\>\s?)+$/;  // Private message pattern
  var s = "";

  // Security: Replace 'script' tags
  text = text.replace(myRe, 'скрипт');

  var spl = text.split("<BR>");
  for (var k = 0; k < spl.length; k++) {
    var txt = spl[k];

    if (txt.length > 8) {
      // Skip malformed font tags
      var re = /\<font\s$/;
      if (re.test(txt)) continue;

      var i, j = 0;

      // Replace emoji codes with images (max 3 per message)
      for (i = 0; i < sm.length; i++) {
        while (txt.indexOf(':' + sm[i] + ':') >= 0) {
          txt = txt.replace(':' + sm[i] + ':',
            smilesimgpath + 'smiles_' + sm[i] + '.gif ' +
            smilesimgstyle + sm[i] + '\')">');
          if (++j >= maxsmiles) break;
        }
        if (j >= maxsmiles) break;
      }

      // Handle private messages (format: timestamp<SPL>from<SPL>message)
      if (txt.indexOf('<SPL>') > 0) {
        var msgp = txt.split('<SPL>');
        var j = msgp[1].indexOf('<SPAN>');
        var i = msgp[1].indexOf('</SPAN>');
        var user2;
        user2 = msgp[1].substring(j + 6, i);

        if (msgp[2] != '') {
          msgp[2] = ' ' + msgp[2];

          // Private message styling
          if (pr.test(msgp[2])) {
            msgp[1] = '>>> ' + msgp[1];
            while (msgp[2].indexOf('>') >= 0) msgp[2] = msgp[2].replace('>', ':');
            while (msgp[2].indexOf('%<') >= 0) msgp[2] = msgp[2].replace('%<', '> ');

            if (user2 != '')
              msgp[1] = msgp[1].replace('<SPAN>', '<SPAN alt="%' + user2 + '">');

            // Highlight if message is to current user
            if (msgp[2].indexOf('> ' + user + ':') >= 0) {
              if (user2 != '')
                msgp[2] = msgp[2].replace(user, '<SPAN alt="%' + user2 + '">' + user + '</SPAN>');
              msgp[0] = msgp[0].replace('<font class=chattime>', '<font class=prchattime>');
            }
          } else {
            while (msgp[2].indexOf('<') >= 0) msgp[2] = msgp[2].replace('<', '');
            while (msgp[2].indexOf('>') >= 0) msgp[2] = msgp[2].replace('>', ':');

            // Highlight if message mentions current user
            if (msgp[2].indexOf(' ' + user + ':') >= 0) {
              if (user2 != '')
                msgp[2] = msgp[2].replace(' ' + user,
                  ' <SPAN alt="' + user2 + '">' + user + '</SPAN>');
              msgp[0] = msgp[0].replace('<font class=chattime>', '<font class=yochattime>');
            }
            msgp[2] = '&nbsp;для' + msgp[2];
          }
        }
        txt = msgp.join('');
      }

      s += txt + "<BR>";
    }
  }

  // Append to chat container
  e_m = get_by_id('msg');
  e_m.innerHTML += s;

  // Scroll to bottom
  window.scrollBy(0, 65000);
}
```

---

## Emoji System

### Emoji Code Array

```javascript
// Complete list of 170+ emoji codes
var sm = new Array(
  '001', '002', '003', '004', '005', '007', '008', '009', '006', '010',
  '011', '012', '013', '014', '015', '016', '000', '018', '021', '022',
  '019', '023', '024', '025', '026', '027', '028', '031', '032', '034',
  '033', '037', '038', '036', '040', '039', '043', '049', '052', '056',
  '059', '057', '062', '066', '068', '073', '082', '080', '079', '083',
  '086', '085', '114', '118', '119', '123', '161', '158', '164', '167',
  '166', '170', '174', '177', '175', '179', '178', '186', '189', '188',
  '190', '202', '205', '203', '206', '221', '237', '239', '238', '243',
  '246', '254', '253', '255', '277', '276', '275', '278', '284', '289',
  '288', '294', '293', '295', '310', '313', '324', '336', '347', '346',
  '345', '348', '349', '351', '352', '361', '362', '366', '367', '382',
  '393', '411', '415', '413', '419', '422', '434', '442', '447', '453',
  '467', '471', '472', '475', '551', '554', '559', '564', '568', '573',
  '029', '030', '077', '126', '127', '131', '155', '156', '267', '297',
  '319', '350', '353', '354', '357', '358', '368', '376', '385', '386',
  '414', '417', '457', '459', '469', '473', '474', '477', '552', '558',
  '560', '570', '574', '575', '576', '579', '600', '601', '602', '603',
  '604', '605', '606', '607', '608', '609', '610', '611', '612', '613',
  '614', '615', '616', '617', '618', '619', '620', '621', '622', '623',
  '624', '625', '626', '627', '628', '629', '630', '631', '632', '633',
  '634', '635', '636', '637', '638', '639', '640', '641', '642', '643',
  '644', '645', '646', '647', '648', '650', '651', '652', '653', '654',
  '655', '656', '657', '950', '951', '952', '953', '954', '955', '956',
  '957', '958', '959', '960'
);

var maxsmiles = 3;  // Maximum smiles per message
var smilesimgpath = '<img border=0 src=http://image.neverlands.ru/chat/smiles/';
var smilesimgstyle = ' style="cursor:pointer" onclick="ins_smile(\'';
```

### Insert Emoji Function

```javascript
// Insert smile code into chat input
function ins_smile(smile) {
  top.frames['ch_buttons'].document.FBT.text.focus();
  top.frames['ch_buttons'].document.FBT.text.value += ' :' + smile + ': ';
}
```

### Emoji URL Pattern
- Format: `http://image.neverlands.ru/chat/smiles/smiles_{CODE}.gif`
- Example: `http://image.neverlands.ru/chat/smiles/smiles_001.gif`

---

## User Context Menu

### Menu Handler

```javascript
// Open user context menu on right-click
function ch_open_menu(e) {
  var e = e || window.event;
  var el, x, y, login, login2;

  el = document.getElementById('user_menu');
  var o = e.target || e.srcElement;

  // Only trigger on SPAN elements (usernames)
  if (o.tagName != "SPAN") return true;

  // Calculate menu position
  x = e.clientX + document.documentElement.scrollLeft + document.body.scrollLeft - 4;
  y = e.clientY + document.documentElement.scrollTop + document.body.scrollTop;
  y -= e.clientY + 72 > document.body.clientHeight ? 70 : 2;  // Flip if near bottom

  login = o.innerHTML;
  e.returnValue = false;

  // URL encode special characters in username
  login2 = login;
  while (login2.indexOf(' ') >= 0) login2 = login2.replace(' ', '%20');
  while (login2.indexOf('+') >= 0) login2 = login2.replace('+', '%2B');
  while (login2.indexOf('#') >= 0) login2 = login2.replace('#', '%23');
  while (login2.indexOf('?') >= 0) login2 = login2.replace('?', '%3F');

  // Build menu HTML
  el.innerHTML =
    '<a class="usermenulink" href="javascript:top.say_private(\'' + login + '\');ch_hmenu()">Приват</a>' +
    '<a class="usermenulink" href="' + SOURCE_PUBLIC_CHARACTER_INFO_URL + login2 +
      '" target="_blank" onclick="ch_hmenu();return true;">Информация</a>' +
    '<a class="usermenulink" href="javascript:ch_copy_nick(\'' + login + '\');ch_hmenu()">Копировать ник</a>' +
    '<a class="usermenulink" href="javascript:ch_set_ignor(\'' + login + '\');ch_hmenu()">Игнорировать</a>';

  // Position and show menu
  el.style.left = x + "px";
  el.style.top = y + "px";
  el.style.visibility = "visible";

  return false;
}

// Hide menu
function ch_hmenu() {
  document.getElementById("user_menu").style.visibility = "hidden";
  document.getElementById("user_menu").style.top = "0px";
  top.frames['ch_buttons'].document.FBT.text.focus();
}

// Close menu on mouse leave
function ch_close_menu(e) {
  var e = e || window.event;
  var te = e.relatedTarget || e.toElement;

  if (e && te) {
    var cls = te.className;
    if (cls == 'usermenulink' || cls == 'usermenu') return;
  }

  document.getElementById("user_menu").style.visibility = "hidden";
  document.getElementById("user_menu").style.top = "0px";
  return false;
}
```

### Menu Actions

```javascript
// Set ignore flag for user
function ch_set_ignor(nick) {
  // URL encode special characters
  while (nick.indexOf('=') >= 0) nick = nick.replace('=', '%3D');
  while (nick.indexOf('+') >= 0) nick = nick.replace('+', '%2B');
  while (nick.indexOf('#') >= 0) nick = nick.replace('#', '%23');
  while (nick.indexOf(' ') >= 0) nick = nick.replace(' ', '%20');

  top.frames['ch_refr'].location = '/ch.php?a=ign&s=1&u=' + nick;
}

// Copy nickname to clipboard (IE only)
function ch_copy_nick(nick) {
  var cpn = get_by_id('cpnick');
  cpn.innerHTML = nick;

  if (window.clipboardData) {
    var cp = cpn.createTextRange();
    cp.execCommand("RemoveFormat");
    cp.execCommand("Copy");
  }
}

// Handle username click (regular vs Ctrl vs Alt)
function to_what_who(e) {
  var e = e || window.event;
  var o = e.target || e.srcElement;

  if (o.tagName == "SPAN") {
    var login = o.innerHTML;
    if (o.alt != null && o.alt.length > 0) login = o.alt;

    if (login.charAt(0) == '%') {
      // Alt-click: send private message
      login = login.replace('%', '');
      top.say_private(login);
    } else {
      // Regular click: address message to user
      top.say_to(login);
    }
  }
  return false;
}
```

---

## Player List

### Player List Builder (ch_list.js)

```javascript
// Sort functions
function reverse_alpha_sort(el1, el2) {
  if (el1 > el2) return -1;
  else if (el1 < el2) return 1;
  else return 0;
}

// Quicksort by string (name)
function qsort_str(arr, first, last) {
  if (first < last) {
    point = arr[first].split(":")[0];
    i = first;
    j = last;
    while (i < j) {
      while ((arr[i].split(":")[0] <= point) && (i < last)) i++;
      while ((arr[j].split(":")[0] >= point) && (j > first)) j--;
      if (i < j) {
        temp = arr[i];
        arr[i] = arr[j];
        arr[j] = temp;
      }
    }
    temp = arr[first];
    arr[first] = arr[j];
    arr[j] = temp;
    qsort_str(arr, first, j - 1);
    qsort_str(arr, j + 1, last);
  }
}

// Quicksort by integer (level)
function qsort_int(arr, first, last, h) {
  if (first < last) {
    point = parseInt(arr[first].split(":")[2]);
    i = first;
    j = last;
    while (i < j) {
      while ((h * parseInt(arr[i].split(":")[2]) <= h * point) && (i < last)) i++;
      while ((h * parseInt(arr[j].split(":")[2]) >= h * point) && (j > first)) j--;
      if (i < j) {
        temp = arr[i];
        arr[i] = arr[j];
        arr[j] = temp;
      }
    }
    temp = arr[first];
    arr[first] = arr[j];
    arr[j] = temp;
    qsort_int(arr, first, j - 1, h);
    qsort_int(arr, j + 1, last, h);
  }
}

// Build player list display
function chatlist_build(sort_type) {
  // Sort based on type
  if (sort_type == 'a_z')
    ChatListU.sort();
  else if (sort_type == 'z_a')
    ChatListU.sort(reverse_alpha_sort);
  else {
    if (sort_type == '0_33') {
      qsort_int(ChatListU, 0, ChatListU.length - 1, 1);  // Low to high
    } else if (sort_type == '33_0') {
      qsort_int(ChatListU, 0, ChatListU.length - 1, -1); // High to low
    }
    // Secondary sort by name within same level
    f = 0;
    fl = parseInt(ChatListU[f].split(":")[2]);
    for (i = 1; i < ChatListU.length; i++) {
      n = i;
      nl = parseInt(ChatListU[i].split(":")[2]);
      if (fl != nl) {
        qsort_str(ChatListU, f, n - 1);
        f = n;
        fl = parseInt(ChatListU[f].split(":")[2]);
      }
      if (n == ChatListU.length - 1) {
        qsort_str(ChatListU, f, n);
      }
    }
  }

  // Render each player
  for (var cou = 0; cou < ChatListU.length; cou++) {
    // Data format: "sortkey:name:level:sign;signName;signShort:silence:ignored:injury:dealer:alignment"
    str_array = ChatListU[cou].split(":");

    var ss = '';      // Sign icon
    var sleeps = '';  // Silence icon
    var altadd = '';  // Sign tooltip
    var ign = '';     // Ignore icon
    var inj = '';     // Injury icon
    var psg = '';     // Dealer icon
    var align = '';   // Alignment icon

    nn_sec = str_array[1];
    var login = str_array[1];

    // Handle italic (offline) names
    if (login.indexOf('<i>') > -1) {
      login = login.replace('<i>', '').replace('</i>', '');
      nn_sec = nn_sec.replace('<i>', '').replace('</i>', '');
    }

    // Clan sign
    if (str_array[3].length > 1) {
      sign_array = str_array[3].split(";");
      if (sign_array[2].length > 1) altadd = " (" + sign_array[2] + ")";
      ss = "<img src=http://image.neverlands.ru/signs/" + sign_array[0] +
           " width=15 height=12 align=absmiddle alt=\"" + sign_array[1] + altadd + "\">&nbsp;";
    }

    // Silence icon
    if (str_array[4].length > 1)
      sleeps = "<img src=http://image.neverlands.ru/signs/molch.gif width=15 height=12 border=0 alt=\"" +
               str_array[4] + "\" align=absmiddle>";

    // Ignored user icon
    if (str_array[5] == '1')
      ign = "<a href=\"javascript:ch_clear_ignor('" + login + "');\">" +
            "<img src=http://image.neverlands.ru/signs/ignor/3.gif width=15 height=12 border=0 alt=\"Снять игнорирование\"></a>";

    // Injury icon
    if (str_array[6] != '0')
      inj = "<img src=http://image.neverlands.ru/chat/tr4.gif width=15 height=12 border=0 alt=\"" +
            str_array[6] + "\" align=absmiddle>";

    // Dealer icon
    if (str_array[7] != '0') {
      var dilers = ['', 'Дилер', '', '', '', '', '', '', '', '', '', 'Помощник дилера'];
      psg = "<img src=http://image.neverlands.ru/signs/d_sm_" + str_array[7] +
            ".gif width=15 height=12 align=absmiddle border=0 alt=\"" + dilers[str_array[7]] + "\">&nbsp;";
    }

    // Alignment icon
    if (str_array[8] != '0') {
      sign_array = str_array[8].split(";");
      align = "<img src=http://image.neverlands.ru/signs/" + sign_array[0] +
              " width=15 height=12 align=absmiddle border=0 alt=\"" + sign_array[1] + "\">&nbsp";
    } else if (str_array[7] == '0') {
      align = "<img src=http://image.neverlands.ru/1x1.gif width=15 height=12 align=absmiddle border=0 alt=\"\">&nbsp";
    }

    // Output player entry
    document.write(
      "<img src=http://image.neverlands.ru/1x1.gif width=5 height=0>" +
      "<a href=\"javascript:top.say_private('" + login + "')\">" +
        "<img src=http://image.neverlands.ru/chat/private.gif width=11 height=12 border=0 align=absmiddle></a>&nbsp;" +
      psg + align + ss +
      "<a href=\"javascript:top.say_to('" + login + "')\">" +
        "<font class=nickname><b>" + str_array[1] + "</b></a>[" + str_array[2] + "]</font>" +
      "<a href=\"" + SOURCE_PUBLIC_CHARACTER_INFO_URL + nn_sec + "\" target=_blank>" +
        "<img src=http://image.neverlands.ru/chat/info.gif width=11 height=12 border=0 align=absmiddle></a>" +
      sleeps + "&nbsp;" + ign + "&nbsp;" + inj + "<br>"
    );
  }
}
```

---

## Chat Refresh System

### Refresh Configuration (game.js)

```javascript
var ChatTimerID = -1;      // Chat refresh timer ID
var ChatDelay = 12;        // Refresh interval (seconds)
var ChatFyo = 0;           // Chat mode: 0=all, 1=private only, 2=none
var lmid = -1;             // Last message ID
var OnlineDelay = 60;      // Player list refresh (seconds)
var OnlineTimerOn = -1;    // Player list timer ID
var OnlineStop = 1;        // Player list refresh enabled
var OnlineScrollPosition = 0;  // Scroll position memory

var ChatClearTimerID = -1; // Chat cleanup timer
var ChatClearDelay = 600;  // Cleanup interval (10 min)
var ChatClearSize = 12228; // Max chat content size (bytes)
```

### Refresh Functions

```javascript
// Refresh chat messages
function ch_refresh() {
  if (ChatTimerID >= 0) clearTimeout(ChatTimerID);
  ChatTimerID = setTimeout('ch_refresh()', ChatDelay * 1000);
  top.frames['ch_refr'].location = '/ch.php?' + Math.random() + '&show=1&fyo=' + ChatFyo;
}

// Stop chat refresh
function ch_stop_refresh() {
  if (ChatTimerID >= 0) clearTimeout(ChatTimerID);
  ChatTimerID = -1;
}

// Schedule next refresh
function ch_refresh_n() {
  if (ChatTimerID >= 0) clearTimeout(ChatTimerID);
  ChatTimerID = setTimeout('ch_refresh()', ChatDelay * 1000);
}

// Refresh player list
function online_reload(now) {
  if (OnlineTimerOn >= 0) {
    clearTimeout(OnlineTimerOn);
    if (!OnlineStop)
      OnlineTimerOn = setTimeout('online_reload(0)', OnlineDelay * 1000);
    else
      OnlineTimerOn = -1;
  }
  if (!OnlineStop || now)
    top.frames['ch_list'].location = '/ch.php?lo=1';
}

// Clean up old chat messages
function ch_refresh_clr() {
  if (ChatClearTimerID >= 0) clearTimeout(ChatClearTimerID);
  ChatClearTimerID = setTimeout('ch_refresh_clr()', ChatClearDelay * 1000);

  var s = top.frames['chmain'].document.all('msg').innerHTML;
  if (s.length > ChatClearSize) {
    // Keep only last portion
    var j = s.lastIndexOf('<BR>', s.length - ChatClearSize);
    top.frames['chmain'].document.all('msg').innerHTML = s.substring(j, s.length);
  }
}
```

### Chat Mode Toggle

```javascript
// Cycle through chat modes: All -> Private Only -> None -> All
function change_chatsetup() {
  if (ChatFyo == 0) {
    ChatFyo = 1;
    top.frames['ch_buttons'].document.FBT.fyo.value = 1;
    top.frames['ch_buttons'].document.FBT.schat.src = 'http://image.neverlands.ru/chat/bb3_me.gif';
    top.frames['ch_buttons'].document.FBT.schat.alt = 'Режим чата (Показывать только личные сообщения)';
  } else if (ChatFyo == 1) {
    ChatFyo = 2;
    top.frames['ch_buttons'].document.FBT.fyo.value = 2;
    ch_stop_refresh();  // Stop refresh when chat disabled
    top.frames['ch_buttons'].document.FBT.schat.src = 'http://image.neverlands.ru/chat/bb3_none.gif';
    top.frames['ch_buttons'].document.FBT.schat.alt = 'Режим чата (Не показывать сообщения)';
  } else {
    ChatFyo = 0;
    top.frames['ch_buttons'].document.FBT.fyo.value = 0;
    ch_refresh();  // Resume refresh
    top.frames['ch_buttons'].document.FBT.schat.src = 'http://image.neverlands.ru/chat/bb3_all.gif';
    top.frames['ch_buttons'].document.FBT.schat.alt = 'Режим чата (Показывать все сообщения)';
  }
}

// Change refresh speed: 10s -> 30s -> 60s -> 10s
function change_chatspeed() {
  if (ChatTimerID >= 0) clearTimeout(ChatTimerID);

  if (ChatDelay == 10) ChatDelay = 30;
  else if (ChatDelay == 30) ChatDelay = 60;
  else ChatDelay = 10;

  ChatTimerID = setTimeout('ch_refresh()', ChatDelay * 1000);
  top.frames['ch_buttons'].document.FBT.spchat.src = 'http://image.neverlands.ru/chat/bb_' + ChatDelay + '.gif';
  top.frames['ch_buttons'].document.FBT.spchat.alt = 'Скорость обновления (раз в ' + ChatDelay + ' секунд)';
}
```

---

## CSS Styles

### Chat Message Styles (main.css)

```css
/* Regular chat text */
.chattxt {
  font-family: Verdana, Tahoma, Helvetica;
  text-decoration: none;
  color: #000000;
  font-size: 10pt;
}

/* Timestamp */
.chattime {
  font-family: Tahoma, Verdana, Arial;
  font-size: 11px;
  text-decoration: none;
  color: #003366;  /* Blue */
}

/* Highlighted (message mentions you) */
.yochattime {
  font-family: Tahoma, Verdana, Arial;
  font-size: 11px;
  text-decoration: none;
  color: #ffffff;
  background-color: #6699bb;  /* Blue background */
}

/* Private message */
.prchattime {
  font-family: Tahoma, Verdana, Arial;
  font-size: 11px;
  text-decoration: none;
  color: #ffffff;
  background-color: #D16F67;  /* Red/pink background */
}

/* Mass/system message */
.massm {
  font-family: Tahoma, Verdana, Arial;
  font-size: 11px;
  text-decoration: none;
  color: #ffffff;
  background-color: #EF6B00;  /* Orange background */
}

/* Username */
.nickname {
  font-family: Verdana, Arial;
  font-size: 12px;
  text-decoration: none;
  color: #222222;
}
```

### User Menu Styles

```css
/* Context menu container */
.usermenu {
  background-color: #FCFAF3;
  border-color: #B9A05C #A9904C #A9904C #B9A05C;
  border-style: solid;
  border-width: 1px;
  position: absolute;
  left: 0px;
  top: 0px;
  visibility: hidden;
}

/* Menu link */
a.usermenulink {
  font-family: Tahoma, Arial, Verdana;
  font-size: 11px;
  font-weight: bold;
  color: #222222;
  border: 0px solid #000000;
  padding: 2px 12px 2px 12px;
  display: block;
  text-decoration: none;
}

/* Menu link hover */
a.usermenulink:hover {
  background-color: #F3ECD7;
  color: #336699;
}
```

---

## Key Implementation Notes

| Feature | Neverlands | Elselands |
|---------|------------|-----------|
| Transport | iframes | ActionCable WebSocket |
| Refresh | Polling (10-60s) | Real-time push |
| Emoji | :CODE: → img | Source-backed smile assets, not Unicode shortcut maps |
| Context menu | onclick/oncontextmenu | Stimulus controller |
| Private messages | %<user> prefix | %<user> addressing shape |

---

*Last updated: December 2024 (Live server analysis)*
