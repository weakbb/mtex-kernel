//{$APPTYPE CONSOLE}
uses windows,messages,kol,shellapi;
{$I w32.pas}{$R texaide.res}

var s:string;
begin;
	ChDir(GetStartDir);
	AddFontResource('EUCSYM.TTF');
	AddFontResource('mtextra.ttf');
    SendMessage (HWND_BROADCAST, WM_FONTCHANGE, 0, 0);
	ExecWait('regedit.exe /s _\texaide.reg',SW_HIDE);
	s:='eqnedt32.exe '+GetArgs;
	//ShellExec(s,'','',SW_SHOW);
	WinExec(PChar(s),SW_SHOW);
	//ExecWait(s,SW_SHOW);
end.