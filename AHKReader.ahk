; AHK VSERION: AutoHotkey_2.0-a129-78d2aa15 U32
; Author: fwt
#SingleInstance force
; TEST: 保存快照
; f1::
; {
;   html := FileRead(".\UI.html")
;   body := WebView.document.body.innerHTML
;   html := RegExReplace(html, "s)(<body.*?>).*(<\/body>)", "$1" body "$2")
;   fileobj := FileOpen("c:\Users\chnfw\Desktop\Reader\UI.html", "w")
;   fileobj.write(html)
;   fileobj.close()

;   html := FileRead(".\static\frame1.html")
;   body := f1.contentDocument.body.innerHTML
;   html := RegExReplace(html, "s)(<body.*?>).*(<\/body>)", "$1" body "$2")
;   fileobj := FileOpen("c:\Users\chnfw\Desktop\Reader\Static\frame1.html", "w")
;   fileobj.write(html)
;   fileobj.close()

;   html := FileRead(".\static\frame2.html")
;   body := f2.contentDocument.body.innerHTML
;   html := RegExReplace(html, "s)(<body.*?>).*(<\/body>)", "$1" body "$2")
;   fileobj := FileOpen("c:\Users\chnfw\Desktop\Reader\Static\frame2.html", "w")
;   fileobj.write(html)
;   fileobj.close()
; }

; {{{ 初始化
tempDir := A_Temp . "\AHKReader"
if(!DirExist(tempDir))
  DirCreate(A_Temp . "\AHKReader")
disableLocakScript(0)
MainWin := Gui("-Caption +LastFound -DPIScale","Reader")
MainWin.marginX := 0, MainWin.marginY := 0
MainWin.BackColor := "EEAA99"
WinSetTransColor("EEAA99", MainWin)
contentCtrl := MainWin.Add("ActiveX", "-E0x200 x404 y30 w1298 h766", "Shell.Explorer")
contentVeiw := contentCtrl.value
contentVeiw.Silent := True
contentVeiw.Navigate(Format("file:///{:s}/static/readme.html", A_ScriptDir))
WebViewCtrl := MainWin.Add("ActiveX", "-E0x200 w1700 h800 x0 y0", "Shell.Explorer")
WebView := WebViewCtrl.Value
WebView.Silent := True
WebView.Navigate(Format("file:///{:s}/UI.html", A_ScriptDir))
testView := MainWin.Add("ActiveX", "-E0x200 x0 y0 w0 h0", "Shell.Explorer").Value
testView.Navigate("about:blank")
MainWin.onEvent("Size", resize)
MainWin.Show("")

resize(o, minmax, w, h){ ; {{{ 自适应大小
  global WebViewCtrl, contentCtrl
  WebViewCtrl.move(0,0,w,h)
  contentCtrl.move(,,w-404, h-31)
} ; }}}


While WebView.ReadyState != 4
sleep 20
GuiHWND := MainWin.hwnd
document := WebView.Document
caption := document.getElementById("caption")
f1 := document.getElementById("frame1")
f2 := document.getElementById("frame2")
ComObjConnect(WebView, "WB_")
ComObjConnect(caption , "caption_")

caption_onmousedown(obj){ ; {{{ 窗口拖动
  global GuiHWND
  SendMessage(0xA1, 2, 0, GuiHWND)
} ; }}}

; }}}

; {{{ 读取配置文件，拉取列表

document1 := f1.contentDocument
document2 := f2.contentDocument
sourcesAll := IniRead("AHKReader.ini", "main", "source")
articleHistory := Map()
for source in StrSplit(sourcesAll, ",")
{
  url := IniRead("AHKReader.ini", source, "url")
  RegExMatch(url, "https?://[^/]*", &m)
  iconurl := m.0 . "/favicon.ico"
  selector := IniRead("AHKReader.ini", source, "Selector", "a")
  script := IniRead("AHKReader.ini", source, "Script", "")
  title := IniRead("AHKReader.ini", source, "title")
  img := "<img src='{}' OnError='setDefaultIMG(this);'></img> "
  link := "<a href='{}'><i class='fa fa-spinner fa-pulse' aria-hidden='true'></i> {}</a>"
  html := Format(img, iconurl) . format(link, url "&id=" source, title)
  ele := document1.createElement("div")
  ele.innerHTML := html
  ele.setAttribute("onclick", "onclickCallback(this);")
  ele.setAttribute("id", source)
  document1.getElementById("init").appendChild(ele)

  ele := document2.createElement("div")
  ele.setAttribute("id", source)
  history := getArticleHistory(source)
  articleHistory[source] := history[1]
  ele.innerHTML := history[2]
  document2.body.appendChild(ele)
  getlist(document1, document2, url, source, selector , script)
  SetTimer(getlist.bind(document1, document2, url, source, selector , script), 1800000)
}
; }}}

getArticleHistory(source){ ; {{{ 
  global tempDir
  file := format("{}\{}.html", tempDir, source)
  ret := Map()
  html := ""
  if(FileExist(file)){
    content := FileRead(file)
    startpos := 0
    loop(200){
      startpos += 1
      if(startpos := RegExMatch(content, '<a.*?href="(.*?)".*?<\/a>', &match, startpos))
        ret[match.1] := match.0
      else
        break
      html .= match.0
    }
  }
  return [ret, html]
} ; }}}

WB_BeforeNavigate2(pDisp, &url, &Flags, &TargetFrameName, &PostData, &Headers, &cancel, obj){ ; {{{事件：BeforeNavigate2，显隐列表，菜单
  global GuiHWND, contentVeiw,f2
  static x,y,w,h
  cancel := 1
  if(TargetFrameName = ""){ ; {{{ 主界面菜单
    RegExMatch(url, "\w+$", &r)
    minmax := obj.document.getElementById("minmax")
    Switch(r.0) {
      case "close":
        ExitApp
      case "min":
        WinMinimize(GuiHWND)
      case "max":
        WinGetPos(,,,&Trayh,"ahk_class Shell_TrayWnd")
        WinGetPos(&x,&y,&w,&h)
        WinMove(0,0,A_ScreenWidth, A_ScreenHeight - Trayh)
        minmax.setAttribute("href", "restore")
        minmax.innerText := 2
      case "restore":
        WinMove(x,y,w,h)
        minmax.setAttribute("href", "max")
        minmax.innerText := 1
      case "help":
        contentVeiw.Navigate(Format("file:///{:s}/static/readme.html", A_ScriptDir))
    } ; }}}
  } else if(TargetFrameName = "frame1") { ; {{{ 大目录树
      jQuery := f2.contentDocument.parentWindow.jQuery
    RegExMatch(url, "(.*)&id=(.*)", &r)
    source := r.2
    if(source="all"){
      jQuery("body > div").show()
    } else {
      jQuery("body > div").hide()
      jQuery("div#" . source).show()
    } ; }}}
  } else if(TargetFrameName = "frame2"){ ; {{{ 小目录树
    jQuery := f2.contentDocument.parentWindow.jQuery
    headers := jQuery("a.checked").attr("headers")
    contentVeiw.Navigate(url, Flags, "_self", PostData, headers)
  } ; }}}
} ; }}}

getlist(document1, document2, url, source, selector, script := ""){ ; {{{ 拉取数据函数。 TODO：查重，保存
  document1.parentWindow.jQuery(format("#{} > a > i", source)).show()
  method := IniRead("AHKReader.ini", source, "method", "xmlhttp")
  if(method = "xmlhttp"){
    xmlHttpGet(document1, document2, url, source, selector, script := "")
  }
  else if(method = "ie"){
    ieGet(document1, document2, url, source, selector, script := "")
  }
  else{
    MsgBox "method 请使用 ie 或 xmlhttp 或 留空"
    document1.parentWindow.jQuery(format("#{} > a > i", source)).hide()
    return
  }
} ; }}}

xmlHttpGet(document1, document2, url, source, selector, script := ""){
  static req := ComObjCreate("Msxml2.XMLHTTP.6.0")
  req.open("GET", url, true)
  req.setRequestHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.121 Safari/537.36 Edg/85.0.564.67")
  req.setRequestHeader("Accept", "text/html")
  req.onreadystatechange := xmlHttpReady.bind(req, url,document1, document2, selector, source, script)
  req.send()
}

ieGet(document1, document2, url, source, selector, script := ""){
  ie := ComObjCreate("InternetExplorer.Application")
  ; ie.Visible := True
  ie.Navigate(url)
  SetTimer(ieReady.bind(ie, document1, document2, selector, source, script, 0), -1000)
}

xmlHttpReady(req, url,document1, document2, selector, source, script) {
    Critical
    global testView
    if (req.readyState != 4)
      return
    if (req.status == 200)
    {
      try{
        text := req.responseText
        pos := RegExMatch(text, "s)<body.*?>(.*)<\/body>", &m)
        html := m.1
        document := testView.document
        document.body.innerHTML := html
        getHrefList(document, document1, document2, selector, source, script)
      }
      catch e{
        MsgBox format("Source: {} 无法请求到网页内容"
        . "`n将使用 InternetExplorer.Application 重新尝试."
        . "`n建议在配置文件中修改默认请求方式。", source)
        ieGet(document1, document2, url, source, selector, script := "")
      }
    } else {
      MsgBox format("Source: {}  Status={}"
        . "`n将使用 InternetExplorer.Application 重新尝试."
        . "`n建议在配置文件中修改默认请求方式。", source, req.status)
        ieGet(document1, document2, url, source, selector, script := "")
    }
}

ieReady(ie, document1, document2, selector, source, script, count){ ; {{{ 异步判断ReadyState并获取内容
  if count > 10{ ; 超时10秒退出
    document1.parentWindow.jQuery(format("#{} > a > i", source)).hide()
    ie.quit()
    return 0
  }

  global articleHistory
  if(ie.ReadyState = 4){
    document := ie.document
    getHrefList(document, document1, document2, selector, source, script)
    ie.quit()
  }
  else{
    SetTimer(ieReady.bind(ie, document1, document2, selector, source, script, count + 1), -1000)
  }
} ; }}}


getHrefList(document, document1, document2, selector, source, script){
  installjQuery(document)
  if(script = ""){
    script := Format("var selector='{:s}';", selector)
    . FileRead("Static\js\default.js")
  } else{
    script := FileRead("Static\js\" . script)
  }
  script .= ";"
  . format("$('#vkZBvUweQk > a').attr('owner', '{}');", source)
  . format("$('#vkZBvUweQk > a').attr('date', '{}');", SubStr(A_Now, 1, 8))   
  . "$('#vkZBvUweQk > a').attr('onclick', 'onclickCallback(this)');"
  runJS(document, script, "vkZBvUweQk")
  html := document.getElementById("vkZBvUweQk").innerHTML

  jQuery := document2.parentWindow.jQuery
  links := document.getElementById("vkZBvUweQk").getElementsByTagName("a")
  loop links.length
  {
    link := links.item(A_Index - 1) 
    if(!articleHistory[source].has(link.href))
      jQuery("div#" . source).prepend(link.outerHTML)
  }
  document1.parentWindow.jQuery(format("#{} > a > i", source)).hide()
}

installjQuery(document){ ; {{{ 安装jQuery脚本
  static jQuerymini := FileRead("Static\js\jquery.min.js")
  try {
    document.parentWindow.jQuery
  } catch e {
    ele := document.createElement("script")
    ele.setAttribute("type", "text/javascript")
    if(document.documentMode < 9)
      ele.setAttribute("text", jQuerymini)
    else
      ele.innerText := jQuerymini
    document.body.appendChild(ele)
  }
} ; }}}

runJS(document, script, returnid := ""){ ; {{{ 在网页中运行js脚本
  ele := document.createElement("script")
  ele.setAttribute("type", "text/javascript")
  if(returnid != "")
    script := "ahkReaderContainer = document.createElement('div');"
    . format("ahkReaderContainer.setAttribute('id', '{:s}');", returnid)
    . "document.body.appendChild(ahkReaderContainer);"
    . script
  if(document.documentMode < 9)
    ele.setAttribute("text", script)
  else
    ele.innerText := script
  document.body.appendChild(ele)
  return returnid
} ; }}}

disableLocakScript(arg){  ; {{{允许运行本地脚本
  static keyname := "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_LOCALMACHINE_LOCKDOWN"
  ; arg : 0允许运行本地脚本 or 1禁止运行本地脚本
  RegWrite(0, "REG_DWORD", keyname, "iexplore.exe")
} ; }}}

OnExit(exitfunc) ; {{{ 收尾
exitfunc(*){
  global f2,tempDir
  divs := f2.contentDocument.getElementsByTagName("div")
  loop divs.length
  {
    div := divs.item(A_Index - 1) 
    filepath :=  format("{}\{}.html", tempDir, div.getAttribute("id"))
    fileobj := FileOpen(filepath, "w")
    fileobj.write(div.innerHTML)
    fileobj.close()
  }
  disableLocakScript(1)
} ;}}}

