{$APPTYPE CONSOLE}
uses windows,messages,kol,shellapi;
{$I w32.pas}

var d,s:string;
begin;
	d:=ExcludeTrailingPathDelimiter(GetStartDir);
	SetEnv('RTFPATH',d);
	s:=d+'\latex2rt.exe -P '+d+' '+GetArgs;
	//ShellExec(s,'','',SW_SHOW);
	//WinExec(PChar(s),SW_SHOW);
	//ExecWait(s,SW_SHOW);
	RunDos(s,false,false,SW_SHOW);
end.