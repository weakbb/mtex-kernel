{$APPTYPE console}
uses windows,messages,winspool,kol,shellapi;{$I w32.pas}
const 
usage='用法：IS_PRINTER 打印机名字 ＝＝）检查指定的打印机是否存在'+CR
	+'返回值：1 [YES] 打印机名字合法；2 [NO] 打印机名字非法。';
	
	
var h:Cardinal;
begin;
  if ParamCount=0 then 
	  begin;writeln(usage);halt(0);end;
  if OpenPrinter(PChar(ParamStr(1)),h,nil) then 
	  begin;ClosePrinter(h);writeln('YES');halt(1);end 
  else 
	  begin;writeln('NO');halt(2);end;
end.
