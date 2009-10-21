'by [mathmhb]: 01/04/09 Spell Checking by Kingsoft WPS
'Usage: wscript wps_spell.vbs "c:\path\file.ext"
Set Args = WScript.Arguments

if Args.Count=0 then
	WScript.Echo "用法：wscript wps_spell.vbs 要进行拼写检查的文件（全路径）"
	WScript.Quit
end if

set Sh = WScript.CreateObject("WScript.Shell")
Set App=CreateObject("wps.application")
App.Visible=true
'Set Doc=App.Documents.Add()
'App.Selection.text="hellox worldx"
Set Doc=App.Documents.Open(Args(0),false,false,false,"","",false,"","",0,0,true,false,0,true)
Sh.SendKeys "{F7}"
'WScript.Sleep 5000	
'App.Documents.Close
'App.Quit(true)
'set App = Nothing

