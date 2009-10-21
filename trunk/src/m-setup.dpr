{
v0.97: support multi-language config file m-setup.ini.*
v0.95:
v0.90[qhs]: 将listview改为treeview，用户可更加方便地用树状结构选择组件。 
v0.85: 支持通过语言文件修改字体大小及属性
v0.80: 多语言支持，可通过语言文件修改界面语言；修改comspec设置；允许自定义ftp列表；修正打开网络对话框后直接退出时的异常错误。
v0.75: 允许一个组件多个压缩包、多个组件同一压缩包；增加压缩包大小显示；未指定占用空间时，根据压缩包大小估计占用空间；
v0.7: 添加组件更新；修改一些bug。
v0.6: 每个压缩包可以单独指定解压目录；压缩包可以放在子目录中；在脚本中自动添加解压命令。
v0.5: 加入网络下载功能。加入下载进度条。下载有记录。增加了必须选择的组件的处理。
v0.4: 加入清空选项。加入占用空间估计。每个压缩包有单独的文件列表。
v0.3: 加入文件列表。改进了配置文件格式。不再依赖于4DOS。增加设置默认选项。
v0.2: 目录选择，描述文件，配置文件格式改变，简单分组功能
v0.1: 基本功能
}

//{$DEFINE DEBUG}
{$DEFINE RELEASE}
program MTeX_setup;
uses
  windows,messages,kol{,tooltip1}{,ftpsend},shlobj,ShellAPI,wininet,XPtheme,commctrl;
  {$I w32.pas}
  {$R mtex.res}
//  {$R ImageList1.res}
  {$R ImageListState.res}

  
const
  CS=#12;fn='m-setup';f_bat='__tmp__.bat';f_add='__tmp__.add';
  f_ini=fn+'.ini';f_readme='readme';f_rar='unrar.exe';
  dir_mtex='mtex-filelist.html';f_ver='version.ini';f_vernew='__version.$$$';//f_log='MTeX.log';
  dir='\MTeX';
  title='[中文MTeX套装] 组件安装/升级程序 v0.97 [mhb & qhs]'; 
  usage='请您在左框中选择您要安装的组件，然后点击按钮[开始安装]。'+CR+CR
       +'当您选择组件时，您可以在本区域看到对所选组件的说明。'+CR+CR
       +'多数情况下，典型的组件已经为您自动选中，因此您可以直接点击按钮[开始安装]来进行默认的安装。'+CR+CR
       +'如果您只是升级，请不要选中"安装前清空您选择的目标文件夹"。'+CR+CR;
  net_msg='未发现本程序的配置文件，请您接着点击按钮[设置网络]设置网络并下载本程序需要的配置文件。'
         +CR+CR+'本程序还将根据您的网络设置和选择的组件列表，自动下载并安装缺少的安装包。'+CR+CR;
  net_hint= '提示：请在下面分别设置http/ftp服务器地址和代理服务器地址。'+CR
           +'      代理服务器格式：协议=地址[:端口]'+CR
           +'      例如 http=10.0.0.1:80, ftp=10.0.0.1:2100, socks=10.0.0.1:1080'+CR
           +'注意：ftp.ctex.org 对 30 秒内超过 5 次连接的 IP 自动封禁 12 小时。';
  stat_msg='本程序能从 CTEX 的 ftp 服务器上下载安装需要的文件，下载的文件将放在本程序所在的目录内。'         +'因此强烈建议您把本安装程序放在一个单独的目录中，再运行本安装程序。'
          +'请点击按钮[设置网络]设置网络（如果本地已有需要的文件，则可跳过此步），然后点击按钮[开始安装]。'
          +'该程序将自动根据您的网络设置和选择的组件列表，自动下载并安装缺少的压缩包。'+CR
          +'注意：通过本程序下载的文件您不必删除，今后再次运行本安装程序时可以直接使用这些文件，不需要再次下载。'+CR;
  msg_net_err='网络连接失败，请检查或重试您的网络设置。';
  msg_net_ok='网络连接成功，您可以继续下一步操作！';
  msg_download='您选择的组件需要以下文件，是否继续从网上下载它们？';
  msg_install='点击[确定]将开始安装，点击[取消]可退出安装。';
  msg_progress='正在下载需要的安装包，根据网络的速度，可能需要较长时间，请您耐心等待……'+CR+CR
              +'下载过程中会显示一个随时间变化的进度条，但不表示下载的百分比。'+CR+CR
              +'下载完毕后将会提示您是否继续安装，您可以选择[取消]终止本次安装，'
              +'下一次安装时将不需要再次下载您在本次安装中已经下载过的安装包文件。'+CR+CR;
  msg_upd_none='选择的组件无更新!';
  msg_upd='下列组件需要更新，是否从网上下载它们？';
  msg_upd_noexist='未在本地发现下列需要更新的组件，是否从网上下载它们？';
  msg_upd_nopak='请选择需要检查更新的组件!';
  msg_upding='正在更新组件 ...';
  msg_upd_finished='更新完成!';
  msg_setup_finished='已完成安装。点击[确定]退出。';
  msg_proxy_invalid='请正确填写代理服务器地址！';
  msg_connecting='正在连接 ';
  msg_downloading='正在下载文件 ';
  msg_success='成功';
  msg_fail='失败';
  msg_ini_missing='缺少 m-setup.ini 文件！';
  msg_ini_error='m-setup.ini 文件错误！';
  def_ftpsite=//'ftp://2823:2823@210.77.2.99:2121/Soft/Mathematics/TeX/mtex/current/';
  //'ftp://localhost/mtex/';
  'ftp://ftp.ctex.org/pub/tex/systems/mtex/current/';
  def_ftpsite2='ftp://mtex:mtex@137.132.146.202/mtex/current/';
//  'http://210.77.3.140';
//  'http://localhost';
  unpack_cmd='unrar.exe x -o+%SRC%\%ARC%.rar @%ARC%. %DIR%\';
  BufferSize = 65536;MAX_ITEMS = 3000;
  FormatStr = 'm-setup 将于 %d 秒后自动重新连接完成下一步操作!';
  Answers = '确定/取消';

var 
  W,LV1,TV,PN1,LW1,L1,L2,L3,L4,E1,E2,B0,B1,B2,B3,B4,C1,C2,D1,D2,D3,CB1,CB2,EB1,W_net,E_net,CB_net,B_net,B_net2,PBar,bUpd,CK_net,TT_net,CT_net,Dialog:PControl;
  IL:PImageList;OD:TOpenDirDialog;
  s_cfg,s_des,s_mtex,comspec,ext,s_cmd,s_add,s_del,s_need,s_dir,ftpsite,ftp_host,ftp_dir,proxy0,proxyserver,s_ver,mtex_dir:string;
  p,LNam,LSec,L_n,L_s,L_ftp,L_pak,L_arc,p_log{,p_upd},FtpList:PStrList;
  default:array[0..MAX_ITEMS] of byte;
  TV_ind:array[0..MAX_ITEMS] of THandle;
  est_size:array[0..MAX_ITEMS] of word;
  hSession,hConnect,hConn,hFind: HINTERNET;
//  FFD:TWin32FindData;
  Timer:PTimer;TimerCnt,LastItem:integer;
  Thread:PThread;
  bUseProxy,bUseHttp,bStopThread:bool;
  connect_time: array of dword;
  max_connect_times, current_times, lefttime: integer;
  ini_file:string;//[mhb] 01/23/09
type
  TLVHitTestInfo = packed record
    pt: TPoint;
    flags: DWORD;
    iItem: Integer;
    iSubItem: Integer;
end;


{$I treeview3.pas}


function ThreadOnExec( Sender: PThread ): Integer; forward;
procedure IniRead; forward;

function DelDirectory(const Source:string): boolean;
var fo: TSHFILEOPSTRUCT;
begin
FillChar(fo, SizeOf(fo), 0);
with fo do
begin
Wnd := 0;
wFunc := FO_DELETE;
pFrom := PChar(source+#0);
pTo := #0#0;
fFlags := FOF_NOCONFIRMATION{+FOF_SILENT};
end;
Result := (SHFileOperation(fo) = 0);
end;

function BaseFileName(fn:string):PChar;
begin;
Result:=StrRScan(PChar(fn),'/')+1;
end;

function GetNowTime(prefix:string='';suffix:string=''):string;
var systemtime:Tsystemtime; datetime:Tdatetime;
begin;
//  GetLocalTime(SystemTime);
//  SystemTime2DateTime(SystemTime,DateTime);
//  Result:=prefix+DateTime2StrShort(DateTime)+suffix;
Result:=prefix+Time2StrFmt('HH:mm:ss',Now)+suffix;
end;

procedure AddPath(d:string);
var s:string;
begin;
  if DirectoryEmpty(d) then Exit;
  s:=';'+GetEnv('PATH');
  if Pos(';'+Uppercase(d),Uppercase(s))=0 then SetEnv('PATH',d+s);
end;

procedure AddConnectTime;
var i: Integer; s: String;
begin;
  Inc(current_times);
  if (current_times>=max_connect_times) then begin;
    Inc(max_connect_times,50);
    SetLength(connect_time, max_connect_times);
  end;
  connect_time[current_times]:= GetTickCount;
//  Msg_Ok(int2str(current_times));
//  for i := 1 to current_times do
//  begin { for }
//    s:=s+Format('%d',[connect_time[i]]){int64_2str(connect_time[i])}+CR;
//  end;  { for }
//  Msg_Ok(s);
end;

procedure Close_Msg( Dummy, Sender: PControl; var Accept: Boolean );forward;

procedure Timer1Event(Dummy: Pointer; Sender: PControl);
begin;
  Dec(lefttime);//w.caption:=int2str(lefttime);
  if (LeftTime<0) then begin;Dialog.Children[2].click;end;
  Dialog.Children[1].caption:=Format(FormatStr,[LeftTime]);
end;

function ShowWait(S: String; Time: Integer):integer;
var //Dialog:PControl;
    Buttons: PList;
    Btn: PControl;
    AppTermFlag: Boolean;
    Lab, D: PControl;
    Y, W, I: Integer;
    Title: String;
    DlgWnd: HWnd;
    AppCtl: PControl;
    Timer1: PTimer;
begin;
//  AppTermFlag := AppletTerminated;
//  AppCtl := Applet;
//  AppletTerminated := FALSE;
  Title := '连接限制';
//  if pos( '/', Answers ) > 0 then
//    Title := 'Question';
  if Applet <> nil then
    Title := Applet.Caption;
  Dialog := NewForm( Applet, Title );//.SetSize( 300, 100 );
  Dialog.Style := Dialog.Style and not (WS_MINIMIZEBOX or WS_MAXIMIZEBOX);
  SetFont(Dialog.Font,'宋体,12');
  
  Dialog.Tag := 102;
  Dialog.OnClose := TOnEventAccept( MakeMethod( Dialog, @Close_Msg ) );
  Dialog.Margin := 8;
  NewWordWrapLabel(Dialog,s).SetSize(300,20).PlaceDown.ResizeParent;
  D := NewLabel(Dialog, Format(FormatStr,[Time])).SetSize(300,20).PlaceDown.shift(0,-5).ResizeParent;

  Buttons := NewList;
  Btn := NewButton( Dialog, '  确定  ' ); Btn.visible:=false;
  Buttons.Add( Btn );
  Btn := NewButton( Dialog, '  取消  ' ).Placedown.ResizeParent;
  Btn.left := (Dialog.width - Btn.Width) div 2;
  Btn.Shift(0,20).ResizeParent;
  Dialog.ActiveControl := Btn;
  Buttons.Add( Btn );

  for I := 0 to Buttons.Count-1 do
  begin
    Btn := Buttons.Items[ I ];
    Btn.Tag := I + 1;
    Btn.OnClick := TOnEvent( MakeMethod( Dialog, @OKClick ) );
    Btn.OnKeyDown := TOnKey( MakeMethod( Dialog, @KeyClick ) );
  end;
  Dialog.CenterOnParent.Tabulate.CanResize := FALSE;
  Buttons.Free;

  Timer1:=NewTimer(1000);
  Timer1.OnTimer:=TOnEvent( MakeMethod( Dialog, @Timer1Event ) );
  LeftTime:=Time;Timer1.Enabled:=true; Timer.Enabled:=false;
  Dialog.CreateWindow;Dialog.ShowModal;
  Timer1.Enabled:=false; Timer.Enabled:=true;
  Result := Dialog.ModalResult;
//  Dialog.Close;
  Dialog.Free;
end;

function LimitConnect:Boolean;
var t: Dword;i,j:integer;
begin;
  result:=false;
  if CT_net=nil then Exit;//[mhb]
  i:=str2int(TT_net.text);j:=str2int(CT_net.text);//Msg_Ok(TT_net.text+CR+CT_net.text);
  if CK_net.checked and (i>0) and (j>0) and (current_times>=j-1)  then
  begin;
    t := (Gettickcount-connect_time[current_times-j+1]) div 1000;
    if t < i then //begin;
//      if (thread.Terminated) then Msg_Ok('y') else Msg_Ok('n');
      if (ShowWait('您已在 '+int2str(i)+' 秒内连接服务器 '+int2str(j)+' 次!',i-t)<>1) then begin;
        Result:=true;
        thread.terminate; bStopThread:=true;
        Timer.Enabled:=false;
      end;
  end;
//  result:=false;
end;

function GetV(item,part:integer):string;
var s,si,des,cmd,cfg,arcs,f_arc,f_add,f_del,f_need,f_dir,n,f,d,p,arc,un_cmd:string;f_siz,i,arcsiz:integer;lst:PStrList;ch:Char;
begin;
s:=LSec.Items[item];if s='' then s:=CR+CR;
lst:=NewStrList;lst.Text:=s;f_siz:=0;arcsiz:=0;
un_cmd:='';arcs:='';
for i:=0 to lst.Count-1 do 
  begin;si:=lst.Items[i]+CR;ch:=si[1];Delete(si,1,1);
  case ch of
  '=': begin;
       d:=S_Before(CR,si);f_arc:=S_Before('->',d);
       if d='' then d:='.';
       f_add:=f_add+'='+f_arc+CR;arcs:=arcs+f_arc+CR;
       arcsiz:=arcsiz+FileSize(f_arc);
       p:=ExtractFileExt(f_arc);n:=ExtractFileNameWOExt(f_arc);
       if {(d<>'') and} FileExists(f_arc) then 
         if (p='.rar') then begin;un_cmd:='unrar.exe x -o+ %SRC%\'+f_arc+' @'+n+'.$$$ '+d+'\'+CR;end;
       cmd:=cmd+un_cmd;
       end;
  '+':f_add:=f_add+si;
  '-':f_del:=f_del+si;
  '*':cfg:=cfg+si;
  '#':des:=des+si;
  '@':des:=des+StrLoadFromFile(si);
  '<':f_need:=f_need+si;
  '>':f_dir:=f_dir+si;
  '$':f_siz:=f_siz+Str2Int(si); 
  else cmd:=cmd+ch+si;
  end;
  end;

if f_siz=0 then f_siz:=arcsiz * 2 div 1000;

case part of 
   -1:Result:=arcs;//f_arc;
    0:Result:=des;
    1:Result:=cfg;
    2:Result:={CR+}cmd;
    3:Result:={CR+}f_add;
    4:Result:={CR+}f_del;
    5:Result:=f_need;
    6:Result:=f_dir;
    7:Result:=Int2Str(f_siz);
    8:Result:=Int2Str(arcsiz);
    end;
end;

procedure CalcSize;var n,s:string;i,j,siz:integer;
begin;siz:=0;
  for i:=0 to LNam.Count-1 do 
	  begin;
	  j:=TV_ind[i];
      if (TV.TVItemStateImg[j]=ST_CHECK) then 
		  begin;
		  s:=GetV(i,7);
		  siz:=siz+Str2Int(s);
		  end;
	  end;
  L4.Text:=Int2Str(siz)+'KB';
end;


procedure Show_Info(Item:Integer);var n,s:string;i:integer;
begin;
n:=TV.TVItemText[Item];
i:=Integer(TV.TVItemData[Item]);
s:=L_arc.Items[i];
if Length(n)=0 then Exit;
LW1.Text:='【组件名称】'+n+CR
+'【需要安装包】'+GetV(i,8)+'字节'+CR+s+CR
+'【组件简要说明】'+CR+GetV(i,0)+CR
+'【估计占用空间】'+GetV(i,7)+'KB'+CR
+'（空间估计仅供参考，未必准确）'+CR;
end;




procedure TV_MouseMove(dummy:Pointer;Sender: PControl;
  var Mouse: TMouseEventData);
var
  HTI: TLVHittestinfo;
begin
HTI.pt.x:=Mouse.X;
HTI.pt.y:=Mouse.y;
HTI.iItem:=TV.Perform(TVM_HITTEST, 0, Integer(@ HTI));
//if LongBool(HTI.flags and LVHT_ONITEMICON) then 
if (LastItem<>HTI.iItem) then begin;Show_Info(HTI.iItem);lastItem:=HTI.iItem;end;
end;

procedure TV_MouseLeave(dummy:Pointer;Sender: PControl; var Mouse: TMouseEventData);
begin
LW1.Text:=usage;
LastItem:=-1;
end;

procedure D1Click(Dummy:Pointer; Sender: PControl);var i:integer;s:string;
begin;
  OD.Title:='请选择安装组件包所在的文件夹：';
  if OD.Execute then E1.Text:=FileShortPath(OD.Path);
  E1.Text:=ExcludeTrailingChar(E1.Text,'\');
end;

procedure D2Click(Dummy:Pointer; Sender: PControl);var i:integer;s:string;
begin;
  OD.Title:='请选择安装目标文件夹：';
  if OD.Execute then E2.Text:=FileShortPath(OD.Path);
  E2.Text:=ExcludeTrailingChar(E2.Text,'\');
  if Pos(dir,E2.Text)=0 then E2.Text:=E2.Text+dir;
end;

function CheckPak:boolean;var i,j:integer;s,arcs:string;
begin;
  Result:=false;L_pak.Clear;//p_log.clear;
  for i:=0 to LNam.Count-1 do 
	begin;j:=TV_ind[i];
    if (TV.TVItemStateImg[j]=ST_CHECK) then 
      begin;
        arcs:=L_arc.Items[i]+CR;
	repeat 
	  s:=S_Before(CR,arcs);
          if (Length(s)>0) then 
            if (L_pak.IndexOf(s)<0) then 
              if (not FileExists(s)) then L_pak.Add(s) else p_log.Add(s);
	until Length(arcs)=0;
       end;
	end;

  if L_pak.Count=0 then Exit;//Msg_Ok(l_pak.text);
  if Msg_(msg_download+CR+L_pak.Text,MB_YESNO)=ID_NO then Exit;
  Result:=true;
end;

function IsValidProxy(proxy:string):Boolean;
begin
  result:=false;
  if    (   (Pos('ftp=',proxy)=1) 
         or (pos('http=',proxy)=1)
         or (pos('socks=',proxy)=1))
     {and (pos('.',proxy)>1)} then result:=true;
end;

function InitProxy(proxy:string):string;
begin
  Result:='';
  bUseHttp:=false;
  if Pos('ftp=',proxy)=1 then 
  begin;Delete(proxy,1,4);proxy:='ftp=ftp://'+proxy;end;
  if pos('http=',proxy)=1 then
  begin;Delete(proxy,1,5);proxy:='http://'+proxy;bUseHttp:=true;end;
  Result:=proxy;
end;

function SetupNet:bool;
begin
  result:=false;
  proxy0:=E_net.text;
  proxyserver:=proxy0;
  if (proxyserver<>'') then
  begin {  }
    if (not IsValidProxy(proxyserver)) then
      begin Msg_Ok(msg_proxy_invalid);exit; end;
    proxyserver:=InitProxy(proxyserver);
    bUseProxy:=true;
  end
  else begin bUseProxy:=false;end;

  ftpsite:=CB_net.Text;
  if (CB_net.IndexOf(ftpsite)<0) then CB_net.add(ftpsite);  
  if (copyTail(ftpsite,1)<>'/') then ftpsite:=ftpsite+'/'; 

  result:=true;
end;

procedure SetInfoVScroll;
var intMin,intMax,scr_pos,i:integer;
    SCROLLINFO:tagSCROLLINFO;
begin
//  GetScrollRange(EB1.Handle, SB_VERT, intMin, intMax);
//  SetScrollPos(EB1.handle,SB_VERT,intMax,TRUE);
//  Msg_Ok(int2str(intMin)+' '+int2str(intMax));
  for i := 0 to eb1.count-8 do EB1.perform(WM_VSCROLL, SB_LINEDOWN, 0);
//  scr_pos:=GetScrollPos( EB1.Handle, SB_VERT );
//  Msg_Ok(int2str(scr_pos)+' '+int2str(eb1.count));

// this line can not work on windows 98
//  sendmessage(EB1.handle, WM_VSCROLL, SB_BOTTOM, 0);

  W.processmessages;
end;

{----------------------------------------------------------------------------}
{- Get remote file from a URL
{----------------------------------------------------------------------------}
function GetRemoteFile(hSession:hInternet; fileURL:string; sFileName:string):Boolean;
label again;
var //hConnect: HInternet;
    Buffer: array[1..BufferSize] of char;
    BufferLen, dwLength, dwCode, dwSize, dwReserved: DWORD;
    content: string;
    bInitalRequest: bool;
    nilptr:Pointer;
    DownloadedFile: PStream;
begin
//  Msg_Ok('GetRemoteFile');
  Result:=false;
  hConnect := InternetOpenURL(hSession, PChar(fileURL), nil,0, INTERNET_FLAG_DONT_CACHE or INTERNET_FLAG_KEEP_CONNECTION or INTERNET_FLAG_RELOAD,0);
  if hConnect=nil then begin;Exit;end;
  try
    {----------------------------------------------------------------------------}
    {- 以下部分为http代理验证
    {----------------------------------------------------------------------------}
    bInitalRequest := true;
    again:
    if not bInitalRequest then
    begin
      if not HttpSendRequest(hConnect, nil, 0, nil, 0) then begin;Exit;end;
    end;
    dwSize := sizeof(dwCode);
    if not InternetQueryOption(hConnect, INTERNET_OPTION_HANDLE_TYPE, @dwCode, dwSize) then
    begin;Exit;end;
    if ((dwCode = INTERNET_HANDLE_TYPE_HTTP_REQUEST) or (dwCode = INTERNET_HANDLE_TYPE_CONNECT_HTTP)) then
    begin
      dwSize := sizeof(DWORD); dwReserved := 0; 
      if not HttpQueryInfo(hConnect, HTTP_QUERY_STATUS_CODE or HTTP_QUERY_FLAG_NUMBER, @dwCode, dwSize, dwReserved) then begin;Exit;end;
      if dwCode = HTTP_STATUS_PROXY_AUTH_REQ then
      begin
        if not InternetQueryDataAvailable(hConnect, dwLength, 0,0) then begin;Exit;end;
        // 简化了程序，从弹出窗口里输入代理用户名和密码，无需另行设置
        if (InternetErrorDlg  (GetDesktopWindow(),
                               hConnect, 
                               ERROR_INTERNET_INCORRECT_PASSWORD,
                               FLAGS_ERROR_UI_FILTER_FOR_ERRORS or
                               FLAGS_ERROR_UI_FLAGS_GENERATE_DATA or
                               FLAGS_ERROR_UI_FLAGS_CHANGE_OPTIONS,
                               nilptr) = ERROR_INTERNET_FORCE_RETRY) then
        begin
          bInitalRequest := FALSE;
          goto again;
        end;
      end;
    end;
    {----------------------------------------------------------------------------}
    {- 以上部分为http代理验证
    {----------------------------------------------------------------------------}
    AddConnectTime;
    DownloadedFile := NewWriteFileStream(sFileName);
    try
      repeat
        if not InternetReadFile(hConnect, @Buffer, SizeOf(Buffer), BufferLen) then
        begin;Exit;end;
        if (BufferLen>0)and(WriteFileStream(DownloadedFile,Buffer,BufferLen)<>BufferLen)then
          begin;exit;end;
      until BufferLen = 0;
      Result := true;
    finally
       CloseFileStream(DownloadedFile);
    end;
  finally
    InternetCloseHandle(hConnect);
  end;
end;

{
function transformdatetime(dt:string):string;
begin;
result:=copy(dt,7,4)+'/'+copy(dt,1,2)+'/'+copy(dt,4,2)+' '+copy(dt,17,2)+copy(dt,12,5);
end;

// 从html文件里获取文件的日期
function parsehtml(fn:string):string;
var p1:PStrList;
    s1,s0,temp :string;
    i: integer;
begin;
if (not fileExists(fn)) then
begin;
  Msg_Ok(fn+' not found');exit;
end;
p1:=NewStrList;
p1.LoadFromFile(fn);
s1:=p1.text;
S_beforelast('<PRE>',s1);
S_after('</PRE>',s1);
s0:='';
while (pos('<A',s1)>0) or (pos('</A>',s1)>0)  do
begin
  s0:=s0+s_before('<A',s1);
  s_before('>',s1);
  s0:=s0+s_before('</A>',s1);
end; 
p1.text:=s0;
for i := p1.count-1 downto 0 do
begin
  if (pos('Directory',p1.items[i])>0) or (p1.items[i]='') then begin
    p1.delete(i);
  end else begin
    temp:=p1.items[i];
    p1.items[i]:=trim(strpas(strrscan(pchar(temp),' ')))+'='+transformdatetime(copy(temp,1,18));
  end;
end; 
result:=p1.text;
p1.free;
end;

function ListCurrentDirectory(handle: HInternet): string;
var
  hSearch: HINTERNET;
  findData: WIN32_FIND_DATA;
begin
  hSearch := FtpFindFirstFile(handle,nil,findData,0,0);
  if hSearch = nil then
  begin
    // Something has gone wrong!
    // Perhaps we've been disconnected?
    result := '';
  end
  else
  begin
    //--------------------------------
    // Loop reading directory entries.
    //--------------------------------
    result := '';
    repeat
      if (findData.dwFileAttributes<>FILE_ATTRIBUTE_DIRECTORY) then
        result := result+findData.cFileName+'='+int2str(findData.nfilesizelow)+' '+int2str(findData.dwFileAttributes)+CR;
    until not InternetFindNextFile(hSearch,@findData);
    InternetCloseHandle(hSearch);
  end;
end;
}

// 用于解析 ftp 的地址，只用了一次 :)
function before_S(sub:string;var s:string):string;
var i:integer;
begin;
  i:=Pos(sub,s)-1;//if i<0 then i:=Length(s);
  Result:=Copy(s,1,i);Delete(s,1,i+Length(sub));
end;

function Connect:boolean;
var i,fsize:integer;
    s,ftp_user,ftp_pass,ftp_port:string;
begin;
  Result:=false;
//  Msg_Ok('Connect');
  if (LimitConnect) then exit {else Msg_Ok('not limit')}; 
  s:=ftpsite;
  if (Pos('http://',s)=1) then begin;
    bUseHttp:=true;
{$IFDEF DEBUG}
    EB1.Add('远程主机['+ftpsite+']'+CR);
{$ENDIF}
  end else if Pos('ftp://',s)=1 then begin;
    delete(s,1,6);
    ftp_pass:=Before_S('@',s);//Msg_Ok(s);
    ftp_user:=s_before(':',ftp_pass);
    ftp_port:=s_before('/',s);
    ftp_host:=s_before(':',ftp_port);
    ftp_dir:=s;
    if ftp_user='' then ftp_user:='anonymous';
    if ftp_pass='' then ftp_pass:='anonymous@anonymous.com';
    if ftp_port='' then ftp_port:='21';
{$IFDEF DEBUG}
    EB1.Add({GetNowTime('[',']->')+}'远程主机['+ftp_host+'] 端口['+ftp_port+'] 用户名['+ftp_user+'] 密码['+ftp_pass+'] 目录['+ftp_dir+']'+CR);
{$ENDIF}
  end else begin;Exit;end;
  EB1.add(GetNowTime('[',']->')+msg_connecting+ftpsite+' ... ');SetInfoVScroll;

  if (bUseHttp) then // 如果使用http
  begin 
    if (bUseProxy) then begin;// 如果使用代理
{$IFDEF DEBUG}
      EB1.Add(CR+'http with proxy ['+proxyserver+']. ');
{$ENDIF}
      hSession := InternetOpen('m-setup', INTERNET_OPEN_TYPE_PROXY, pchar(proxyserver), nil, INTERNET_FLAG_KEEP_CONNECTION);
    end else begin
{$IFDEF DEBUG}
      EB1.Add(CR+'http without proxy. ');
{$ENDIF}
      hSession := InternetOpen('m-setup', INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, INTERNET_FLAG_KEEP_CONNECTION);
    end;
    if (hSession=nil) then begin EB1.add(msg_fail+CR);SetInfoVScroll;Exit; end;
    if (getremotefile(hSession,ftpsite,dir_mtex)) then
      begin EB1.add(msg_success+CR);Result:=true;end
    else begin EB1.add(msg_fail+CR);SetInfoVScroll;Exit; end;  
  end
  else begin // 其它情形
    if (bUseProxy) then begin
{$IFDEF DEBUG}
      EB1.Add(CR+'ftp with proxy ['+proxyserver+']. ');
{$ENDIF}
      hSession := InternetOpen('m-setup', INTERNET_OPEN_TYPE_PROXY, pchar(proxyserver), nil, INTERNET_FLAG_KEEP_CONNECTION);
    end
    else begin
{$IFDEF DEBUG}
      EB1.Add(CR+'ftp without proxy. ');
{$ENDIF}
      hSession := InternetOpen('m-setup', INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, INTERNET_FLAG_KEEP_CONNECTION);
    end;
    if (hSession=nil) then begin EB1.add(msg_fail+CR);SetInfoVScroll;Exit; end;
{$IFDEF DEBUG}
    EB1.Add('InternetOpen OK! ');
{$ENDIF}
    hConnect:= InternetConnect(hSession,PChar(ftp_host),str2int(ftp_port),pchar(ftp_user),pchar(ftp_pass),INTERNET_SERVICE_FTP,0,100);
    if hConnect=nil then begin;EB1.add(msg_fail+CR);SetInfoVScroll;Exit;end;
    AddConnectTime;
{$IFDEF DEBUG}
    EB1.Add('InternetConnect OK!');
{$ENDIF}
    if (ftp_dir<>'') then begin    
      if not FtpSetCurrentDirectory(hConnect, PChar(ftp_dir)) then 
        begin;EB1.add(msg_fail+CR);SetInfoVScroll;Exit;end;
    end;
    EB1.add(msg_success+CR);Result:=true;
//    Msg_Ok(ListCurrentDirectory(hConnect));
  end;
  SetInfoVScroll;
end;

procedure DisConnect;
begin;
  if (hConnect<>nil) then InternetCloseHandle(hConnect);
  if (hSession<>nil) then InternetCloseHandle(hSession);
end;

function DownloadFile(f:string;newfn:string='';bShowInfo:bool=true):bool;
const f_temp='__tmp__.$$$';
var s,d,fx:string;fsize:integer;bDownloaded:bool;
begin;
  Result:=false;
  if (bUseHttp)and(LimitConnect) then exit;
  if (newfn='') then newfn:=f;  
  if (bShowInfo) then EB1.add(GetNowTime('[',']->')+msg_downloading+f+' ... ');SetInfoVScroll;
  d:=ExtractFilePath(f);if (Length(d)>0) and (not DirectoryExists(d)) then MkDir(d);
  fx:=f; fx:=StrReplaceAll(fx,'\','/'); //Msg_Ok(f+cr+fx+cr+newfn);

  if ({bUseProxy and }bUseHttp) then begin // 如果使用http
//    AddConnectTime;
    bDownloaded:=getremotefile(hSession,ftpsite+fx,f_temp); 
  end else begin // 如果使用ftp
    bDownloaded:=FtpGetFile(hConnect,PChar(fx), PChar(f_temp), False,File_Attribute_Normal,Ftp_Transfer_Type_Binary, 0);
  end;  
  if (bDownloaded) then
  begin 
    fsize := FileSize(f_temp);//Msg_Ok(GetOSVer);
    if ( // MoveFileEx is only supported by win2000 or NT and later
         (GetOSVer='WIN_NT') and
         MoveFileEx(PChar(f_temp),PChar(newfn),MOVEFILE_COPY_ALLOWED or MOVEFILE_REPLACE_EXISTING)
     or
         ( (GetOSVer='WIN_95') and 
           ( (FileExists(newfn) and DeleteFile(PChar(newfn)) and MoveFile(PChar(f_temp),PChar(newfn)))
             or MoveFile(PChar(f_temp),PChar(newfn)) 
           ) )
       {CopyMoveFiles(f_temp,f,true)}
       ) then begin;
       Result:=true;
      if (bShowInfo) then      
      EB1.add(msg_success+format(' [%d.%d KB]',[fsize div 1024, (fsize mod 1024)*10 div 1024])+CR);
    end else begin;
      if (bShowInfo) then EB1.add(msg_fail+CR);
    end;
  end
  else begin if (bShowInfo) then EB1.add(msg_fail+CR); end;
  SetInfoVScroll;
end;

function ThreadOnDownloadIni( Sender: PThread ): Integer;
var I:integer;
//procedure DownloadIni;
begin;
//  i:=0;
  if not Connect then begin;Msg_Ok(msg_net_err);Exit;end;
  try
    if (bStopThread) then exit;
    DownloadFile(f_ini);
    DownloadFile(f_ini+'.'+GetMTeXLang);
    if (bStopThread) then exit;
    DownloadFile(f_readme);
    if not FileExists(f_rar) then 
    begin;
      if (bStopThread) then exit;
      DownloadFile(f_rar);
    end;

    s_ver:='';
    if not FileExists(f_ver) then begin;
      if (bStopThread) then exit;
      DownloadFile(f_ver);
    end else begin
      if (bStopThread) then exit;
      if (DownloadFile(f_ver,f_vernew,false)) then begin
        s_ver:=StrLoadFromFile(f_vernew)+CR;
        DeleteFile(f_vernew);
      end;
    end;//Msg_Ok(s_ver);
    
//    if (bStopThread) then exit;
    if FileExists(f_readme) then WinExec(PChar('notepad '+f_readme),SW_SHOW);
  finally
    DisConnect;
  end;

  IniRead;
  W_net.Close;
  if FileExists(f_ver) and (s_ver<>'') then bUpd.enabled:=true;
end;

procedure DownloadPak(pak:PStrList);
var i:integer;s:String;
begin;
//  msgok('x');
  if not Connect then begin;Msg_Ok(msg_net_err);DisConnect;Exit;end;
//  msgok('x');
  try
    if (bStopThread) then exit;
    for i:=0 to pak.Count-1 do 
    begin;
      if (DownloadFile(pak.Items[i])) then
      begin; //Msg_Ok(pak.Items[i]);
        if (bStopThread) then exit;
        if (s_ver<>'') then begin
          s:=strbetween(s_ver,pak.items[i]+'=',CR);//Msg_Ok(s);
          SetIniStr(mtex_dir+f_ver,'MTeX',pak.Items[i],s);
        end;
        p_log.add(pak.items[i]);
      end;
    end;
  finally
    DisConnect;
  end;
end;

//procedure checkUpdate;
function ThreadOnUpdate( Sender: PThread ): Integer;
label ENDUPD;
var tmp,s,s0,s1,s2,s3,s4:string;p,q,p_upd,p_pak,p_noexist:PStrList;i,j:integer;
begin;
  if (not FileExists(f_ver)) or (s_ver='') then exit;

  bUpd.enabled:=false;b1.enabled:=false;
  p_pak:=NewStrList;p_noexist:=NewStrList;p:=NewStrList;p_upd:=NewStrList;
  for i:=0 to LNam.Count-1 do 
  begin;j:=TV_ind[i];
    if (TV.TVItemStateImg[j]=ST_CHECK) then 
    begin;
      s:=L_arc.Items[j];
      if (Length(s)>0) then 
      begin;
        if (p_pak.IndexOf(s)<0) then
        begin;
          p_pak.Add(s);
          if (not FileExists(s)) then
            p_noexist.Add(s)
          else
            p.Add(s);          
        end;
      end;
    end;
  end;
  if (p_pak.text='') then begin;
    Msg_Ok(msg_upd_nopak);
    goto ENDUPD;
//    bUpd.enabled:=true;b1.enabled:=true;
//    result:=0;
//    exit;
  end;

//  Msg_Ok(p_pak.text);Msg_Ok(p_noexist.text);Msg_Ok(p.text);

  for i := 0 to p.count-1 do
  begin
    s:=p.items[i];
    s1:=getinistr(mtex_dir+f_ver,'MTex',s,'0');
    s2:=strbetween(s_ver,s,CR);
    if ( str2double(s1) < str2double(s2) ) then p_upd.add(s);
  end; 
//  Msg_Ok(p_upd.text);

  if (p_upd.text<>'')or(p_noexist.text<>'') then
  begin;
    if (p_noexist.text<>'')and(Msg_(msg_upd_noexist+CR+p_noexist.text,MB_OKCANCEL)=ID_OK) then begin;
//    if (p_noexist.text<>'')and(ShowQuestion(msg_upd_noexist+CR+p_noexist.text,Answers)=1) then begin;
      PBar.Progress:=0;
      PBar.Visible:=true;
      downloadPak(p_noexist);
      PBar.Visible:=false;
      if (bStopThread) then goto endupd;
    end;
    if (p_upd.text<>'') then
    begin;
      if (Msg_(msg_upd+CR+p_upd.text,MB_OKCANCEL)=ID_OK) then begin;
//    if (p_noexist.text<>'')and(ShowQuestion(msg_upd_noexist+CR+p_noexist.text,Answers)=1) then begin;
        EB1.Add(msg_upding+CR);SetInfoVScroll;
        PBar.Progress:=0;
        PBar.Visible:=true;
        downloadPak(p_upd);
        PBar.Visible:=false;
        if (bStopThread) then goto endupd;
        EB1.Add(msg_upd_finished+CR);SetInfoVScroll;
      end;
    end else Msg_Ok(msg_upd_none);
  end else Msg_Ok(msg_upd_none);

ENDUPD:
  p_pak.free;p_noexist.free;p.free;p_upd.free;
  bUpd.enabled:=true;b1.enabled:=true;
  result:=0;

//p:=NewStrList; p_upd:=NewStrList;
//s0:=getinisec(mtex_dir+f_ver,'Setup'); //Msg_Ok(s0);
//p.text:=s0; //Msg_Ok(int2str(p.count));
//for i := 0 to p.count-1 do
//begin { for }
//  tmp:=p.items[i];
//  s1 :=before_s('=1',tmp); //Msg_Ok(s1);
//  if (s1<>'') and ( str2double(getinistr(mtex_dir+f_ver,'MTex',s1,'0')) < str2double(strbetween(s_ver,s1,CR)) ) then p_upd.add(s1);
//end;  { for }
////Msg_Ok(p_upd.text);
//if (p_upd.text='') then begin;Msg_Ok(msg_upd_none);exit;end;
//if ShowMsg(msg_upd+CR+p_upd.text,MB_OKCANCEL or MB_SETFOREGROUND)=ID_CANCEL then Exit;
//downloadPak(p_upd);
//p.free; p_upd.free;
end;



procedure Install;
var i,j:integer;s,tmp,f_tmp,f_n:string;b:boolean;p,q:PStrList;
begin;
  if Msg_(msg_install,MB_OKCANCEL)=ID_CANCEL then Exit;
//  if ShowQuestion(msg_install,Answers)<>1 then Exit;
  if Length(E1.Text)=0 then D1Click(nil,nil);
  if Length(E2.Text)=0 then D2Click(nil,nil); 
  if C1.Checked and DirectoryExists(E2.Text) then DelDirectory(E2.Text);
  if not DirectoryExists(E2.Text) then MkDir(E2.Text);
  AddPath(E1.Text);AddPath(E2.Text);AddPath(E2.Text+'\bin');
  s:='';s_add:='';s_del:='';s_cmd:='';s_need:='';s_dir:='';
  for i:=0 to LNam.Count-1 do 
	begin;j:=TV_ind[i];
      if (TV.TVItemStateImg[j]=ST_CHECK) or (Pos('--',LNam.Items[i])=1) then 
         begin;         
	 s:=s+GetV(i,2){+CR};
	 s_add:=s_add+{'='+L_arc.Items[i]+CR+} GetV(i,3);//Msg_Ok(L_arc.items[i]);
	 s_del:=s_del+GetV(i,4);
	 s_need:=s_need+GetV(i,5)+CR;
	 s_dir:=s_dir+GetV(i,6)+CR;
	 end;
	end;

  ChDir(E2.Text);
  p:=NewStrList;p.Clear;p.Text:=s_del;
  for i:=0 to p.Count-1 do 
    if DirectoryExists(p.Items[i]) then DeleteFiles(p.Items[i]+'\*.*') else DeleteFiles(p.Items[i]);
  p.Clear;p.Text:=s_add+CR+'=';q:=NewStrList;q.Clear;
  f_tmp:='__TMP__';s_add:='';
  for i:=0 to p.Count-1 do begin;
    tmp:=p.Items[i];
    if Pos('=',tmp)=1 then 
      begin;Delete(tmp,1,1);
      f_n:=ExtractFileNameWOext(tmp);
      if not (f_n=f_tmp) then 
        begin;
	if Length(s_add)=0 then s_add:='*';
	if FileExists(f_tmp+'.$$$') then s_add:=StrLoadFromFile(f_tmp+'.$$$')+CR+s_add;//
	StrSaveToFile(f_tmp+'.$$$',s_add);
	f_tmp:=f_n;s_add:='';
	end;
      end
    else if not (tmp='') then 
      s_add:=s_add+CR+tmp;
  end;

  s:='@echo off'+CR//+'loadbtm on'+CR
    //+'path '+GetStartDir+';'+E1.Text+';'+Format('%s\bin;%%path%%',[E2.Text])+CR
    //+'set LST='+f_add+CR
    +'set SRC='+E1.Text+CR
    +'set DEST='+E2.Text+CR
    +'set WINDIR='+GetWindowsDir+CR
    +'set EXEDIR='+GetStartDir+CR
    +s_cfg+CR
    +':#START'+CR
    +s+CR
    +'goto #END'+CR
    +':#STOP'+CR;

  StrSaveToFile(f_bat,s);
  s_cmd:=comspec+f_bat;ChDir(E2.Text);
  W.Visible:=false;
{$IFDEF RELEASE}
  shell(s_cmd,sw_SHOW,true);
{$ENDIF}
  W.Visible:=true;

// 更新 version.ini 的 Setup 节
  for i := 0 to p_log.count-1 do
  begin { for }
//    Msg_Ok(p_log.items[i]);
    setinistr(mtex_dir+f_ver,'Setup',p_log.items[i],'1');
  end;  { for }

//  ShowMsg(msg_setup_finished,MB_OK or MB_SETFOREGROUND);
  Msg_(msg_setup_finished,MB_OK);
{$IFDEF RELEASE}
  DeleteFiles('*.$$$');
  DeleteFile(f_bat);
{$ENDIF}
  Halt(0);
end;

procedure B1Click(Dummy:Pointer; Sender: PControl);
begin;
  p_log.clear;
  if CheckPak then 
    begin;
    Timer.Enabled:=true;TimerCnt:=0;
    LW1.Text:=msg_progress;
//    Thread:=NewThread;
    Thread.OnExecute:= TOnThreadExecute ( MakeMethod( nil, @ThreadOnExec ) );
    bStopThread:=false;
    Thread.Execute; 
//    Thread.Resume;
    end
  else Install;
end;

procedure bUpdClick(Dummy:Pointer; Sender: PControl);
begin;
Timer.Enabled:=true;TimerCnt:=0;
Thread:=NewThread;
Thread.OnExecute:= TOnThreadExecute ( MakeMethod( nil, @ThreadOnUpdate ) );
bStopThread:=false;
Thread.Execute;
//Thread.Resume;
//checkUpdate;
end;

procedure B2Click(Dummy:Pointer; Sender: PControl);var i:integer;s:string;
begin;
//Disconnect;
if W_net<>nil then W_net.close;
w.destroy;
Halt(1);
end;

procedure C2Click(Dummy:Pointer; Sender: PControl);var i,k:integer;s:string;
begin;
  if not C2.Checked then k:=1 else k:=0;
  //C2.Checked:=not C2.Checked;
  for i:=0 to LNam.Count-1 do 
    if Length(LNam.Items[i])>0 then 
		begin;
		if k=0 then TV.TVItemStateImg[TV_ind[i]]:=ST_UNCHECK
			else TV.TVItemStateImg[TV_ind[i]]:=default[i];
		end;
  CalcSize;
end;

function S_ParseIni2(s_ini:string;nam,sec:PStrList):string;
var s,s_cfg,s_nam,s_sec,s_opt,s_sep:string;var i:integer;
begin;
  s:=s_ini;nam.Clear;sec.Clear;
  s_cfg:=S_before(CR+'[[',s);//msgOK(s_cfg);
  Result:=s_cfg;
  repeat
    s_opt:=S_before(CR,s);
    s_nam:=S_before(']]'+CR,s_opt);
    i:=Pos(']]',s_nam);
    if i>0 then s_nam:=Copy(s_nam,1,i-1);
    nam.Add(s_nam);
    s_sec:=S_before(CR+'[[',s);
    sec.Add(trim(s_sec));
    //msgOK(s_opt+'@'+CR+s_nam+'@'+CR+s_sec+'@'+CR+s);
  until s='';
  if (s='') then sec.Add(S_before(CR,s_sec));
end;

function Read_Ini2(f:string;nam,sec:PStrList):string;
begin;Result:=S_ParseIni2(StrLoadFromFile(f),nam,sec);end;

            
            
procedure IniRead;var i,k:integer;j:THandle;s:string;c:char;
begin;
  ini_file:=f_ini+'.'+GetMTeXLang;//[mhb] 01/23/09
  if not FileExists(ini_file) then ini_file:=f_ini;//[mhb] 01/23/09
  if (not FileExists(ini_file)) then begin;Msg_Ok(msg_ini_missing);exit;end;
  
  s_cfg:=Read_ini2(ini_file,LNam,LSec);//Read_ini(fn+'.des',L_n,L_s);

  if (trim(LNam.text)='')or(trim(LSec.text)='') then begin;Msg_Ok(msg_ini_error);exit;end;
//  Msg_Ok('@'+LNam.text+'@');Msg_Ok('@'+LSec.text+'@');
//  Msg_Ok(int2str(lnam.count)+cr+int2str(lsec.count));
  L_arc.Clear;
  TV.clear;k:=0;

  for i:=0 to LNam.Count-1 do 
    begin;
    s:=LNam.Items[i];c:=s[1];
    if (c='*') or (c='!') then 
		begin;
		Delete(s,1,1);
	    LNam.Items[i]:=s;
		end;
	if (Pos('--',s)=1) then 
		begin;
		j:= TV.TVInsert( 0, 0, s );
		TV.TVSelected := j;
		k:=i;
		end
	else
		begin;
		j := TV.TVInsert( TV.TVSelected, 0, s );
		end;
	TV.TVItemData[j]:=Pointer(i);
	TV_ind[i]:=j;
    if (c='*') or (c='!')  then SetChildState(j,ST_CHECK) else SetChildState(j,ST_UNCHECK);
	SetParentState(j);
	if (Pos('--',s)<>1) then default[k]:=TV.TVItemStateImg[TV.TVSelected];
    default[i]:=TV.TVItemStateImg[j];
    s:=GetV(i,-1);//Msg_Ok(s);
//    if (Length(s)<2) and (i>0) then s:=L_arc.Items[i-1];
    L_arc.Add(s);
    end;
  CalcSize;
end;

procedure B_net_Click(Dummy:Pointer; Sender: PControl);var i:integer;s:string;
begin;
  if (not SetupNet) then exit; 
  if not Connect then Msg_Ok(msg_net_err) else Msg_Ok(msg_net_ok);
  DisConnect;
end;

procedure B_net2_Click(Dummy:Pointer; Sender: PControl);var i:integer;s:string;
begin;
  if (not SetupNet) then exit;
//  Thread:=NewThread;
  Thread.OnExecute:= TOnThreadExecute ( MakeMethod( nil, @ThreadOnDownloadIni ) );
  bStopThread:=false;
  Thread.Execute; 
//Thread.Resume;
//  DownloadIni;
//  IniRead;
//  W_net.Close;
//  if FileExists(f_ver) and (s_ver<>'') then  
//    bUpd.enabled:=true;
end;

procedure SetCenterOnScreen( Wnd: HWnd );
var R: TRect;
    W, H: Integer;
begin
  GetWindowRect( Wnd, R );
  W := R.Right - R.Left;
  H := R.Bottom - R.Top;
  R.Left := (GetSystemMetrics( SM_CXSCREEN ) - W) div 2;
  R.Top := (GetSystemMetrics( SM_CYSCREEN ) - H) div 2;
  MoveWindow( Wnd, R.Left, R.Top, W, H, True );
end;

procedure Close_Msg( Dummy, Sender: PControl; var Accept: Boolean );
begin
  //msgok('xxx');
  case Sender.Tag of 
    101:  begin;
            Accept := false;
            Sender.hide;
          end;
    102:  begin;
            Accept := True;
            Sender.ModalResult := 2;
          end;
    103:  begin;
            Accept := FALSE;
            Sender.ModalResult := -1;
          end;
  end;
//  Sender.ModalResult := -1;
end;
  
procedure Close_W( Dummy, Sender: PControl; var Accept: Boolean );
begin
B2Click(Dummy,Sender);
end;
  
procedure B0Click(Dummy:Pointer; Sender: PControl);var i:integer;
begin;
if (W_net=nil) then begin;
  W_net:=NewForm(Applet,'网络设置').Tabulate;
  SetFont(W_net.Font,'宋体,12');
  //W_net.Left:=W.Left+100;W_net.Top:=W.Top+100;
  W_net.style := W_net.style and not (WS_MINIMIZEBOX or WS_MAXIMIZEBOX or WS_THICKFRAME);
  W_net.tag := 101;
  W_net.OnClose := TOnEventAccept( MakeMethod( W_net, @Close_Msg ) );
  W_net.margin:=3;
  NewWordWrapLabel(W_net,net_hint).Shift(0,0).SetSize(450,52).PlaceDown.ResizeParent;
  CK_net:=NewCheckbox(W_net,'服务器连接限制：').SetSize(120,20).PlaceDown.shift(0,0);
  CK_net.font.color:=clred;  CK_net.checked:=true;
//  NewLabel(W_net,'').SetPosition(25,48).SetSize(58,20).font.color:=clred;
  TT_net:=NewEditbox(W_net,[]).SetSize(40,18).PlaceRight;TT_net.color:=clwhite;
  TT_net.TextAlign:=tacenter;TT_net.font.color:=clblue;TT_net.text:='30';
  NewLabel(W_net,'秒内最多连接服务器').SetSize(109,20).PlaceRight.Shift(2,3);
  CT_net:=NewEditbox(W_net,[]).SetSize(40,18).PlaceRight.Shift(0,-3);CT_net.color:=clwhite;
  CT_net.TextAlign:=tacenter;CT_net.font.color:=clblue;CT_net.text:='4';
  NewLabel(W_net,'次').PlaceRight.Shift(0,3).ResizeParent;
  NewLabel(W_net,'安装包下载地址：').SetSize(100,20).PlaceDown.ResizeParent;
  CB_net:=NewCombobox(W_net,[]).SetSize(350,20).PlaceRight.Shift(0,-3).ResizeParent;
  for i:=0 to FtpList.Count-1 do CB_net.Add(FtpList.Items[i]);CB_net.DropDownCount:=20;
  if (ftpsite<>'') then CB_net.Text:=ftpsite else CB_net.Text:=def_ftpsite;
  CB_net.Color:=clWhite;
  NewLabel(W_net,'代理服务器地址：').SetSize(100,20).PlaceDown.Shift(0,3).ResizeParent;
  E_net:=NewEditbox(W_net,[]).SetSize(350,20).PlaceRight.Shift(0,-3).ResizeParent;
  E_net.Color:=clWhite;E_net.Focused:=true;
  E_net.text:=proxy0;
  B_net:=NewButton(W_net,'1.测试当前的网络设置').SetSize(225,30).PlaceDown.ResizeParent;
  B_net.OnClick := TOnEvent( MakeMethod( nil, @B_net_Click ) );
  B_net2:=NewButton(W_net,'2.下载并调入需要的配置文件').SetSize(225,30).PlaceRight.ResizeParent;
  B_net2.OnClick := TOnEvent( MakeMethod( nil, @B_net2_Click ) );
  W_net.Add2AutoFree(W);
  SetCenterOnScreen(W_net.handle);
  W_net.createwindow;
end;
//  PostMessage(w.Handle, WM_ACTIVATE, WA_INACTIVE, 0 );
//  EnableWindow(w.handle,false);
  W_net.ShowModal;w_net.close;
end;

procedure TimerEvent(Dummy:Pointer; Sender: PControl);
begin;
TimerCnt:=TimerCnt mod 100 + 1;
PBar.Progress:=TimerCnt;
end;

function ThreadOnExec( Sender: PThread ): Integer; var i:integer;
begin;
//Msg_Ok('a');
B1.Enabled:=false;
PBar.Progress:=0;
PBar.Visible:=true;
DownloadPak(L_pak);
//sendmessage(EB1.handle, WM_VSCROLL, SB_BOTTOM, 0);
B1.Enabled:=true;PBar.Visible:=false;
if (bStopThread) then exit;
Result:=0;
Install;
end;

{//[mhb] removed: remove codes into treeview3.pas
function FormMessage(Dummy_Self: PObj; var Msg: TMsg; var Rslt: Integer ): Boolean;
begin
  Result := FALSE;
//  if ((Msg.message=WM_SYSCOMMAND))and(Msg.wparam=SC_CLOSE) then
  if (msg.message=wm_close) then
  begin;
    Disconnect;//Msg_Ok('Quit');
//    Result:=true;
  end;
end;
}



var i:integer;  
  
procedure Init;
begin;
  FtpList:=NewStrList;FtpList.Clear;
  if FileExists(fn+'.ftp') then FtpList.LoadFromFile(fn+'.ftp') 
  else begin;FtpList.Add(def_ftpsite);FtpList.Add(def_ftpsite2);end;
  LNam:=NewStrList;LSec:=NewStrList;
  L_pak:=NewStrList;L_pak.Clear;
  L_arc:=NewStrList;L_arc.Clear;
  L_n:=NewStrList;L_s:=NewStrList;p:=NewStrList;
  p_log:=NewStrList;//p_upd:=NewStrList;
  if ParamCount>0 then s_mtex:=Trim(ParamStr(1));// else s_mtex:=Trim(GetEnv('MTEX'));
  if s_mtex='' then s_mtex:='c:\MTeX';
  ftpsite:=def_ftpsite;
  mtex_dir:=GetStartDir;
  AddPath(mtex_dir);
  Chdir(mtex_dir);
  comspec:=GetEnv('COMSPEC');
  if Length(comspec)=0 then comspec:='command.com';
  comspec:=comspec+' /c ';
  //if FileExists('4dos.com') then comspec:='4dos.com /e:5120 /c ' else comspec:='command.com /e:5120 /c ';
  //WebUpdate;
  Applet := NewApplet('m-setup');
  W := NewForm( Applet,title).Tabulate;  
  if not JustOne(W,fn) then Halt(0);
  W.Style:=W.Style and not (WS_MAXIMIZEBOX or WS_SIZEBOX);
  SetFont(W.Font,'宋体,12');
  //W.Font.ReleaseHandle;

  L1:=NewLabel(W,'安装组件文件夹').SetSize(100,20).PlaceRight;
  E1:=NewEditbox(W,[]).SetSize(300,20).PlaceRight;
  E1.Text:=ExcludeTrailingChar(GetStartDir,'\');E1.Color:=clWhite;
  D1:=NewButton(W,'浏览...').SetSize(50,20).PlaceRight;
  L2:=NewLabel(W,'安装目标文件夹').SetSize(100,20).PlaceDown;
  E2:=NewEditbox(W,[]).SetSize(300,20).PlaceRight;E2.Color:=clWhite;
  D2:=NewButton(W,'浏览...').SetSize(50,20).PlaceRight;
  E2.Text:=s_mtex;

  C1:=NewCheckBox(W,'安装前清空您选择的目标文件夹').SetSize(250,20).PlaceDown;
  C1.Checked:=true;
  IL:=NewImageList(W);
  IL.ImgWidth:=12;IL.ImgHeight:=12;//IL.ImgWidth:=15;IL.ImgHeight:=15;
  IL.LoadBitmap('ImageListState',clwhite);//IL.LoadBitmap('FORM1_IMAGELIST1',clMaroon);
  
  TV := NewTreeView(W,[tvoLinesRoot,tvoCheckBoxes],nil,IL).SetSize(250,300).PlaceDown;

  L3:=NewLabel(W,'您选择的组件需要的空间大致为： ').SetSize(200,20).PlaceDown;
  L4:=NewLabel(W,'0').SetSize(50,20).PlaceRight;CalcSize;
  C2:=NewCheckbox(W,'清除所有选择/恢复默认选择').SetSize(200,20).PlaceDown;
  C2.OnClick := TOnEvent( MakeMethod( nil, @C2Click ) );

  B0:=NewButton(W,'设置网络').PlaceDown.SetSize(62,30).ResizeParent;
  B1:=NewButton(W,'开始安装').PlaceRight.SetSize(62,30).ResizeParent;
  bUpd:=NewButton(W,'检查更新').PlaceRight.SetSize(62,30).ResizeParent;bUpd.enabled:=false;
  B2:=NewButton(W,'退出').PlaceRight.SetSize(62,30){.Shift(50,0)}.ResizeParent;
  W.Height:=W.Height-20;
  PN1:=NewPanel(W,esRaised).PlaceRight.AlignTop(C1).SetSize(200,W.Height-55).ResizeParent;
  LW1:=NewWordWrapLabel(PN1,usage).PlaceRight.SetSize(PN1.Width-4,PN1.Height-4);
  EB1:=NewEditBox(W,[eoMultiline, eoReadonly, eoNoHScroll]).PlaceDown.Shift(0,10).SetSize(W.Width-10,100).ResizeParent;
  EB1.Text:=stat_msg;
  PBar:=NewProgressBar(W).AlignTop(EB1).AlignLeft(EB1).Shift(0,-10).SetSize(W.Width-10,8);
  PBar.Visible:=false;

  W.Onmessage := TOnMessage( MakeMethod(nil, @FormMessage));
  W.OnClose := TOnEventAccept( MakeMethod( W, @Close_W ) );

  TV.OnKeyDown := TOnKey(MakeMethod(nil, @TV_OnKeyDown));
  TV.OnMouseDown := TOnMouse(MakeMethod(nil, @TV_OnMouseDown));
  TV.OnMouseMove:=TOnMouse( MakeMethod( nil, @TV_MouseMove ) );
  TV.OnMouseLeave:=TOnEvent( MakeMethod( nil, @TV_MouseLeave ) );

  
  D1.OnClick := TOnEvent( MakeMethod( nil, @D1Click ) );
  D2.OnClick := TOnEvent( MakeMethod( nil, @D2Click ) );
  B0.OnClick := TOnEvent( MakeMethod( nil, @B0Click ) );
  B1.OnClick := TOnEvent( MakeMethod( nil, @B1Click ) );
  bUpd.OnClick := TOnEvent( MakeMethod( nil, @bUpdClick ) );
  B2.OnClick := TOnEvent( MakeMethod( nil, @B2Click ) );
  Timer:=NewTimer(1000);
  Timer.OnTimer:=TOnEvent( MakeMethod( nil, @TimerEvent ) );
  Thread:=NewThread;
//  Thread.OnExecute:= TOnThreadExecute ( MakeMethod( nil, @ThreadOnExec ) );
  ini_file:=f_ini+'.'+GetMTeXLang;//[mhb] 01/23/09
  if not FileExists(f_ini) and not FileExists(ini_file) then Msg_Ok(net_msg)
  else IniRead;

  SetCenterOnScreen(W.handle);
  bUseProxy:=false;

  LastItem:=-1;
  max_connect_times:=100;
  current_times:=0;
  SetLength(connect_time,max_connect_times);
  bStopThread:=false;
  

end;


begin
  Init;
  Run(Applet);
end.