{$APPTYPE CONSOLE}
uses windows,messages,kol,shellapi;{$R gnuplot.res}
{$I w32.pas}

var s,exedir,ttfdir:string;
begin;
	exedir:=GetStartDir;
	SetEnv('PATH',GetEnv('PATH')+';'+exedir);
	ttfdir:=GetEnv('TTFDIR');
	if Length(ttfdir)=0 then ttfdir:=GetWindowsDir+'fonts';
	SetEnv('GDFONTPATH',ttfdir);
	SetEnv('GNUPLOT_DEFAULT_GDFONT','Arial');
	s:=exedir+'wgnuplot.exe '+GetArgs;
	//ShellExec(s,'','',SW_SHOW);
	//WinExec(PChar(s),SW_SHOW);
	ExecWait(s,SW_SHOW);
	//RunDos(s,true,true,SW_SHOW);
	DeleteFiles('plot.tmp\*.*');
	Rmdir('plot.tmp');
end.