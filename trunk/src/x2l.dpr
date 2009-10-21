//{$APPTYPE CONSOLE}
uses windows,messages,kol,shellapi;{$R x2l.res}
{$I w32.pas}
const MaxLen=1000;pn='Excel.exe';
var s,p:string;buf:array[0..MaxLen] of char;fn_buf:PChar;

var
 reg:HKey;
begin;
  s:=GetStartDir+'Excel2LaTeX.xla ';
  reg:=RegKeyOpenRead(HKEY_CLASSES_ROOT,'Applications\WINWORD.EXE\DefaultIcon');
  p:=RegKeyGetStr(reg,'');
  if p<>'' then p:=ExtractFilePath(p)+'\'
  else 
	if SearchPath(nil,pn,nil,MaxLen,buf,fn_buf)=0 then p:='' else p:=ExtractFilePath(buf);
  WinExec(PChar(p+pn+' '+s),SW_SHOW);
end.
