{$APPTYPE CONSOLE}
uses windows,messages,kol,shellapi;{$R mlab.res}
{$I w32.pas}
const keys=#13+'3031-362c-2834-3181-2d28-dc2c-4026-26e0'+#13;
var exedir,s:string;h:THandle;
begin;
	exedir:=GetStartDir;
	if FileExists(exedir+'INIT_.FIL') then
		StrSaveToFile(exedir+'INIT0.FIL',StrLoadFromFile(exedir+'INIT_.FIL'));
	s:=exedir+'Mlab0.exe '+GetArgs;	
	ShellExec(s,'',exedir,SW_SHOW);
	h:=0;
	repeat
		h:=FindW('MLAB');
	until h>0;
	sleep(1000);
	SendStrTo(keys,h);
		
	//WinExec(PChar(s),SW_SHOW);
	//ExecWait(s,SW_SHOW);
end.