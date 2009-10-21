//{$APPTYPE CONSOLE}
uses windows,messages,kol,shellapi;
{$I w32.pas}{$R tex-edt.res}
const title='tex-edt.exe';title2='TEX-DOS';

var s:string;h:THandle;
begin;
	h:=Find_W(title);
	if h<>0 then CloseW(h);
	h:=Find_W(title2);
	if h<>0 then CloseW(h);
	 
	s:=GetStartDir+'4nt.exe /c TEX-EDIT.btm '+Trim(GetArgs);
	//ExecWait(s,SW_SHOW);
	WinExec(PChar(s),SW_HIDE);
	//RunDos(s,false,false,SW_SHOW);
	Halt(GetLastError);
	//WinExec(PChar(s),SW_SHOW);
end.