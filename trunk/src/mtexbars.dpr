uses windows,messages,kol,shellapi;
{$I w32.pas}{$R mtexbars.res}

function FindFirst(f:string):string;
var s:string;h:THandle; fd:WIN32_FIND_DATA;
begin;
	Result:='';
	h:=FindFirstFile(PChar(f),fd);
	if h=INVALID_HANDLE_VALUE then Exit;
	Result:=fd.cFileName;
end;

var s:string;r,p:string;


begin;
	s:=GetStartDir+'bin\4nt.exe /c ';
	r:=GetSysDir('SendTo');//msgok(r);
	p:=FindFirst(r+'\TeX-DOS*.lnk');//msgok(p);
	if p='' then 
		s:=s+'call tex-lnk.btm -SendTo %+ ';
	s:=s+'tmac.exe '+GetArgs;
	//ShellExec(s,'','',SW_SHOW);
	WinExec(PChar(s),SW_HIDE);
	//ExecWait(s,SW_SHOW);
end.