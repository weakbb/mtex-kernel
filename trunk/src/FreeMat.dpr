uses windows,messages,kol,shellapi;
{$I w32.pas}{$R freemat.res}

var s:string;
begin;
	s:=GetStartDir+'Contents\bin\FreeMat.exe '+GetArgs;
	WinExec(PChar(s),SW_SHOW);
end.