{$APPTYPE CONSOLE}
uses windows,messages,kol,shellapi;
{$I w32.pas}

var d,s:string;
begin;
	d:=GetStartDir;
	SetEnv('rtf2latex2e_dir',ExcludeTrailingPathDelimiter(d));
	s:=d+'rtf2latex2e.exe '+GetArgs;
	//ShellExec(s,'','',SW_SHOW);
	//WinExec(PChar(s),SW_SHOW);
	//ExecWait(s,SW_SHOW);
	RunDos(s,false,false,SW_SHOW);
end.