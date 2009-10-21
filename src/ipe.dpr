//{$APPTYPE CONSOLE}
uses windows,messages,kol,shellapi;
{$I w32.pas}

var s:string;
begin;
	s:=GetStartDir+'bin\ipe.exe '+GetArgs;
	//ShellExec(s,'','',SW_SHOW);
	WinExec(PChar(s),SW_SHOW);
	//ExecWait(s,SW_SHOW);
end.
