{
v0.40: 支持通过语言文件修改字体大小及属性
v0.35: 多语言支持，可通过语言文件修改界面语言；
v0.3
v0.25:
v0.2:
v0.1:基本功能
}
{$D SMALLEST_CODE} 
{$R mtex.res}
uses windows,messages,kol,shellapi,xptheme;{$I w32.pas}

const 
	 sStart='◆'; sEnd='■'; fn=' 计时器';

var App,W,B1,B2,L1:PControl;T:PTimer;cnt:integer;
const n=6;step=15;minimum=15;maximum=254;

procedure T_Timer(Dummy:Pointer; Sender: PControl);var s:string;
begin;
//  W.Visible:=false;W.Visible:=true;
  s:=' 第'+Int2Str(cnt div n + 1)+'分钟！';
  if cnt>0 then begin;L1.Text:=s;cnt:=cnt+1;end
  else L1.Text:='  未计时！';
end;

procedure B1_Click(Dummy:Pointer; Sender: PControl);
begin;
if cnt>0 then begin;cnt:=0;L1.Text:=' 停止计时！';b1.caption:=sStart;end 
else begin;cnt:=1;L1.Text:=' 开始计时！';b1.caption:=sEnd;end; 
//W.Focused:=false;
end;

procedure B2_Click(Dummy:Pointer; Sender: PControl);
begin;Halt(0);end;

procedure w_MouseLeave(Dummy_Self: PObj; Sender: PControl;var Mouse: TMouseEventData);
var hh:Hwnd; P:TPoint;
begin
  GetCursorPos(P);
  hh:=windowfrompoint(P);
  if (hh>0) and (GetWindowThreadProcessId(hh,nil)<>GetCurrentThreadId) then 
    begin;SetActiveWindow(hh);SetForegroundWindow(hh);end;
end;

function FormMessage(Dummy_Self: PObj; var Msg: TMsg; var Rslt: Integer ): Boolean;
begin
  Result := FALSE;
  if (Msg.message=WM_LBUTTONDOWN)and(Msg.hwnd=L1.handle) then
  begin;
    SendMessage(w.handle, WM_NCLBUTTONDOWN, HTCAPTION,0);
    result:=true;
  end;
  if (Msg.message=WM_LBUTTONDBLCLK) and (Msg.hwnd=L1.handle) then
  begin;
    B1.click;
    result:=true;
  end;
  if (msg.message=wm_keydown) or (msg.message=wm_char)  then
  begin
    if (msg.wparam=vk_down) then begin;w.alphablend:=max(w.alphablend-step,minimum);end;
    if (msg.wparam=vk_up) then begin;w.alphablend:=min(w.alphablend+step,maximum);end;
    result:=true;
  end;
  if (msg.message = WM_MOUSEWHEEL) then
  begin
    if HIWORD(msg.wParam)=120 then        // 上滚
      begin;w.alphablend:=min(w.alphablend+step,maximum);end
    else begin;w.alphablend:=max(w.alphablend-step,minimum);end;
  end;
end;

procedure SetEvents;
begin;
  B1.OnClick := TOnEvent( MakeMethod( nil, @B1_Click ) );
  B2.OnClick := TOnEvent( MakeMethod( nil, @B2_Click ) );
  T.OnTimer := TOnEvent( MakeMethod( nil, @T_Timer ) );
  w.OnMouseLeave:=TOnEvent( MakeMethod( nil, @w_MouseLeave ) );
  W.Onmessage := TOnMessage( MakeMethod(nil, @FormMessage));
end;

procedure InitObjs;
begin;
//  App := NewApplet( 'Test' );
  W := NewForm(nil, fn);
//  w.StayOnTop:=true;
  W.Left:=2;W.Top:=2;
  W.Style:=WS_POPUP or WS_CLIPSIBLINGS {or WS_border};
  W.ExStyle := WS_EX_TOOLWINDOW or WS_EX_TOPMOST;
  w.alphablend:=254;
//  SetWindowPos(w.handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE Or SWP_NOSIZE);
//  SetWindowLong(w.Handle,GWL_EXSTYLE,getwindowlong(w.handle,gwl_exstyle) or WS_EX_TOOLWINDOW or WS_EX_TOPMOST or WS_DLGFRAME);
  SetFont(W.Font,'黑体,16');
  T:=NewTimer(1000*60 div n);T.Enabled:=true;cnt:=0;
  if not JustOne(W,fn) then Halt(0);
  B1:=NewButton(W,sStart).PlaceUnder.SetSize(20,0).ResizeParent;
  L1:=NewEditBox(W,[eoReadOnly]).PlaceRight.SetSize(92,0).ResizeParent; 
  L1.Color:=clYellow;L1.Text:='记时器[mhb]';
  B2:=NewButton(W,'×').PlaceRight.SetSize(20,0).ResizeParent;
//  W.Tabstop:=false;B1.Tabstop:=false;B2.Tabstop:=false;L1.Tabstop:=false;
  //with L1.Font^ do begin;FontHeight:=12;FontName:='楷体_GB2312';Color:=clYellow;end;
  //L1.Font.FontColor:=clYellow;
//  W.Focused:=false;W.IgnoreDefault:=false;W.DefaultBtn:=false;W.LookTabKeys:=[];
end;

begin;
  InitObjs;
  SetEvents;
  Run(W);
end.