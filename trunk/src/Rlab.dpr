{$APPTYPE CONSOLE}
uses windows,messages,kol,shellapi;{$R rlab.res}
{$I w32.pas}

var s,exedir,ttfdir:string;buf:array[0..256] of char;b:DWord;p:PChar;
begin;
	//SetEnv('RLAB2_PATH',r+'demo;'+r+'rlib;'+r+'misc;'+r+'controls;');
	exedir:=GetStartDir;
	SetEnv('PATH',GetEnv('PATH')+';'+exedir+';'+exedir+'..\gnuplot');
	SetEnv('RLAB',ExcludeTrailingPathDelimiter(exedir));
	ttfdir:=GetEnv('TTFDIR');
	if Length(ttfdir)=0 then ttfdir:=GetWindowsDir+'fonts';
	SetEnv('GDFONTPATH',ttfdir);
	SetEnv('GNUPLOT_DEFAULT_GDFONT','Arial');
	b:=SearchPath(nil,'less.exe','',256,buf,p);
	if b>0 then 
		begin;//msgok(buf);
		SetEnvironmentVariable('RLAB2_PAGER',buf);
		SetEnvironmentVariable('RLAB2_HELP_PAGER',buf);
		end;
	//msgok(exedir);
	s:=exedir+'bin\Rlab.exe '+GetArgs;
	ShellExec(s,'','',SW_SHOW);
	//WinExec(PChar(s),SW_SHOW);
	//ExecWait(s,SW_SHOW);
	//RunDos(s,true,true,SW_SHOW);
end.