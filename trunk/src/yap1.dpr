uses
  windows,messages,kol,shellapi;{$I w32.pas}
var h:HWnd;param:Longint;title,fn:string;T:PTimer;cnt:integer;cmdline:string;n:integer;
//App:PControl;
const fn_default='-';

procedure Send_Key(h:THandle;k:DWord);
begin;
  SetActiveWindow(h);
  SetForegroundWindow(h);
  keybd_event(k, MapVirtualKey(k,0), 0, 0);
  keybd_event(k, MapVirtualKey(k,0), KEYEVENTF_KEYUP, 0);	
end;
	
	
procedure Find_Yap;
var
  h: HWnd;
  szText: array[0..254] of char;
  szClass: array[0..254] of char;
  i,j:integer;
begin
h := GetTopWindow(0);
while h <> 0 do
  begin;
  if GetWindowText(h, @szText, 255) > 0 then
    begin;
    GetClassName(h,@szClass,255);
	if (szClass='#32770') and (szText='Yap') then 
		//if (n=1) then 
			begin;Send_Key(h,VK_RETURN);n:=2;break;end;
		//else if (n=2) then begin;n:=3;break;end;
    if (szClass='MiKTeX_yap') and (szText='Yap 2.4.1803 - ['+fn+'.dvi]') then 
		//if (n=1) then begin;Halt(1);end else 
			begin;Send_Key(h,VK_F5);Halt(1);end;
    end;
  h := GetNextWindow(h, GW_HWNDNEXT);
  end;
if (h=0) and (n>1) then Halt(1);
end;


procedure T_Timer(Dummy:Pointer; Sender: PControl);var s:string;
begin;
Find_Yap;
end;


var m:Msg;i:integer;hnd: THandle;


begin;
// cmdline:='yap.exe';
// for i:=1 to ParamCount do cmdline:=cmdline+' '+ParamStr(i);
// WinExec(cmdline,SW_SHOW);

hnd := CreateMutex(nil, True, 'yap1_mtex');
if GetLastError = ERROR_ALREADY_EXISTS then Halt;


T:=NewTimer(400);T.Enabled:=true;n:=1;
T.OnTimer := TOnEvent( MakeMethod( nil, @T_Timer ) );

// fn:=fn_default;
// if (ParamCount>0) and (Pos('-',ParamStr(1))<>1) then fn:=ExtractFileNameWOext(ParamStr(1));
//msgOK(fn);

fn:=ExtractFileNameWOext(ParamStr(1));

while( GetMessage( m, 0, 0, 0 ) ) do 
  begin
    TranslateMessage(m);
    DispatchMessage(m);
  end;
if hnd <> 0 then CloseHandle(hnd);
	
end.

