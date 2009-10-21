{$APPTYPE CONSOLE}
uses windows,messages,kol,shellapi;{$I w32.pas}
const usage='用途：获取系统特殊文件夹的路径，结果按顺序保存于文件wfolder.sav。'+CR
	+'格式: WFOLDER [path1] [path2] ...'+CR
	+'每个路径可以$Desktop,$SendTo,$Programs,$Startup,$Start Menu等开头。';
var res,s:string;i:integer;


function Expand_Dir(s:string):string;
var d,r:string;i:integer;
begin;
Result:=s;
if pos('$',s)=1 then 
  begin;
  i:=pos('\',s);
  if i<1 then i:=Length(s)+2;
  if i>2 then 
	begin;
    d:=copy(s,2,i-2);
    delete(s,1,i-1);
    r:=GetSysDir(d);
    Result:=FileShortPath(r)+s;
    end;
  end;
end;
	
begin;
if ParamCount=0 then begin;msgok(usage);Halt(1);end;
res:='';s:='';
for i:=1 to ParamCount do begin;s:=ParamStr(i);res:=res+Expand_Dir(s)+CR;end;
StrSaveToFile('wfolder.sav',res);
write(res);
end.
