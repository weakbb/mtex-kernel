{
v0.96: 用系统默认字体; 修改部分控件大小使英文显示更好
v0.95: 增加状态栏；修改图标；修改checkbox处理；增加dropdowncount；
v0.90: 支持通过语言文件修改字体大小及属性
v0.85: 多语言支持，可以通过语言文件实现各种语言的界面；ini文件格式改变：
v0.80: 增加自动缩小窗口的功能，减少占用屏幕空间；
v0.75: 改进了保存配置的功能，现在可以直接添加或修改命令脚本；增加环境变量替换功能；选择工具类别框时可以立即弹出工具菜单。
v0.70: 可从环境变量ETC指定的目录读配置文件；
v0.65: XP风格美化；修正ShowQuestion2的bug；修正消息循环的bug；
v0.60: 加入DefaultExt设置；
v0.55: 拖动文件.
v0.50: 增加环境变量配置功能。
v0.45: 增加C7,C8。增加传递命令行到已有实例。置顶。自动打开关联菜单。处理文件名。环境变量替换？拖动文件？
v0.40: 增加Reset选项。
v0.35: 自动根据文件扩展名给出菜单。
v0.30: 修正临时文件权限？增加环境变量替换功能？清除命令行按钮？
v0.25: 增加Dir,Mode,Hint,Ask,Open,WinExec,ShellExec,NeedFile,NeedDir等选项指令；改写Ext选项指令的处理；调整字体大小，颜色；去掉CB0中的'--'显示。修改配置文件。
}
program Utils;
{$D SMALLEST_CODE} 
{$D USE_DROPDOWNCOUNT}
//{$R mtex.res}
{$R utilsman.res}
uses
  windows,messages,kol,shellapi,xptheme;{$I w32.pas} 

const
  _tmp='_tmp_.bat';_log='_tmp_.log';_ini='utilsman.ini';_conf='utilsman.env';
  DefFilter='所有文件(*.*)|*.*|可执行文件(*.exe;*.com;*.bat;*.cmd;*.btm)|*.exe;*.com;*.bat;*.cmd;*.btm';
  help='UtilsMan〖工具箱管家〗 v 0.96 欢迎大家免费使用。'+CR+CR
    +'版权所有 2004--2008 [mhb]。作者保留对本软件的所有权利。'+CR
    +'如有问题或建议，请到MTeX-suite论坛讨论。E-mail地址：mtex-suite@googlegroups.com。'+CR+CR
    +'1.基本用法：您可以通过下拉框选择您要运行的工具，然后在文本框中输入命令行参数，接着点击按钮"执行所选工具"开始运行。'+CR
    +'2.为了辅助您输入命令行参数，您可以点击按钮"…"选择一个文件，或"[…]"选择一个文件夹。'+CR
    +'3.如果您运行工具前希望察看或修改您选择的文件，您可以点击文本框后的按钮"︾"打开一个内置的小编辑器，编辑后点击按钮"︽"即可存盘！'+CR
    +'4.进一步用法：您还可以把本软件当作一个运行任何命令的外壳，您可以直接在编辑框中输入命令(比如DOS命令"dir/p")，然后点击按钮"执行所选工具"运行您输入的命令。'
    +'运行命令前，您可以点击按钮"[..]"选择当前文件夹，点击按钮".."直接选择要运行的可执行文件（需要钩上"可直接输入命令"）。';
  DlgHintFile='更多本工具配置/运行的相关信息，请参考同时为您自动打开的帮助文件或程序：';


var etc:string;
var 
  tmp,log,ini,conf,default_ext:string;
  App,W,W2,Menu,L1,E1,E2,E3,B_run,B_file1,B_dir1,B_edit1,B_file2,B_dir2,B_edit2,B_options,B_help,B8,B9,CB1,CB0,P1,P2,C1,C2,C3,C4,C5,C6,C7,C8:PControl;
  UtilList:PStrList;exepath,title,cfg,s_cfg,paths,pre,post,menudata,comspec,cmds,editor,filter,fn,args,envs,opt,sec:string;
  Dlg1,Dlg2:TOpenSaveDialog;D1:TOpenDirDialog;D2:TOpenSaveDialog;
  E2changed,E3changed,bTrackEnter:boolean;
  DlgType:integer;
  T1:PTimer;
  w_width,w_height,style1,style2:integer;
  DlgHints:array[1..2] of string;
  DlgTitles:array[1..2] of string;

function GetParam1(s:string):string;
var c:char;i:integer;
begin;
s:=TrimLeft(s);Result:='';c:=' ';
if s='' then Exit;
if s[1]='"' then begin;Delete(s,1,1);c:='"';end;
Result:=S_Before(c,s);
end;


procedure ReadConfig;forward;
function GetMenus(f:string):string;forward;
procedure AddMenus(v:string);forward;

procedure SaveWindowSize;
begin;
  w_width:=W.Width;w_height:=W.Height;
end;

procedure RestoreWindowSize;
begin;
  if W.Height<w_height then begin;W.Height:=w_height;W.Width:=w_width;end;
  w.alphablend:=255;
  w.style:=W.Style and not (ws_maximizebox or WS_SIZEBOX) or ws_sysmenu;
  w.caption:=title;
end;

procedure MinimizeWindowSize;
begin;
  W.ClientHeight:=0;
  W.Width:=40;
  W.alphablend:=196;
  w.style:=W.Style and not (ws_sysmenu or WS_SIZEBOX);
  w.caption:='  '+title;
  drawiconex(getwindowdc(w.handle),5,(w.height-16) div 2-2,LoadIcon(hinstance, 'MAINICON'),16,16,0,0,di_normal);
end;



procedure W_OnAnotherInstance( Dummy: PControl; CmdLine: String );
var v:string;
begin;

bTrackEnter := false;
T1.enabled := false;
RestoreWindowSize;

E1.Text:=TrimLeft(GetParams(CmdLine));
ReadConfig;
if Length(E1.Text)=0 then Exit;
fn:=GetParam1(E1.Text);//msgok(fn);
v:=GetMenus(fn);//v:=GetMenus(E1.Text);
AddMenus(v);
//if W.Visible then 
  begin; W.Perform(WM_SYSCOMMAND,SC_RESTORE,0);CB1.Perform(CB_SHOWDROPDOWN,1,0);end;

end;

procedure T1_Timer(Dummy:Pointer; Sender: PControl);
var P:TPoint;
    FormRect: TRect;
begin;
  GetCursorPos(P);
  GetWindowRect(w.Handle, FormRect);
  if not (PtInRect(FormRect, P)) then
  begin;
    T1.enabled := false;
    bTrackEnter := true;
    MinimizeWindowSize;
//    msgok('w_leave');
  end;
end;


function FormMessage(Dummy_Self: PObj; var Msg: TMsg; var Rslt: Integer ): Boolean;
var  num,i:integer;
     lpszFile:pchar;
     v:string;
     hDrop:THandle;
begin
  Result := FALSE;
  if (Msg.message=WM_NCHITTEST) and (bTrackEnter) then
    begin;
      bTrackEnter := false;
      T1.enabled := true;
//      msgok('w_enter');
      RestoreWindowSize;
    end
  else if (msg.message=WM_DROPFILES) then
  begin;
    bTrackEnter := false;
    T1.enabled := true;
    RestoreWindowSize;
    hDrop:=msg.WParam;
    num:=dragqueryfile(hDrop,$ffffffff,nil,0);//msgok(int2str(num));
    getmem(lpszfile,255);
//    for i := 0 to num-1 do 
      dragqueryfile(hDrop,0{i},lpszFile,254); // 只接收第一个文件
    E1.text:=strpas(lpszFile);
    DragFinish(hDrop); FreeMem(lpszfile);
//    ReadConfig;
    fn:=GetParam1(E1.Text);//fn:=E1.Text;//
    v:=GetMenus(fn);
    AddMenus(v);
    if W.Visible then 
      begin; W.Perform(WM_SYSCOMMAND,SC_RESTORE,0);CB1.Perform(CB_SHOWDROPDOWN,1,0);end;
    result:=true;
  end;
end;


procedure InitObjs;
var buf:string;W_OAI:TOnAnotherInstance; 
begin;
  DlgHints[1]:='请您配置如下环境变量，点击【确定】保存该配置。';
  DlgHints[2]:='请您设置如下运行参数，点击【确定】您的设定将在本次运行生效。';
  DlgTitles[1]:='配置 ';
  DlgTitles[1]:='设置 ';	
  W:=NewForm(nil,'UtilsMan工具箱管家 [mhb&qhs]');
	
  W_OAI:=TOnAnotherInstance(MakeMethod( nil, @W_OnAnotherInstance));
  if not JustOneNotify(W,'UtilsMan',W_OAI) then begin;halt(0);end;
  W.StayOnTop:=true;W.Left:=ScreenWidth div 10*5;W.Top:=ScreenHeight div 10*2;
  W.Style:=W.Style and not (WS_MAXIMIZEBOX or WS_SIZEBOX);
  W.font.releasehandle;//[qhs]
  W.Font.AssignHandle(GetStockObject(DEFAULT_GUI_FONT));//[qhs]
  //SetFont(W.Font,'宋体,12');
  CB0:=NewCombobox(W,[coReadOnly]).PlaceRight.SetSize(75,20);
  CB0.DropDownCount:=30;
  CB0.Font.Color:=clBlue;
  //SetFont(CB0.Font,'宋体,12');
  CB1:=NewCombobox(W,[coReadOnly]).PlaceRight.SetSize(175,20);
  CB1.DropDownCount:=40;
  B_run:=NewButton(W,'执行所选工具').PlaceRight.SetSize(100,20);
  B_run.Font.Color:=clBlue;
  B_file1:=NewButton(W,'..').PlaceRight.SetSize(30,20);
  B_dir1:=NewButton(W,'[..]').PlaceRight.SetSize(30,20);
  B_edit1:=NewButton(W,'︾').PlaceRight.SetSize(50,20);
  B_options:=NewButton(W,'设置').PlaceRight.SetSize(50,20).ResizeParent;//.Shift(20,0);

  
  

  L1:=NewLabel(W,'命令行参数:').PlaceDown.SetSize(100,20);
  E1:=NewEditbox(W,[]).PlaceRight.AlignLeft(CB1).SetSize(270,20);      E1.Color:=clWhite;
  B_file2:=NewButton(W,'…').PlaceRight.AlignLeft(B_file1).SetSize(30,20); B_file2.Font.Color:=clWhite;
  B_dir2:=NewButton(W,'[…]').PlaceRight.SetSize(30,20);B_dir2.Font.Color:=clWhite;
  B_edit2:=NewButton(W,'︾').PlaceRight.SetSize(50,20); B_edit2.Font.Color:=clWhite;
  B_help:=NewButton(W,'帮助').PlaceRight.SetSize(50,20).ResizeParent;//.Shift(20,0);

  
  CB1.Font.Color:=clRed;
  E1.Color:=clWhite;

  P2:=NewPanel(W,esLowered).PlaceDown;
  C1:=NewCheckbox(P2,'结束后按任意键').SetSize(125,0).PlaceRight.ResizeParent;
  C2:=NewCheckbox(P2,'显示命令清单').SetSize(125,0).PlaceRight.ResizeParent;
  C3:=NewCheckbox(P2,'记录运行结果').SetSize(125,0).PlaceRight.ResizeParent;
  C4:=NewCheckbox(P2,'最小化运行窗口').SetSize(125,0).PlaceRight.ResizeParent;
  C5:=NewCheckbox(P2,'WinExec方式运行').SetSize(125,0).PlaceDown.ResizeParent;
  C5.Checked:=true;
  C6:=NewCheckbox(P2,'运行前改变目录').SetSize(125,0).PlaceRight.ResizeParent;
  //C6.Checked:=true;
  C7:=NewCheckbox(P2,'结束后立即退出').SetSize(125,0).PlaceRight.ResizeParent;
  C8:=NewCheckbox(P2,'可直接输入命令').SetSize(125,0).PlaceRight.ResizeParent;
  B_file1.Enabled:=C8.Checked;

  T1:=NewTimer(100);  T1.OnTimer := TOnEvent( MakeMethod( nil, @T1_Timer ) ); T1.enabled := false;
  bTrackEnter:=true;

  P2.ResizeParent;

  E2:=NewEditbox(W,[eoMultiline]).PlaceUnder.SetSize(450,140);//.ResizeParent;
  E3:=NewEditbox(W,[eoMultiline]).AlignTop(E2).AlignLeft(E2).SetSize(450,140);
  E2.Hide;E3.Hide;
  UtilList:=NewStrList;
  comspec:=GetEnv('COMSPEC')+' /c';
  {buf:=GetEnv('TMP');  ShowMessage(buf+'\\'+tmp);}
  editor:='notepad.exe';
  title:='工具箱管家 [mhb&qhs]';
  Dlg1.Title:='请选择文件：';
  Dlg1.Filter:=DefFilter;
  filter:='';
  D1.Title:='请选择一个文件夹：';
  D2.Title:='请选择一个文件：';
  
  W.SimpleStatusText:=PChar('本软件为您提供简单而强有力的方式来运行各种工具，即使该工具没有图形界面。');
  B_run.CustomData:=PChar('点击该按钮将运行您选择的工具！');
  B_file1.CustomData:=PChar('点击该按钮将使您直接选择一个可执行程序。');
  B_dir1.CustomData:=PChar('点击该按钮将使您直接选择一个目录，您选择的工具将在该目录运行。');
  B_edit1.CustomData:=PChar('点击该按钮将使您直接编辑当前工具的命令脚本。');
  B_options.CustomData:=PChar('点击该按钮将使您直接打开配置文件utilsman.ini。');
  E1.CustomData:=PChar('您可以在文本框中直接输入命令行参数。');
  B_file2.CustomData:=PChar('点击该按钮将使您直接选择一个文件并把文件路径加入命令行。');
  B_dir2.CustomData:=PChar('点击该按钮将使您直接选择一个目录并把其路径加入命令行。');
  B_edit2.CustomData:=PChar('点击该按钮将允许您直接编辑您选定的文件并保存您的修改。');
  B_help.CustomData:=PChar('点击该按钮将显示简单的帮助信息。');
  C1.CustomData:=PChar('选中该选项可以让您在运行后观察屏幕输入，适于控制台模式的工具。');
  C2.CustomData:=PChar('选中该选项可以在命令运行前显示即将运行的命令。');
  C3.CustomData:=PChar('选中该选项可以将运行结果重定向到一个临时文件，供您在运行后查看。');
  C4.CustomData:=PChar('选中该选项将使您以最小化模式运行工具。');
  C5.CustomData:=PChar('选中该选项运行工具将不等待工具结束。');
  C6.CustomData:=PChar('选中该选项将在运行工具前自动进入文件所在目录。');
  C7.CustomData:=PChar('选中该选项将使您运行完工具自动退出本软件。');
  C8.CustomData:=PChar('选中该选项将允许您直接在文本框中输入DOS命令。该选项将使您选择的工具失效！');
  
end;

procedure ReadConfig;
var s:string;i:integer;
begin;

  if FileExists(cfg) then
    begin;
    s_cfg:=StrLoadFromFile(cfg);
    title:=StrBetween(s_cfg,CR+'Title=',CR);
    W.Text:=Title;
    paths:=StrBetween(s_cfg,CR+'Paths=',CR);
    editor:=StrBetween(s_cfg,CR+'Editor=',CR);
    comspec:=StrBetween(s_cfg,CR+'Comspec=',CR);
    filter:=StrBetween(s_cfg,CR+'Filter=',CR);
    default_ext:=StrBetween(s_cfg,CR+'DefaultExt=',CR);
    if default_ext='' then default_ext:='.tex';
    Dlg1.Filter:=filter+'|'+DefFilter;
    pre:=StrBetween(s_cfg,CR+'[#PreRun]'+CR,CR+'['); //执行前预备命令
    post:=StrBetween(s_cfg,CR+'[#PostRun]'+CR,CR+'['); //执行后结尾命令
    menudata:=StrBetween(s_cfg,CR+'[#AssocMenus]'+CR,CR+'[[');//ShowMessage(menudata);//扩展名关联菜单
    
    CB1.Clear;UtilList.Clear;CB0.Clear;
    CB1.Add('');UtilList.Add('');CB0.Add('');
    i:=0;StrToken(s_cfg,CR+'[[',i);
    repeat
      s:=StrToken(s_cfg,']]'+CR,i);
      CB1.Add(s);//ShowMessage(s);
      if Pos('--',s)=1 then begin;Delete(s,1,2);CB0.Add(s);end;
      s:=StrToken(s_cfg,CR+'[[',i);
      UtilList.Add(s);
    until s='';
    E2.Text:=UtilList.Items[CB1.CurIndex];
    end;
end;

procedure WriteConfig;
var s:string;i:integer;
begin;
  s:='[#Settings]'+CR //基本设置
    +'Title='+title+CR
    +'Comspec='+comspec+CR
    +'Editor='+editor+CR
    +'Paths='+paths+CR
    +'Filter='+filter+CR
    +'DefaultExt='+default_ext+CR
    +'[#PreRun]'+CR //执行前预备命令
    +pre+CR
    +'[#PostRun]'+CR //执行后结尾命令
    +post+CR
    +'[#AssocMenus]'+CR //扩展名关联菜单
    +menudata+CR;
  for i:=0 to CB1.Count-1 do 
    if (Length(CB1.Items[i])>0) and not (Pos('|',CB1.Items[i])=1) then 
      s:=s+'[['+CB1.Items[i]+']]'+CR+UtilList.Items[i]+CR;
  StrSaveToFile(cfg,s);
end;


procedure E2Change(Dummy:Pointer; Sender: PControl);
begin;E2changed:=true;
end;

procedure E3Change(Dummy:Pointer; Sender: PControl);
begin;E3changed:=true;
end;

	
procedure C8Click(Dummy:Pointer; Sender: PControl);
begin;
	B_file1.Enabled:=C8.Checked;
	//if C8.Checked then CB1.Perform(EM_SETREADONLY,0,0) else CB1.Perform(EM_SETREADONLY,1,0);
end;

	
function InputBox(wtitle,msg,str:string):string;
const cw=200;
var W,L,E,B_ok,B_cancel,B_file,B_dir,X:PControl;
begin;
W:=NewForm(nil,wtitle);
L:=NewWordWrapLabel(W,msg).PlaceDown.SetSize(cw,0).ResizeParent;
E:=NewEditbox(W,[]).PlaceDown.SetSize(cw,0).ResizeParent;
E.Text:=str;
B_ok:=NewButton(W,'确定').PlaceDown.ResizeParent;
B_cancel:=NewButton(W,'取消').PlaceRight.ResizeParent;
X:=NewLabel(W,'').SetSize(cw,6).PlaceDown.ResizeParent;
Run(W);
Result:=E.Text;
end;


procedure Close_Msg( Dummy, Dialog: PControl; var Accept: Boolean );
begin
  Accept := true;
end;

procedure MouseEnter(Dummy:Pointer; Sender: PControl);
begin;
  if Sender.Tag=0 then Sender.Text:='';
  Sender.Tag:=1;
end;

procedure BtnClick(Dummy:Pointer; Sender: PControl);
var i:integer;s:string;W:PControl;
begin
  i:=Sender.TabOrder;s:='';//W:=PControl(Dummy);
  if i=W2.ChildCount then begin;W2.Visible:=false;W2.Close;end
  else if i=W2.ChildCount-1 then  
    begin;
    For i:=1 To W2.ChildCount-3 Do
      With W2.Children[i]^ Do
        if (i mod 4)=1 then s:=s+Text+'=' 
    else if ((i mod 4)=2) then begin;if (Tag=1) then s:=s+Text;s:=s+CR;end;  
    envs:=s;
    if DlgType=1 then 
       if ShowMsg('即将保存以下设置，是否确认？一旦保存，您将只能通过编辑文件'+conf+'来修改这些配置。'+CR+envs,MB_OKCANCEL)=ID_OK then SetIniSec(conf,sec,envs);
    W2.ModalResult:=0;
    W2.Visible:=false;
    W2.Close;
    end
  else if (i mod 4)=0 then 
    begin;
    if D1.Execute then begin;W2.Children[i-2].Tag:=1;W2.Children[i-2].Text:= D1.Path;end
    end
  else if (i mod 4)=1 then 
    begin;
    if D2.Execute then begin;W2.Children[i-3].Tag:=1;W2.Children[i-3].Text:= D2.Filename;end;
    end;
end;

procedure ConfigDlg(sec,t:string);
var k,v,opts,helpfile:string;App,W,L,E,B_dir,B_file,B_ok,B_cancel:PControl;h:HWnd;
begin;
if (DlgType<1) or (DlgType>2) then Exit;
App:=NewApplet(DlgTitles[DlgType]+sec);
W2:=NewForm(Applet,DlgTitles[DlgType]+sec);
W2.Style := W2.Style and not (WS_MINIMIZEBOX or WS_MAXIMIZEBOX);
W2.OnClose := TOnEventAccept( MakeMethod( W2, @Close_Msg ) );
W2.Left:=400;W2.Top:=300;
opts:='';helpfile:='';

if (Length(t)>0) and (t[1]='[') then begin;Delete(t,1,1);opts:=S_Before(']',t);end;
if (Length(opts)>0) and (opts[1]='@') then 
  begin;
  Delete(opts,1,1);
  if FileExists(opts) then begin;WinExec(PChar('notepad '+opts),SW_SHOW); helpfile:=opts;end
  else ShellExec(PChar(opts),'','',SW_SHOW);
  opts:=DlgHintFile+opts;{opts:=StrLoadFromFile(opts);}
  end;
opts:=DlgHints[DlgType]+opts;
L:=NewWordwrapLabel(W2,opts).SetSize(300,(Length(opts) div 30) * 16).PlaceDown.Shift(50,0);
//L:=NewLabel(W2,DlgHints[DlgType]).PlaceDown.SetSize(400,0);
repeat
  v:=S_Before('|',t);
  k:=S_Before('=',v);
  L:=NewLabel(W2,k).PlaceDown.SetSize(60,0);
  E:=NewEditbox(W2,[]).PlaceRight.SetSize(250,0);
  E.Text:=v;E.Tag:=0;E.Focused:=false;{E.SelectAll;}
  E.OnMouseEnter := TOnEvent(MakeMethod( W2, @MouseEnter));
  B_dir:=NewButton(W2,'[...]').SetSize(30,0).PlaceRight.ResizeParent;
  B_dir.OnClick := TOnEvent(MakeMethod( W2, @BtnClick));
  B_file:=NewButton(W2,'...').SetSize(25,0).PlaceRight.ResizeParent;
  B_file.OnClick := TOnEvent(MakeMethod( W2, @BtnClick));
until t='';
B_ok:=NewButton(W2,'确定').PlaceDown.Shift(120,0).ResizeParent;
B_cancel:=NewButton(W2,'取消').PlaceRight.Shift(50,0).ResizeParent;
B_ok.OnClick := TOnEvent(MakeMethod( W2, @BtnClick));
B_cancel.OnClick := TOnEvent(MakeMethod( W2, @BtnClick));
B_ok.DefaultBtn:=true;B_ok.Focused:=true;
W2.CenterOnParent.Tabulate.CanResize := FALSE;
SetCursorPos(W2.Left+B_ok.Left+20,W2.Top+B_ok.Top+30);
W2.CreateWindow;W2.ShowModal;W2.Close;
if helpfile<>'' then begin;h:=Find_W(helpfile);CloseW(h);end;
W2.ProcessMessages;
end;

procedure Configure(t:string);
var s,v,old_envs:string;
begin;
old_envs:=envs;envs:='';
sec:=S_Before('||',t);
if DlgType=1 then envs:=GetIniSec(conf,sec);
if (DlgType=2) or ((DlgType=1) and (envs='')) then ConfigDlg(sec,t);
s:='';
repeat
  v:=S_Before(CR,envs);
  if Pos('=',v)>0 then s:=s+'set '+v+CR;
until envs='';
envs:=old_envs+s;
end;


procedure B_run_Click(Dummy:Pointer; Sender: PControl);
var s1,s0,s,cmd,ext,r,t,k,r_ext,r_path,s_ask,f,fp,old_dir:string;sw:DWord;b,reset:boolean;v_ask,i:integer;
begin;
//if (CB1.text='') then exit;

//T1.Enabled:=false;
if E3.Visible and (Length(fn)>0) and (E3changed) then 
  if ShowMsg('您可能对文件进行了改动，是否存盘？',MB_YESNO)=ID_YES then 
  StrSaveToFile(fn,E3.Text);
sw:=SW_SHOW;
s_ask:='';envs:='';opt:='';
reset:=false;old_dir:='';
  
if (CB1.Text='') or (C8.Checked) then s:=E1.Text 
else s:=E2.Text+CR; 
	{
	begin;
	b:=not (CB1.Text=CB1.Items[CB1.CurIndex]);
	if b then s:=CB1.Text+' '+E1.Text else s:=E2.Text;
	if Pos('|',CB1.Text)=1 then s:=E2.Text+CR;
	end;
	}
args:=E1.Text;
f:='"'+fn+'"';i:=Pos(f,args);
if i>0 then Delete(args,i,Length(f))
else 
  begin;f:=fn;i:=Pos(f,args);
  if i>0 then Delete(args,i,Length(f));
  end;
ext:=LowerCase(ExtractFileExt(fn));
while (s[1]=':') and (s[2]='{') do
  begin;Delete(s,1,2);
  r:=S_Before('}',s);s:=trimLeft(s);//ShowMessage(r);
  repeat
    t:=Trim(S_Before(',',r));//ShowMessage(t);
    t:=StrExpandEnv(t);
    if t='End' then begin;W.ProcessMessages;exit;end;
    k:=LowerCase(S_Before('=',t));
    if k='dir' then Chdir(t)
//  else if k='path' then 
    else if k='reset' then begin;reset:=true;old_dir:=GetWorkDir;Chdir(GetStartDir);end
    else if k='ext' then begin;
      r_ext:=LowerCase(t);
      if (Pos(ext+';',r_ext+';')=0) then f:=ReplaceFileExt(f,Parse(r_ext,';'));
      end
    else if (k='hint') and (E1.Text='') then begin;
      if t[1]<>'@' then ShowMessage(t) 
      else if t[2]<>'@' then begin;Delete(t,1,1);Msg_Ok(StrLoadFromFile(t));end
      else begin;Delete(t,1,1);ShellOpen(t,sw);end;
      exit;
      end
    else if (k='ask') then begin;
      k:=S_Before('//',t);
      v_ask:=ShowQuestion2(k,t,'');//v_ask:=ShowQuestion(k,t);
      if v_ask<0 then exit else s_ask:=s_ask+Format('%d ',[v_ask]);
      end
    else if (k='needfile') then begin;
      if not FileExists(t) then begin;ShowMessage('没找到文件 '+t+' !');exit;end;
      end
    else if (k='needdir') then begin;
      if not DirectoryExists(t) then begin;ShowMessage('没找到文件夹 '+t+' !');exit;end;
      end
    else if (k='mode') then begin;
        if t='hide' then sw:=SW_HIDE
        else if t='max' then sw:=SW_MAXIMIZE
        else if t='min' then sw:=SW_MINIMIZE
        else if t='restore' then sw:=SW_RESTORE
        else if t='show' then sw:=SW_SHOW;
        end
    else if (k='open') then ShellOpen(t,sw)
    else if (k='winexec') then WinExec(PChar(t),sw)
    else if (k='shellexec') then ShellExec(PChar(t),'','',sw)
    else if (k='config') then begin;DlgType:=1;Configure(t);end
    else if (k='prompt') then begin;DlgType:=2;Configure(t);end;
        
  until r='';
  end;

W.ProcessMessages;
	
fp:=ExtractFilePath(fn);
    
if (C6.Checked) and (Length(fp)>0) then ChDir(fp);

//else if (Length(r_path)>0) then ChDir(r_path);
    
if C2.Checked then s0:='' else s0:='@echo off'+CR;
if v_ask>0 then s0:=s0+'set _ask='+s_ask+CR;

s0:=s0
  +pre+CR
  +envs+CR
  +opt+CR
  +'set path='+exepath+';%path%;'+paths+CR
  +'set _a='+args+CR
  +'set _f='+f+CR
  +'set _pn='+ReplaceFileExt(fn,'')+CR
  +'set _p='+fp+CR
  +'set _n='+ExtractFileNameWOext(fn)+CR
  +'set _e='+ExtractFileExt(fn)+CR;
if C1.Checked then s1:='pause' else s1:='';
if C8.Checked and C5.Checked and (Pos('.exe',s)>0) and (not C1.Checked) and (not C3.Checked) then 
  begin;
  cmd:=s;
  if C4.Checked then sw:=SW_HIDE;
  end
else
  begin;
  s:=s0+CR+s+CR+s1;
  StrSaveToFile(tmp,s);
  cmd:=comspec+' '+tmp+' '+E1.Text;
  if C3.Checked then cmd:=cmd+'>'+log;
  if C4.Checked then sw:=SW_SHOWMINIMIZED;
  end;

if C2.Checked then ShowMessage('即将运行如下命令['+cmd+']:'+CR+s);
if C5.Checked and not C3.Checked then winexec(PChar(cmd),sw) else ExecWait(cmd,sw); //[mhb]
//Sleep(2000);
if C3.Checked and FileExists(log) then 
	begin;
	W.Hide;
	ExecWait('tview.exe '+log,SW_SHOW);//WinExec(PChar('notepad.exe '+log),SW_SHOW);//shell(editor+' '+log,SW_SHOW,false);//[mhb]
	DeleteFile(PChar(tmp));
	W.Show;
	end;
	
	
//Delay(2000);

//
if reset then begin;Chdir(old_dir);end;
if C7.Checked then Halt(0);


bTrackEnter:=false;T1.Enabled:=true;

end;

procedure CB0Change(Dummy:Pointer; Sender: PControl);
begin
CB1.CurIndex:=CB1.IndexOf('--'+CB0.Text)+1;
E2.Text:=UtilList.Items[CB1.CurIndex];
CB1.Perform(CB_SHOWDROPDOWN,1,0);
end;


procedure CB1Change(Dummy:Pointer; Sender: PControl);
var s:string;i:integer;
begin;s:=CB1.Text;W.SimpleStatusText:=PChar(CB1.Text);
if Pos('--',s)=1 then CB1.CurIndex:=CB1.CurIndex+1;
if Pos('|',s)=1 then begin;Delete(s,1,1);i:=CB1.IndexOf(s);end else i:=CB1.CurIndex;
E2.Text:=UtilList.Items[i];
for i:=CB1.CurIndex downto 1 do 
	if Pos('--',CB1.Items[i])=1 then 
		begin;CB0.CurIndex:=CB0.IndexOf(Copy(CB1.Items[i],3,255));Exit;end;
end;


var temp_cmdline:string;
procedure B_edit1_Click(Dummy:Pointer; Sender: PControl);
const msg_save='您可能对命令进行了改动，是否保存改动？命令脚本如下：' ;
	msg_edit='现在您可以编辑当前命令的脚本，然后点击第一排的按钮【︽】保存。';
begin;
  if (E2.Visible) and (E2changed) then
    if ShowMsg(msg_save+CR+'[['+E1.Text+']]'+CR+E2.Text,MB_YESNO)=ID_YES then 
        begin;
        if (CB1.CurIndex=0) and (Length(E1.Text)>0) then 
		begin;UtilList.Add(E2.Text);CB1.Add('');CB1.Items[UtilList.Count-1]:=E1.Text;end
	else if (CB1.CurIndex>0) and not (Pos('|',CB1.Text)=1) then 
		begin;CB1.Items[CB1.CurIndex]:=E1.Text;UtilList.Items[CB1.CurIndex]:=E2.Text;end;
	
        WriteConfig;W_OnAnotherInstance( W, GetCommandLine );
        end;
  E2.Visible:=not E2.Visible;
  if E2.Visible then 
		begin;
		L1.Text:='工具对应菜单';temp_cmdline:=E1.Text;
		E1.Text:=CB1.Text; B_edit1.Text:='︽'; 
		ShowMessage(msg_edit); end 
	else 
		begin;L1.Text:='命令行参数';E1.Text:=temp_cmdline;
		B_edit1.Text:='︾';end;
  if E2.Visible or E3.Visible then E2.ResizeParent else W.Height:=W.Height-E2.Height;
  if E2.Visible then E2changed:=false;
end;

procedure B_edit2_Click(Dummy:Pointer; Sender: PControl);
begin;
  if not E3.Visible then begin;E3.Text:=StrLoadFromFile(fn);E3changed:=false;end
  else if (fn<>'') and (E3changed) then 
    if (ShowMsg('您可能对文件进行了改动，是否存盘？',MB_YESNO)=ID_YES) then StrSaveToFile(fn,E3.Text);

  E3.Visible:=not E3.Visible;
  if not E3.Visible then B_edit2.Text:='︾' else B_edit2.Text:='︽';
  if E2.Visible or E3.Visible then E2.ResizeParent else W.Height:=W.Height-E2.Height;
end;

procedure B_file1_Click(Dummy:Pointer; Sender: PControl);
begin
Dlg1.Filename:='*.exe;*.com;*.bat;*.cmd;*.btm';
if Dlg1.Execute then
  begin;E1.Text:=Dlg1.Filename+' ';E2.Clear;end;
end;

procedure B_file2_Click(Dummy:Pointer; Sender: PControl);
begin
if Dlg1.Execute then fn:=FileShortPath(Dlg1.Filename);
if E1.Selection='' then E1.Text:=E1.Text+fn+' ' else E1.Selection:=fn+' ';
end;

procedure B_dir1_Click(Dummy:Pointer; Sender: PControl);
begin
if Dlg1.Execute then ChDir(ExtractFilePath(Dlg1.Filename));
end;

procedure B_dir2_Click(Dummy:Pointer; Sender: PControl);
begin
Dlg1.Filename:='*.*';
if Dlg1.Execute then
  E1.Text:=E1.Text+FileShortPath(ExtractFilePath(Dlg1.Filename))+' ';
end;

procedure B_help_Click(Dummy:Pointer; Sender: PControl);
begin;ShowMessage(help);end;

procedure B_options_Click(Dummy:Pointer; Sender: PControl);
begin;
  ReadConfig;//WriteConfig
  winexec(PChar(editor+' '+cfg),SW_SHOW);
  ShowMessage('如果设置完毕，请点击[确定]启用新的设置。');
  ReadConfig;
end;

procedure B_MouseMove(dummy:Pointer;Sender: PControl;var Mouse: TMouseEventData);
begin
  W.SimpleStatusText:=Sender.CustomData;
end;

procedure SetEvents;
var i,j:integer;
begin;
  DragAcceptFiles(w.Handle,True); // 允许接受拖放文件
  W.Onmessage := TOnMessage( MakeMethod(nil, @FormMessage));

  B_run.OnClick := TOnEvent( MakeMethod( nil, @B_run_Click ) );
  B_help.OnClick := TOnEvent( MakeMethod( nil, @B_help_Click ) );
  B_options.OnClick := TOnEvent( MakeMethod( nil, @B_options_Click ) );
  CB0.OnChange := TOnEvent( MakeMethod( nil, @CB0Change ) );
  CB1.OnChange := TOnEvent( MakeMethod( nil, @CB1Change ) );
  B_file1.OnClick := TOnEvent( MakeMethod( nil, @B_file1_Click ) );
  B_file2.OnClick := TOnEvent( MakeMethod( nil, @B_file2_Click ) );
  B_dir1.OnClick := TOnEvent( MakeMethod( nil, @B_dir1_Click ) );
  B_dir2.OnClick := TOnEvent( MakeMethod( nil, @B_dir2_Click ) );
  B_edit1.OnClick := TOnEvent( MakeMethod( nil, @B_edit1_Click ) );
  B_edit2.OnClick := TOnEvent( MakeMethod( nil, @B_edit2_Click ) );
  E2.OnChange := TOnEvent( MakeMethod( nil, @E2Change ) );
  E3.OnChange := TOnEvent( MakeMethod( nil, @E3Change ) );
  C8.OnClick := TOnEvent( MakeMethod( nil, @C8Click ) );
  
  for i:=0 to W.ChildCount-1 do 
	  if W.Children[i]=P2 then 
		  for j:=0 to P2.ChildCount-1 do 
			  P2.Children[j].OnMouseMove:=TOnMouse( MakeMethod( nil, @B_MouseMove ) )
	  else
		  W.Children[i].OnMouseMove:=TOnMouse( MakeMethod( nil, @B_MouseMove ) );
end;

function ParamFrom(i:integer):string;
var j:integer;
begin;
  Result:='';for j:=i to ParamCount do Result:=Result+ParamStr(j)+' ';
end;





procedure AddMenus(v:string);
var i:integer;ext,s,k:string;
begin;
//CB1.Clear;
CB0.Add('关联菜单');
s:=v;i:=CB1.Count;
CB1.Add('--关联菜单');
repeat
  k:=S_Before('//',s);CB1.Add('|'+k);
until s='';
CB1.CurIndex:=i;
CB1Change(nil,nil);
end;


function GetMenus(f:string):string;
var i:integer;ext,s,k,v0:string;p:PStrList;
begin;
p:=NewStrList;p.Text:=menudata;
ext:=LowerCase(ExtractFileExt(f));v0:='';
if Length(ext)=0 then ext:=default_ext;
for i:=0 to p.Count-1 do 
  begin;
  s:=p.Items[i];
  if Pos('[',s)=1 then exit;
  k:=S_Before('=',s);
  if k='*' then Result:=s else if Pos(ext+',',k+',')>0 then begin;Result:=s+'//'+Result;end;
  end;
end;




begin;
tmp:=GetTempDir+_tmp;
log:=GetTempDir+_log;
exepath:=ExtractFilePath(ParamStr(0));
etc:=GetEnv('ETC')+'\';
if (Length(etc)=1) or not (FileExists(etc+_ini)) then etc:=exepath;
conf:=etc+_conf;
cfg:=etc+_ini;//msgok(cfg);msgok(conf);



InitObjs;
SetEvents;
SetFormOnTop(W,true);
SaveWindowSize;
W_OnAnotherInstance( W, GetCommandLine );
{
ReadConfig;
if ParamCount=0 then 
    begin;CB0.CurIndex:=1;CB0Change(nil, nil);end
else
  begin;
  fn:=ParamStr(1);
  E1.Text:=ExtractFileName(fn)+' '+ParamFrom(2);
  E2.Text:='%_f% %_a%';
  C6.Checked:=true;
  AddMenus(GetMenus(fn));
  end;
}
// msgok('xxx');
Run(W);
// msgok('xxx');
DelFile(log);
DelFile(tmp);
end.
