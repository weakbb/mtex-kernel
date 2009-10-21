uses windows,messages,kol,shellapi;
{$I w32.pas}{$R tex-edt.res}

var s:string;
begin;
	//s:=GetStartDir+'bin\4nt.exe /c tex-edit.btm';
	//WinExec(PChar(s),SW_HIDE);
	
	ShellExec(GetStartDir+'bin\4nt.exe','/c tex-edit.btm','',SW_SHOW);
	
	//ExecWait(s,SW_SHOW);
end.