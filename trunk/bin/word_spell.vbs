'by [mathmhb]: 01/04/09 Spell checking by Winword
'Usage: wscript wps_spell.vbs "c:\path\file.ext"
Set Args = WScript.Arguments

if Args.Count=0 then
	WScript.Echo "用法：wscript word_spell.vbs 要进行拼写检查的文件（全路径）"
	WScript.Quit
end if

set Sh = WScript.CreateObject("WScript.Shell")
Set App=CreateObject("Word.application")
App.Visible=true
'Set Doc=App.Documents.Add()
'App.Selection.text=WScript.StdIn.ReadAll
Set Doc=App.Documents.Open(Args(0),false,false,false,"","",false,"","",0,0,true,false,0,true)
Doc.Range.Select
sText=Doc.Range
if not App.CheckSpelling(Doc.Range) then
	Doc.CheckSpelling
	sResult=Doc.Range
	'WScript.StdOut.Write sResult 
	if sText<>sResult then
		Doc.Save
	end if
else 
	WScript.Echo "Not found spelling errors!"
end if
App.Documents.Close
App.Quit
set App = Nothing

