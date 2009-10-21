uses
  windows,messages,kol,shellapi;{$I w32.pas}
var h:HWnd;param:Longint;i:integer;f:string;fs:PStrList;
const 
usage='本工具[mhb]将Windows字体文件调入内存。'+CR
+'格式1：WFont 字体文件名 [字体文件目录]'+CR
+'格式2：WFont @字体列表文件 [字体文件目录]';

procedure Help;
begin;
msgOK(usage);halt(0);
end;

procedure AddFont(f:PChar);
begin;
  AddFontResource(f);
  SendMessage (HWND_BROADCAST, WM_FONTCHANGE, 0, 0);
end;

begin;
  fs:=NewStrList;
  if ParamCount=0 then Help;

  if ParamCount=2 then ChDir(ParamStr(2));
  f:=ParamStr(1);
  if not (f[1]='@') then fs.Add(f) else begin;Delete(f,1,1);fs.LoadFromFile(f);end;
  for i:=0 to fs.Count do 
	  begin;f:=fs.Items[i];AddFont(PChar(f));end;
end.