{
v0.51: 使用系统默认字体
v0.50:允许直接从文件读菜单，从而解决TCC/LE不能完美处理中文的问题; 同时在控制台输出选中的菜单项
v0.45:检测4NT Prompt；使用状态栏？
v0.40:自动隐藏TEX-DOS窗口；调整颜色、字体
v0.35:加入Hint提示；允许调入提示信息文件
v0.25:XP风格美化；修正ShowQuestion2与Xptheme并用的问题
v0.2:使用自己改进的ShowQuestion2，支持比较多的按钮数量，还可指定按钮的宽度
v0.1:使用KOL ShowQuestion
}
{$APPTYPE CONSOLE}
{$D SMALLEST_CODE} 
{$R mtex.res}
uses windows,messages,kol,xptheme,shellapi{,koladd};{$I w32.pas}
var 
	Hint: PControl; //[mhb]
	HintmsgList: PStrList;
	use_hint:boolean;//[mhb]
	h:THandle;//[mhb]
	ret:integer;//[mhb]

var t,k,s,f_hint:string;a_but:array[0..500] of string;
const usage=
	'WASK v0.55 [mhb]'+CR
	+'本工具可以显示一个具有多个选项的菜单，返回选项的编号。'+CR
	+'用法1：WASK 提示信息//选项1/选项2/...'+CR
	+'用法2：WASK {按钮宽度}提示信息//选项1/选项2/...'+CR
	+'用法3：WASK {@提示信息列表文件,按钮宽度}提示信息//选项1/选项2/...'+CR
	+'说明：将返回选项的编号。默认的提示信息列表文件是$WASKHINT。';

function ReadMenu(s:string):string;
begin;
  Result:=s;
  if not FileExists(s) then Exit;
  Result:=StrLoadFromFile(Result);
  Result:=StrReplaceAll(Result,CR,'/')
end;

function Find_Hint(s:string):string;
var i:integer;
begin;
  for i:=0 to HintmsgList.Count-1 do 
	  if Pos(LowerCase(s),LowerCase(HintmsgList.Items[i]))=1 then 
		  begin;Result:=HintmsgList.Items[i];Exit;end;
  Result:='';	
end;

procedure Btn_MouseMove(dummy:Pointer;Sender: PControl;var Mouse: TMouseEventData);
var  P:TPoint;s,s2:string;
begin;
  if not use_hint then Exit;
  Hint.ResizeParent;Hint.Visible:=TRUE;
  s:=Trim(Sender.Caption);
  s2:=Find_Hint(s);if Length(s2)>0 then s:=s2;
  Hint.Caption:='#'+Int2Str(Sender.Tag)+':'+s;
  
  //SetTextColor(Sender.Parent.StatusCtl.Canvas.Handle,clRed);
  //Sender.Parent.SimpleStatusText:=PChar('#'+Int2Str(Sender.Tag)+':'+s);
  //SetBkColor(Sender.Parent.StatusCtl.Brush.Handle,clRed);
end;

procedure MinimizeMsg( Dummy, Dialog: PControl);
begin
  // msg_ok('xxx');
  // Dialog.ModalResult := -1;
end;

function ShowQuestionEx3( const S: String; Answers: String; CallBack: TOnEvent; Settings:string): Integer;
{$IFDEF F_P105ORBELOW}
type POnEvent = ^TOnEvent;
     PONKey = ^TOnKey;
var M: TMethod;
{$ENDIF F_P105ORBELOW}
var Dialog: PControl;
    Buttons: PList;
    Btn: PControl;
    AppTermFlag: Boolean;
    Lab: PControl;
    Y, W, I: Integer;
    BtnWidth,DlgWidth:integer; 
    Title: String;
    DlgWnd: HWnd;
    AppCtl: PControl;
	s_caption:string;//[mhb]
begin
  AppTermFlag := AppletTerminated;
  AppCtl := Applet;
  AppletTerminated := FALSE;
  BtnWidth:=0;DlgWidth:=300;use_hint:=FALSE;//[mhb]
  if Settings<>'' then BtnWidth:=Str2Int(Settings);
  if BtnWidth>0 then DlgWidth:=6*BtnWidth+30;
  Title := 'Information';
  if pos( '/', Answers ) > 0 then
    Title := 'Question';
  if Applet <> nil then
    Title := Applet.Caption;
  Dialog := NewForm( Applet, Title ).SetSize( DlgWidth, 100 );
  Dialog.font.releasehandle;//[qhs]
  Dialog.Font.AssignHandle(GetStockObject(DEFAULT_GUI_FONT));//[qhs]
  Dialog.Style := Dialog.Style and not ({} WS_MINIMIZEBOX or WS_MAXIMIZEBOX);
  Dialog.StayOnTop := true;//[mhb] added for WASK.exe
  Dialog.OnClose := TOnEventAccept( MakeMethod( Dialog, @CloseMsg ) );
  //Dialog.OnMinimize := TOnEvent( MakeMethod( Dialog, @MinimizeMsg ) );
  Dialog.Margin := 8;
  //SetFont(Dialog.Font,'宋体,13');
  Lab:=NewWordWrapLabel( Dialog,S ).SetSize( DlgWidth-20, 0 );Lab.Autosize(true);
  //Lab := NewEditbox( Dialog, [ eoMultiline, eoReadonly, eoNoHScroll, eoNoVScroll ] ).SetSize( 278, 20 );
  Lab.HasBorder := FALSE;
  //Lab.Color := clRed; //
  //Lab.Color := clBtnFace;
  Lab.Color := clAqua;
  //Lab.Font.FontHeight:=-11;
  
  //Lab.Caption := S;
  Lab.Style := Lab.Style and not WS_TABSTOP;
  Lab.TabStop := FALSE;
  //Lab.LikeSpeedButton;

  //Lab.CreateWindow; //virtual!!! -- not needed, window created in Perform
//  while TRUE do
//  begin
//    Y := HiWord( Lab.Perform( EM_POSFROMCHAR, Length( S ) - 1, 0 ) );
//    if Y < Lab.Height - 20 then break;
//    Lab.Height := Lab.Height + 4;
//    if Lab.Height + 40 > GetSystemMetrics( SM_CYSCREEN ) then break;
//  end;


  Buttons := NewList;
  I := 0;//[mhb]
  if Answers = '' then
  begin
    Btn := NewButton( Dialog, '  OK  ' ).PlaceUnder;
    Buttons.Add( Btn );
  end
    else
  while Answers <> '' do
  begin
    s_caption:=Parse( Answers, '/' );
    a_but[I]:=s_caption;//0.50+
    s_caption:=FileNameExt(s_caption);//0.50+
    if (not use_hint) and (Length(Find_Hint(s_caption))>0) then use_hint:=TRUE;
    Btn := NewButton( Dialog, '  ' + s_caption + '  ' );
	//Btn.Color:=clBlue;Btn.Color:=clGreen;
	//SetFont(Btn.Font,'宋体,12');
	//Btn.Font.FontHeight:=-10;

    Buttons.Add( Btn );
    if (I mod 6)=0 then //W=0
      begin;Btn.PlaceDown.Shift(0,5);end
    else
      begin;Btn.PlaceRight.Shift(6,0);end;
    Inc(I);//[mhb]
    if BtnWidth=0 then Btn.AutoSize( TRUE )  else  Btn.Width:=BtnWidth;
    Btn.ResizeParent;
  end;

  if use_hint then 
	  begin;
	  //Dialog.SimpleStatusText:='';
	  //Dialog.StatusCtl.Color:=clRed;
	  // Dialog.StatusCtl.Font.FontHeight:=-9;
  
	  Hint:=NewLabel(Dialog,'').PlaceDown.SetSize( Dialog.Width-5, 20 ).ResizeParent;	
	  Hint.TabStop:=FALSE;
      Hint.Color:=clTeal;//clLime;
	  //SetFont(Hint.Font,'宋体,11');//Hint.Font.FontHeight:=-9;
	  Hint.Visible:=FALSE;
	  Hint.Style := Hint.Style and not WS_TABSTOP;
  
	  end;
	
  for I := 0 to Buttons.Count-1 do
  begin
    Btn := Buttons.Items[ I ];
    Btn.Tag := I + 1;
    {$IFDEF F_P105ORBELOW}
    M := MakeMethod( Dialog, @OKClick );
    Btn.OnClick := POnEvent( @ M )^;
    M := MakeMethod( Dialog, @KeyClick );
    Btn.OnKeyDown := POnKey( @ M )^;
    {$ELSE}
    Btn.OnClick := TOnEvent( MakeMethod( Dialog, @OKClick ) );
    Btn.OnKeyDown := TOnKey( MakeMethod( Dialog, @KeyClick ) );
    {$ENDIF}
    if use_hint then 
		Btn.OnMouseMove:=TOnMouse( MakeMethod( nil, @Btn_MouseMove ) );
    if I = 0 then
    begin
      Dialog.ActiveControl := Btn;
    end;
  end;
  Dialog.CenterOnParent.Tabulate.CanResize := FALSE;
  Buttons.Free;

  if Assigned( CallBack ) then
    CallBack( Dialog );
  Dialog.CreateWindow; // virtual!!!

  if (Applet <> nil) and Applet.IsApplet then
  begin
    Dialog.ShowModal;
    Result := Dialog.ModalResult;
    //Dialog.Free;
  end
    else
  begin
    DlgWnd := Dialog.Handle;
    while IsWindow( DlgWnd ) and (Dialog.ModalResult = 0) do
      Dialog.ProcessMessage;
    Result := Dialog.ModalResult;
    //Dialog.Free;
    CreatingWindow := nil;
    Applet := AppCtl;
  end;

  if Result>0 then 
	begin;
	writeln(a_but[Result-1]);
	end;
	
  if Result>=0 then Dialog.Free;
  AppletTerminated := AppTermFlag;
end;
//[END ShowQuestionEx]

//[function ShowQuestion]
function ShowQuestion3( const S: String; Answers: String; Settings:string ): Integer;
begin
  Result := ShowQuestionEx3( S, Answers, nil , Settings);
end;

function FindClass(title:string):THandle;
var
  hCurrentWindow: HWnd;
  szText: array[0..254] of char;
begin
hCurrentWindow := GetTopWindow(0);
while hCurrentWindow <> 0 do
  begin;
  if GetClassName(hCurrentWindow, @szText, 255) > 0 then
    if pos(UpperCase(title),UpperCase(szText))=1 then break;
  hCurrentWindow := GetNextWindow(hCurrentWindow, GW_HWNDNEXT);
  end;
Result:=hCurrentWindow;//msgOK(Format('%d',[hCurrentWindow]));
end;

begin;
if ParamCount=0 then begin;msgok(usage);Halt(0);end;
HintmsgList:=NewStrList;HintmsgList.Clear;
t:=GetArgs;s:='';f_hint:=GetEnv('WASKHINT');use_hint:=false;
if (Length(t)>0) and (t[1]='{') then begin;s:=S_Before('}',t);Delete(s,1,1);end;
if (Length(s)>0) and (s[1]='@') then begin;f_hint:=S_Before(',',s);end;
	
if (Length(t)>0) and (t[1]='@') then //new: 0.50+
	begin;
	Delete(t,1,1);
	t:=ReadMenu(Trim(t));
	end;

if FileExists(f_hint) then 
	begin;
	HintmsgList.LoadFromFile(f_hint);
	HintmsgList.Sort(FALSE);
	end;

h:=Find_W('TEX-DOS');
if (h=0) then h:=FindClass('ConsoleWindowClass');
if (h<>0) then SendMessage(h, WM_SYSCOMMAND, SC_MINIMIZE, 0 );
k:=S_Before('//',t);
ret:=ShowQuestion3(k,t,s);
if (h<>0) then SendMessage(h, WM_SYSCOMMAND, SC_RESTORE, 0 );
Halt(ret);
end.