uses
  windows,messages,kol,shellapi;{$I w32.pas}
var h:HWnd;param:Longint;title:string;

{
Function EnumWindowsProc (Wnd: HWND; LParam: LPARAM): BOOL; stdcall;
var s:string;
begin
Result := True;s:=UpperCase(GetText(Wnd));msgok(s);
if Pos(s,'START')=1 then exit;
if (IsWindowVisible(Wnd) or IsIconic(wnd)) and
((GetWindowLong(Wnd, GWL_HWNDPARENT) = 0) or
(GetWindowLong(Wnd, GWL_HWNDPARENT) = GetDesktopWindow)) and
(GetWindowLong(Wnd, GWL_EXSTYLE) and WS_EX_TOOLWINDOW = 0) then
  if Pos(UpperCase(title),s)>0 then 
    begin;CloseW(Wnd);Halt(1); end;
end;
}

procedure Help;
begin;msgOK('本工具[mhb]关闭Windows的程序或窗口。格式：WClose [*]窗口标题特征串');halt(0);end;


begin 
if ParamCount=0 then Help;
title:=GetArgs;
if title[1]='*' then begin;Delete(title,1,1);h:=Find_W(title);end else h:=FindW(title);
if h<>0 then begin;CloseW(h);Halt(1);end;
//EnumWindows(@EnumWindowsProc , Param);
end.

