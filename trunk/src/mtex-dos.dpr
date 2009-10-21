uses windows,messages,kol,shellapi;
{$I w32.pas}{$R tex-dos.res}

var s:string;
begin;
	s:=GetStartDir+'bin\4nt.exe'; //'/k set /r '+GetStartDir+'mtex-user.env';
	ShellExec(s,'','',SW_SHOW);
	//WinExec(PChar(s),SW_SHOW);
	//ExecWait(s,SW_SHOW);
end.