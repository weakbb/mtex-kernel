{$APPTYPE CONSOLE}
uses windows,messages,kol,shellapi;
{$I w32.pas}{$R tex-dos.res}
var s:string;d_quote,s_quote,i:integer;hk:HKey;
begin;
	s:=Trim(GetArgs);
	s:=GetStartDir+'4nt.exe '+s;
	//ExecWait(s,SW_SHOW);
	RunDos(s,false,false,SW_SHOW);
	Halt(GetLastError);
	//WinExec(PChar(s),SW_SHOW);
end.