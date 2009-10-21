uses windows,messages,kol,shellapi;
{$I w32.pas}{$R mtex.res}

var s:string;
begin;
	s:=GetStartDir+'bin\4nt.exe /c main.btm '+GetArgs;
	//ShellExec(GetStartDir+'bin\4nt.exe','/c main.btm','',SW_SHOW);
	WinExec(PChar(s),SW_HIDE);
	//ExecWait(s,SW_SHOW);
end.