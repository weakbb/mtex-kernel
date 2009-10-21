{$APPTYPE CONSOLE}
uses windows,messages,kol,shellapi;
{$I w32.pas}

function GetHelpUrl:string;
var k,s,exedir:string;
begin;
	exedir:=GetStartDir;
	k:=GetArgs;
	StrReplace(k,'"','');StrReplace(k,'"','');
	Result:='file://'+exedir+'doc\refmanual.html';
	if k='file://' then Exit;
	Result:=k;
	if Pos('file://#',k)=0 then Exit;
	k:=Trim(Copy(k,9,256));//Writeln(k);
	//Result:='file://localhost/'+StrReplaceAll(exedir,'\','/')+'doc/ref.html?'+k;
	
	s:='grep -i -l "<hr>'+k+' --" '+exedir+'doc\ref*.html';//Writeln(s);
	s:=RunDos(s,true,false,SW_SHOW);
	StrReplace(s,#13,'');StrReplace(s,#10,'');
	if s<>'' then Result:='file://localhost/'+StrReplaceAll(s,'\','/')+'#'+k;
	
end;

var s:string;//W:PControl;Br1:PKOLWebBrowser;
begin;
	s:=GetHelpUrl;Writeln(s);
	//W:=NewForm(nil,'Help');
	//Br1:=NewKOLWebBrowser(W);
	//Br1.Navigate(s);
	//Run(W);
	ShellExec(s,'','',SW_SHOW);
	//WinExec(PChar(s),SW_SHOW);
	//ExecWait(s,SW_SHOW);
end.