{$APPTYPE CONSOLE}
uses windows,messages,kol,shellapi;//{$R yorick.res}
{$I w32.pas}

var s:string;
begin;
	s:=GetStartDir;
	s:=s+'yacas1.exe --archive '+s+'scripts.dat '+GetArgs;
	//ShellExec(s,'','',SW_SHOW);
	//WinExec(PChar(s),SW_SHOW);
	//ExecWait(s,SW_SHOW);
	RunDos(s,false,false,SW_SHOW);
end.