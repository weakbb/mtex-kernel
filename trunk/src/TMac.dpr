{
v0.995:增加tool_icon_rows,tool_icon_columns的设置; 
v0.991: 增加toolbar_pos_x,toolbar_pos_y的设置;自动调整符号面板位置保证显示全部符号板;主窗口位置不随符号面板位置而变化;符号面板去掉标题
v0.99: 增加tool_icon_sep,tool_icon_alpha的设置; 增加插入图片的对话框
v0.98: 增加激活颜色对话框的代码；增加状态栏提示
v0.97: 增加可定制的多层工具栏；自动隐藏符号板；可以配置快捷键；选编辑器后提示热键；图标大小可定制；可定制编辑器快捷键设置；自动读mtex.env；自动设置mtex环境变量；增加打开文件历史记录。
v0.90: 自动缩小为图标
v0.85: 修改配置文件格式：符号:-> **,模板-> ~~,向导-> >>
v0.80：可以通过语言文件设置字体大小
v0.75: 向导与模板文件路径可使用环境变量；向导可指定窗口部分标题，以避免重复打开向导程序；向导自动切换到向导程序所在路径。
v0.70: 可从环境变量ETC指定的目录读配置文件；缺省打开符号板；
v0.65: XP主题美化；对话框置顶。
v0.6: 增加通过外部程序实现的向导功能;

2006-3-12: 修正隐藏符号板会crash的bug；
           增加符号板鼠标无闪烁跟随提示；
           修正在符号板上通过鼠标获取符号字串可能发生的错位问题（定义dx和dy为浮点数，原为整型）；
           新增一个按钮用于发送模板到剪贴板或指定的编辑器（原为CB1.onchange）
           修正插入文本后光标不能正确定位（到^^）的问题（win32.pas的SendStrTo函数）；
           增加 '^|' 用于表示换行；
           修正配置文件改变后无法立即生效问题。
To do: 帮助；关于；改模板；自动探测配置文件改变；模板提示；符号板；
2006-10-15:v0.5  增加类别下拉框；支持从文件中读取某个模板；支持外部向导程序；

2005-7-22:自动探测Memo中是否修改；加入简单帮助；
2005-7-12:列表只读；光标定位；修正findW；
}
{$D SMALLEST_CODE}
{$D USE_DROPDOWNCOUNT}
uses
  windows,messages,kol,CommCtrl,xptheme,shellapi;{$I w32.pas}
  //{$R MTeX.res}
  {$R tmac.res}

const
  CS=#12;fn='TMac';_ini=fn+'.ini';
  newline='^|';
  cursym='^^';
  c_symbol='**';
  c_template='~~';
  c_exec='>>';
  c_color='@@@COLOR@@@';c_color2='@@@COLOR2@@@';
  c_graphics='@@@GRAPHICS@@@';c_file='@@@FILE@@@';
  DefFilter=
'所有文件(*.*)|*.*|tex文件(*.tex)|*.tex;*.ctx;*.sty;*.ty;*.ltx|程序或脚本|*.c;*.cpp;*.dpr;*.pp;*.rc;*.asm;*.php;*.btm;*.cmd;*.asy;*.mp;*.tpx';
  usage=
'模板符号选择工具TMac v0.995  版权所有 2004--2008 mhb & qsh。欢迎广大LaTeX/TeX用户免费使用。'+CR+CR
+'作者保留对本软件的所有权利。如有问题或建议，可与我联系。'+CR+CR
+'基本用法：最新版本增加可定制的图标工具栏，鼠标在每个图标上停留后即可看到功能提示。'+CR
+'鼠标移向最左边最大的图标，可自动打开模板、符号选择窗口：从蓝色框中选择一个模板或命令，或从红色框中选择一个符号板从中选择一个符号，它将被自动送入剪贴板中；'
+'如果您在命令行上指定了编辑器，则您选择的模板或命令将自动送入相应编辑器中；按钮[>]可用于直接选择发送模板或符号命令的编辑器窗口。'+CR
+'点击工具栏第一行第一个小图标，您可以选择一个文件（比如tex文件）并用默认的编辑器打开。本工具可以记住您选择的文件，并根据您的配置文件把文件路径等参数传递给工具栏其它图标对应的程序。注意：右键可以选择以前打开的文件。'
+'点击工具栏第一行第二个图标将打开万能工具箱管家，它能根据您打开的文件类型打开相应的操作菜单，从而使您可以编译tex文件或源程序等等，这样通过TMac，您不需要对任何编辑器进行工具菜单的配置就可以随时随地使用MTeX来排版，哪怕使用最简单的windows记事本。'+CR
+'工具栏其它图标包括了MTeX的几个特色工具，以及tmac.ini中定义的其它工具。点击工具栏第一行最后一个图标可直接编辑tmac.ini，文件格式很简单，您只需比葫芦画瓢来手工添加您自己的模板、符号面板以及常用的工具程序！';

var TipVisible:Boolean;TT:HWND;ti: TOOLINFO;hint:string;
var
  App,W0,W,P1,M1,M2,BB1,BB2,BB3,BB4,BB5,BB6,CB3,BB7,BB8,BB9,BB10,BB11,CB0,CB1,CB2,CB4,C1,C2,C3,C4,L0,L1,L2,B1,B3,B2,B4,B5,B6,PB1,CKB1,PB0,TB1,TB2,B_Exit:PControl;
  WD:PControl;
  IL:PImageList;PM,PM0:PMenu;
  OpenDialog1,SaveDialog1,OpenDialog2: TOpenSaveDialog;
  ColorDialog1: TColorDialog;
  ini,ext,template,cmd,tex2ps,paths,editor,wname,bmpfile,s_ini,keys_paste,keys_newfile,DefEditor: string;
  cur_file,cur_dir:string;
  idx,nx,ny,m{,dx,dy}: integer;
  dx,dy:double;
  TemList,SymList,Symbols:TStrList;
  Image1:PBitmap;
  T1:PTimer;
//  TT:HWND;
oldidx:TPoint;
//sc:pcanvas;
var h:THandle;
var h_icons:array[0..100] of HICON;x_icons,y_icons:array[0..100] of integer;
	ExeList,HintList:TStrList;
    tool_icon_columns,tool_icon_rows,//[mhb] 07/03/09 
	tool_icon_size,tmac_icon_size,tool_idx,tool_icon_sep,clip_no:integer;
	apps_shift_ins,apps_alt_fn:string;
	mb:TMouseButton;
    ColorDlg:PColorDialog;

function GetSymIdx(P:tpoint):TPoint;forward;

//[mhb]:added to support non-standard editting keys
procedure SetEditKeys(wname:string);
var wn:string;s1,s2:string;
begin;
wn:=Trim(uppercase(wname));


s1:=uppercase(apps_shift_ins);
if pos(wn+' ',s1+' ')>0 then
	keys_paste:=Shift_Insert
else
	keys_paste:=Ctrl_V;

s2:=uppercase(apps_alt_fn);
if pos(wn+' ',s2+' ')>0 then
	keys_newfile:=A_+'FN'+_A
else
	keys_newfile:=Ctrl_N;

if wn='WINVI' then keys_newfile:=Chr(VK_F2);

end;


function Find_Window(title:string):THandle;
var
  hCurrentWindow: HWnd;
  szText: array[0..254] of char;
  i:integer;
begin
//LB1.clear;
hCurrentWindow := GetTopWindow(0);//showmessage('1 '+int2str(hCurrentWindow));
while hCurrentWindow <> 0 do
  begin;
  if GetWindowText(hCurrentWindow, @szText, 255) > 0 then
  begin;
    i:=pos(UpperCase(title),UpperCase(szText));
    if (i>=1) and (IsWindowVisible(hCurrentWindow ) or IsIconic(hCurrentWindow )) and
       ((GetWindowLong(hCurrentWindow, GWL_HWNDPARENT) = 0) or
       (GetWindowLong(hCurrentWindow, GWL_HWNDPARENT) = GetDesktopWindow)) and
       (GetWindowLong(hCurrentWindow , GWL_EXSTYLE) and WS_EX_TOOLWINDOW = 0){and not (szText[i-2]='*')} then
    begin;
      {LB1.add(int2str(hCurrentWindow)+' '+szText);}break;
    end;
  end;
  hCurrentWindow := GetNextWindow(hCurrentWindow, GW_HWNDNEXT);
  end;
Result:=hCurrentWindow;
end;

procedure SetFileEnvs(f:string);
begin;
  SetEnv('F',f);
  SetEnv('P',ExtractFilePath(f));
  SetEnv('N',ExtractFileNameWOext(f));
  SetEnv('E',ExtractFileExt(f));
  SetEnv('S',ExtractShortPathName(f));
end;
	
procedure ParseExecStr(s:string;var s_text,cmd,wintitle,newdir,icon,tmpfile,opts:string);
var f:string;
begin;
  f:=OpenDialog1.FileName;
	
  s_text:=s;
  s:=S_Before(CR,s_text);
	
  //s:=StrExpandEnv(s);//ShowMessage(s);

  cmd:=S_Before(',',s);
  wintitle:=S_Before(',',s);
  newdir:=S_Before(',',s);
  icon:=S_Before(',',s);
  tmpfile:=S_Before(',',s);
  opts:=s;
end;


procedure WinRun(s:string);
begin;//msgok(s+CR+OpenDialog1.FileName);
  WinExec(PChar(StrExpandEnv(s)),SW_SHOW);
end;

procedure Edit_File(editor:string);
begin;
  WinRun(editor+' '+OpenDialog1.FileName);
end;

procedure Menu0ItemHandler(Dummy:PControl; Sender: PMenu; Item: Integer);forward;
procedure Open_File(editor:string);
var f:string;i,j:integer;q:boolean;
begin;
  if mb=mbLeft then
	  q:=OpenDialog1.Execute
  else if mb=mbRight then
	  q:=true;
  if q then
	begin;
    f:=OpenDialog1.FileName;
    SetFileEnvs(f);
    W0.Caption:=fn+' ['+FileNameExt(f)+']';j:=-1;
    for i:=0 to PM0.Count-1 do
		if PM0.ItemText[i]=f then j:=i;
    if j<0 then PM0.AddItem(PChar(f),TOnMenuItem( MakeMethod( nil,@Menu0ItemHandler) ),[]);
	Edit_File(editor);
    end;
end;

procedure ReadIni;forward;
procedure Edit_Config(editor:string);
begin;
  WinRun(editor+' '+ini);
  msg_ok('编辑好配置文件后，请点击[确定]调入新的配置。');
  ReadIni;
end;
	
procedure MyExec(cmd,opts:string);
var ed:string;
begin;
  if Pos('#',cmd)<>1 then
	  begin;WinRun(cmd+opts);Exit;end;
  cmd:=UpperCase(cmd);
  ed:=DefEditor;
  if Pos('.',editor)>0 then ed:=editor
	  else if Length(editor)>0 then ed:='tex-dos.exe tex-edit.btm :'+editor;
  if cmd='#OPEN' then Open_File(ed)
  else if cmd='#HELP' then Msg_Ok(usage)
  else if cmd='#CONFIG' then Edit_Config(ed)	
  else if cmd='#CLOSE' then Halt(1)	
  else if cmd='#DOCS' then WinRun('tex-dos.exe doc.btm :?')
  else if cmd='#MAINMENU' then WinRun('tex-dos.exe main.btm')
  else if cmd='#TEX_DOS' then WinRun('tex-dos.exe')
  else if cmd='#TEX_BMP' then WinRun('tex-bmp.exe')	
  else if cmd='#TEX_EDIT' then Edit_File(ed)
  else if cmd='#UTILSMAN' then Edit_File('utilsman.exe')
  else if cmd='#BIBX' then WinRun('bibx.exe')	
  else if cmd='#NET_PKG' then WinRun('net_pkg.exe')	
  else if cmd='#OPENX' then Edit_File('tex-dos.exe openx.btm')
  else if cmd='#EDITX' then Edit_File('tex-dos.exe editx.btm')
  else if cmd='#MCONV' then Edit_File('tex-dos.exe m-conv.btm')
  else if cmd='#SPELL' then Edit_File('tex-dos.exe spell.btm')
  else if cmd='#COMPILE' then Edit_File('tex-dos.exe openx.btm -compile');

end;

procedure DoExec(s_text,cmd,wintitle,newdir,icon,tmpfile,opts:string);
var curdir:string;h:THandle;
begin;
  curdir:=GetWorkDir;h:=0;
  cmd:=StrExpandEnv(cmd);
  newdir:=StrExpandEnv(newdir);
  icon:=StrExpandEnv(icon);
  tmpfile:=StrExpandEnv(tmpfile);
  if (Length(tmpfile)=0) then Text2Clipboard(s_text) else StrSaveToFile(tmpfile,s_text);
  if (Length(newdir)>0) then ChDir(newdir);
  if Length(wintitle)>0 then h:=Find_W(wintitle);
  if h=0 then MyExec(cmd,opts) else ShowWindow(h,SW_SHOWNORMAL);
  Chdir(curdir);
  if (Length(tmpfile)>0) and FileExists(tmpfile) then DeleteFiles(tmpfile);
  //WD.Caption:='cmd='+cmd+'/w='+wintitle+'/d='+newdir+'/ico='+icon+'/tmp='+tmpfile+'/opt='+opts;
end;

function Arg0(s:string):string;
begin;
  if Pos('"',s)=1 then begin;Delete(s,1,1);Result:=S_Before('"',s);end
  else if Pos(' ',s)>0 then Result:=S_Before(' ',s)
  else Result:=s;
end;

function GetHIcon(icon,cmd:string;var newline:boolean):HIcon;
begin;
  newline:=false;
  if Pos(' ',cmd)=1 then begin;Delete(cmd,1,1);newline:=true;end;
  if Pos('#',cmd)=1 then Delete(cmd,1,1);
  if icon='' then icon:=Arg0(cmd);
  Result:=GetIcon(StrExpandEnv(icon));
  if Result=0 then Result:=LoadIcon(hInstance,PChar(icon));
end;

procedure Add_Icon(s,hint:string);
var  s_text,cmd,wintitle,newdir,icon,tmpfile,opts:string;i:integer;newline:boolean;
begin;
		ParseExecStr(s,s_text,cmd,wintitle,newdir,icon,tmpfile,opts);
		i:=ExeList.Count;h_icons[i]:=GetHIcon(icon,cmd,newline);
		if i=0 then begin;x_icons[i]:=0;y_icons[0]:=0;end
			else if newline then
				begin;
				x_icons[i]:=0;
				y_icons[i]:=y_icons[i-1]+tool_icon_size+tool_icon_sep;
				//TB1.Height:=max(TB1.Height,y_icons[i]+tool_icon_size+tool_icon_sep);
				end
			else
				begin;
				x_icons[i]:=x_icons[i-1]+tool_icon_size+tool_icon_sep;
				y_icons[i]:=y_icons[i-1];
				//TB1.Width:=max(TB1.Width,x_icons[i]+tool_icon_size+tool_icon_sep);
				end;
		if h_icons[i]<>0 then begin;ExeList.Add(s);HintList.Add(hint);Inc(i);end;
		//TB1.ResizeParent;
end;

function GetToolIconIdx(x,y:integer):integer;
var i:integer;
begin;
  for i:=0 to ExeList.Count-1 do
	  if (x>x_icons[i]) and (y>y_icons[i]) and (x<x_icons[i]+tool_icon_size) and (y<y_icons[i]+tool_icon_size) then
		  begin;Result:=i;Exit;end;
  Result:=-1;
end;

//[mhb] 07/05/09 
function Hint_of(cmd:string):string;
var s:string;
begin;
  s:=S_Before(CR,cmd);
  if s='#OPEN' then Result:='选择一个文件并用您设置的默认编辑器打开（右键从文件历史中选）'
  else if s='#EDIT' then Result:='编辑当前文件'
  else if s='#UTILSMAN' then Result:='工具箱管家：智能根据文件类型让您选择相应的操作！'
  else if s='#COMPILE' then Result:='用Openx智能编译：智能根据文件类型编译、预览、运行各种文件！'
  else if s='#MAINMENU' then Result:='MTeX主菜单：让您通过菜单选择MTeX的各种功能，适合所有用户！'
  else if s='#TEX_DOS' then Result:='TEX-DOS：强大的命令行窗口，直接输入命令，高手必备哦！'
  else if s='#TEX_BMP' then Result:='TEX-BMP：让您在所有应用程序（特别是PowerPoint）中使用强大的LaTeX数学排版！'	
  else if s='#BIBX' then Result:='BIBX：帮您提取网上数据库的文献信息，自动生成Bib文献条目！'		
  else if s='#SPELL' then Result:='Spell：通过MTeX提供的任何拼写检查软件来对文件进行拼写检查！'
  else if s='#NET_PKG' then Result:='Net_Pkg：让您在CTAN网上检索任何TeX资源、搜索和下载安装标准宏包！'
  else if s='#TEX_EDIT' then Result:='TEX集成环境：打开您设置的默认编辑器'
  else if s='#DOCS' then Result:='选择MTeX提供的各种本地与服务器文档'
  else if s='#HELP' then Result:='显示简单帮助'
  else if s='#CONFIG' then Result:='编辑配置文件'
  else if s='#CLOSE' then Result:='关闭TMac'
  else Result:=s;
end;
	  
procedure ReadIni;
var s,s_cfg,s_nam,s_sec,s_opt,s_sep,s_key,s_tmp:string;flag:char;i_tmp:integer;
begin;
  TemList.Clear;SymList.Clear;//OptList.Clear;
  CB1.Clear;CB2.Clear;CB0.Clear;
  ExeList.Clear;HintList.Clear;TB1.Width:=0;
	
  CB0.Add('隐藏符号板');SymList.Add('');
  s_ini:=StrLoadFromFile(ini);s:=s_ini+CR;
  s_cfg:=S_before(CR+'[',s)+CR;//msgOK(s_cfg);
  //OptList.Add(s_cfg);

  apps_shift_ins:=StrBetween(s_cfg,CR+'Apps_ShiftIns=',CR);
  if apps_shift_ins='' then apps_shift_ins:='GVim WinVi MeWin MicroEMACS';
  apps_alt_fn:=StrBetween(s_cfg,CR+'Apps_AltFN=',CR);
  if apps_alt_fn='' then apps_alt_fn:='GVim MeWin MicroEMACS';
  if Length(editor)=0 then editor:=StrBetween(s_cfg,CR+'Editor=',CR);
	
  s_tmp:=ExtractFileNameWOext(editor);
  if wname='' then wname:=StrBetween(s_cfg,CR+LowerCase(s_tmp),CR);
  if wname='' then wname:=s_tmp;
  wname:=Trim(wname);
  SetEditKeys(wname);

  s_tmp:=StrBetween(s_cfg,CR+'Toolbar_Pos_X=',CR);
  i_tmp:=Str2Int(s_tmp);
  if i_tmp>0 then W0.Left:=i_tmp 
    else if i_tmp<0 then W0.Left:=ScreenWidth+i_tmp;

  s_tmp:=StrBetween(s_cfg,CR+'Toolbar_Pos_Y=',CR);
  i_tmp:=Str2Int(s_tmp);
  if i_tmp>0 then W0.Top:=i_tmp 
    else if i_tmp<0 then W0.Top:=ScreenHeight+i_tmp;
    
  //[mhb] 07/03/09 
  s_tmp:=StrBetween(s_cfg,CR+'Tool_Icon_Columns=',CR);
  tool_icon_columns:=max(Str2Int(s_tmp),0);
  s_tmp:=StrBetween(s_cfg,CR+'Tool_Icon_Rows=',CR);
  tool_icon_rows:=max(Str2Int(s_tmp),0);
    
  s_tmp:=StrBetween(s_cfg,CR+'Tool_Icon_Sep=',CR);
  tool_icon_size:=max(Str2Int(s_tmp),16);
  s_tmp:=StrBetween(s_cfg,CR+'TMac_Icon_Size=',CR);
  tmac_icon_size:=max(Str2Int(s_tmp),16);//[mhb] 07/03/09 
  s_tmp:=StrBetween(s_cfg,CR+'Tool_Icon_Sep=',CR);
  tool_icon_sep:=max(Str2Int(s_tmp),0);
  s_tmp:=StrBetween(s_cfg,CR+'Tool_Icon_Alpha=',CR);
  if Length(s_tmp)>0 then W0.AlphaBlend:=Str2Int(s_tmp);

  W0.Width:=1;W0.Height:=1;//[mhb] 07/03/09 
  PB0.Width:=tmac_icon_size;PB0.Height:=tmac_icon_size;
  TB1.Left:=tmac_icon_size+1+tool_icon_sep;
  TB1.Width:=tool_icon_columns*(tool_icon_size+tool_icon_sep);//[mhb] 07/03/09 
  TB1.Height:=tool_icon_rows*(tool_icon_size);//[mhb] 07/03/09 

  //TB1.ResizeParent;
  //[mhb] 07/03/09 
  W0.Width:=TB1.Left+TB1.Width;
  W0.Height:=max(TB1.Height,PB0.Height);
  //TB1.ResizeParent;

  s_key:='';
  repeat
	s_opt:=S_before(CR,s);//msgOK(s_opt);
        s_nam:=S_before(']',s_opt);//msgOK(s_nam);
	if Length(s_opt)=0 then flag:=' ' else begin;flag:=s_opt[1];Delete(s_opt,1,1);end;
	if flag='<' then s_sep:=s_opt else s_sep:='';
	if (s_sep<>'') or (s[1]<>'[') then s_sep:=s_sep+CR;//[mhb]
	s_sec:=S_before(s_sep+'[',s);//[mhb]:delete +CR
	if (flag='+') then
	  begin;//msgOK(s_opt);
	  s_opt:=Trim(s_opt);s_opt:=StrExpandEnv(s_opt);
	  if FileExists(s_opt) then s_sec:=StrLoadFromFile(s_opt) else begin;ShowMsg('未发现文件'+s_opt+'!',MB_OK);{s_sec:='';}end;
	  end;

	if Pos(c_symbol,s_nam)=1 then
		begin;Delete(s_nam,1,Length(c_symbol));CB0.Add(s_nam);SymList.Add(s_sec);end
	else if Pos(c_exec,s_nam)=1 then
		begin;
		if Pos('#',s_sec)=1 then s_nam:=Hint_Of(s_sec);
		Add_Icon(s_sec,s_nam);
		end
	else //if s<>'' then
	  begin;
	  CB1.Add(s_nam);TemList.Add(s_sec);
	  s_tmp:=S_Before('|',s_nam);
	  if s_tmp<>s_key then begin;CB2.Add(s_tmp);s_key:=s_tmp;end;
	  end;
  until s='';
  if (s='') then TemList.Add(S_before(s_sep+CR,s_sec));

end;


procedure B_MouseMove(dummy:Pointer;Sender: PControl;var Mouse: TMouseEventData);
var  P:TPoint;i,dy:integer;
begin
  dy:=20;
  if Sender=TB1 then
	begin;
	GetCursorPos(P);P:=TB1.Screen2Client(P);
    i:=GetToolIconIdx(P.x,P.y);
    if i>=HintList.Count then i:=HintList.Count-1;
	hint:=HintList.Items[i];
	dy:=40;
    end
  //else if Sender=B3 then hint:='编辑配置文件'
  //else if Sender=B4 then begin;hint:='显示简单帮助';end
  else if Sender=B5 then begin;hint:='选择编辑器窗口';end
  else if Sender=B6 then begin;hint:='发送当前模板内容到剪贴板或指定的编辑器';end
  else if Sender=B_Exit then begin;hint:='关闭TMac!';end //[mhb] 07/04/09 
	else begin
		exit;
	end;
  TipVisible := True;
	if TipVisible then
  begin
	  GetCursorPos(P);
    SendMessage(TT,TTM_TRACKPOSITION,0, MAKELPARAM(P.x,p.y+dy));
		SendMessage(TT,TTM_TRACKACTIVATE,Integer(LongBool(True)),Integer(@ti));
  end;
end;

procedure CreateTipsWindow;
var
  iccex: tagINITCOMMONCONTROLSEX;
begin
  // Load the ToolTip class from the DLL.
  iccex.dwSize := SizeOf(tagINITCOMMONCONTROLSEX);
  iccex.dwICC := ICC_BAR_CLASSES;
  InitCommonControlsEx(iccex);
  // Create the ToolTip control.
  TT := CreateWindowEx(WS_EX_TOPMOST,TOOLTIPS_CLASS, nil,
      WS_POPUP or TTS_NOPREFIX or TTS_ALWAYSTIP,
      CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT,
      W.handle, 0, hInstance, nil );
  //SetWindowPos(TT, HWND_TOPMOST, 0, 0, 0, 0,SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE);
  // Prepare TOOLINFO structure for use as tracking ToolTip.
  ti.cbSize := SizeOf(ti);
  ti.uFlags := TTF_IDISHWND or TTF_TRACK or TTF_ABSOLUTE or TTF_TRANSPARENT;
  ti.hwnd := W.Handle;
  ti.uId := W.Handle;
  ti.hinst := hInstance;
  ti.lpszText := LPSTR_TEXTCALLBACK;
  ti.Rect.Left := 0;
  ti.Rect.Top := 0;
  ti.Rect.Bottom := 0;
  ti.Rect.Right := 0;

//  SendMessage(TT, WM_SETFONT, W.Font.Handle, Integer(LongBool(False)));
  SendMessage(TT,TTM_ADDTOOL,0,Integer(@ti));
end;

procedure HideTipsWindow;
begin
  if TipVisible then
  begin
    SendMessage(TT,TTM_TRACKACTIVATE,Integer(LongBool(False)), 0);
    TipVisible := False;
  end;
end;



function FormMessage(Dummy_Self: PObj; var Msg: TMsg; var Rslt: Integer ): Boolean;
var
  phd: PHDNotify;
  NMTTDISPINFO: PNMTTDispInfo;
begin
  Result := FALSE;
	if Msg.message=WM_NOTIFY then
	begin
		phd := PHDNotify(Msg.lParam);
		if phd.Hdr.hwndFrom = TT then
		begin
			if phd.Hdr.Code = TTN_NEEDTEXT then
			begin
				NMTTDISPINFO := PNMTTDispInfo(phd);
				NMTTDISPINFO.lpszText := PChar(hint);
				Result := TRUE;
			end;
		end;
	end;
end;

procedure B4Click(Dummy:Pointer; Sender: PControl);
begin
HideTipsWindow;
ShowMessage(usage);
end;

function DelS(s:string;c1,c2:char):string;
var x:string;i1,i2:integer;
begin;
i1:=Pos(c1,s);i2:=Pos(c2,s);
if i2>i1 then Delete(s,i1,i2-i1+1);
Result:=s;
end;

procedure MenuItemHandler(Dummy:PControl; Sender: PMenu; Item: Integer);
var i:integer;s,s1:string;
begin;
s:=Sender.ItemText[Item];
s:=DelS(s,'[',']');
s:=DelS(s,'<','>');
s:=DelS(s,'(',')');
s1:=S_Before(' - ',s);
s:=Trim(s);
if (s='') or (Pos('.',s)>0) then s:=s1;
s:=Trim(s);
wname:=s;
if Pos(' ',s)>0 then wname:=S_Before(' ',s);
SetEditKeys(wname);
if keys_paste=Ctrl_V then
	s:='Ctrl+V'
else
	s:='Shift+Ins';
if keys_newfile=Ctrl_N then
	s1:='Ctrl+N'
else if keys_newfile=chr(VK_F2) then
	s1:='F2'
else
	s1:='Alt+FN';
msg_ok('注意：您选择的编辑器是'+wname+' 对应粘贴热键为'+s+' 新文件热键为'+s1+CR
+'如果您需要修改粘贴热键为Shift+Insert或新文件热键为Alt+FN，请把编辑器名字加入配置设置Apps_ShiftIns或Apps_AltFN中。'
);
W.SimpleStatusText:=PChar(wname+'--'+'Paste:'+s+'   NewFile:'+s1);
end;

Function EnumWindowsProc (Wnd: HWND; LParam: LPARAM): BOOL; stdcall;
begin
Result := True;//h:=0;
if (IsWindowVisible(Wnd) and not IsIconic(wnd)) and
((GetWindowLong(Wnd, GWL_HWNDPARENT) = 0) or
(GetWindowLong(Wnd, GWL_HWNDPARENT) = GetDesktopWindow)) and
(GetWindowLong(Wnd, GWL_EXSTYLE) and WS_EX_TOOLWINDOW = 0) and
((GetWindowThreadProcessId(Wnd,nil)<>GetCurrentThreadId)) then
PM.AddItem(PChar(GetText(Wnd)),TOnMenuItem( MakeMethod( nil,@MenuItemHandler) ),[]);
end;

procedure B5Click(Dummy:Pointer; Sender: PControl);
var p:TPoint;i:integer;Param : Longint;
begin;
HideTipsWindow;
EnumWindows(@EnumWindowsProc , Param);
p.x:=0;p.y:=0;
p:=B5.Client2Screen(p);
PM.Popup(p.x,p.y);
for i:=0 to PM.Count-1 do PM.RemoveSubMenu(i);
end;

procedure C1Click(Dummy:Pointer; Sender: PControl);
begin
W.StayOnTop:=C1.Checked;
end;

procedure B1Click(Dummy:Pointer; Sender: PControl);
var
Param : Longint;
begin
CB4.Clear;CB4.Add('');
EnumWindows(@EnumWindowsProc , Param);
end;


procedure hidepaintbox;
begin
PB1.Visible:=false;W.clientheight:=B5.height+2;W.clientwidth:=B5.left+B5.width+2;B5.ResizeParent;
end;


procedure CB0Change(Dummy:Pointer; Sender: PControl);
const DefWidth=800;
var sym,keys,s,sym_hint:string;h:THandle;
begin

if CB0.CurIndex=0 then
  begin;hidepaintbox;Exit;end;

sym:=SymList.Items[CB0.CurIndex];//msgOK(sym);
Symbols.Text:=sym;
sym_hint:=Symbols.Items[0];
W.SimpleStatusText:=PChar(wname+'--'+sym_hint);
s:=S_Before('#',sym_hint);
bmpfile:=S_Before(',',s);
Image1.LoadFromFile(bmpfile);
if Image1.Width<=DefWidth then m:=1 else m:=Image1.Width div DefWidth+1;
if m=1 then PB1.Width:=Image1.Width else PB1.Width:=DefWidth{ div dx * dx};
if PB1.Visible then W.Height:=W.Height-PB1.Height;
PB1.Height:=m*Image1.Height;
W.Width:=PB1.Width;
B_Exit.ResizeParent;//[mhb] 07/04/09 changed: B5.ResizeParent;
dx:=16;dy:=16;//nx:=Image1.Width div dx;ny:=Image1.Height div dy;
nx:=round(Image1.Width / dx -0.4);ny:=round(Image1.Height / dy-0.4);
if Pos('x',s)>0 then begin;//nx:=Image1.Width div 16;ny:=1;dx:=16;dy:=16;end
	dx:=Str2Int(S_Before('x',s));dy:=Str2Int(s);
  if (dx<1)or(dy<1) then begin;hidepaintbox;showmessage('请在配置文件中正确设置 '+CB0.text+' 每个符号的大小！');CB0.CurIndex:=0;exit;end;
  nx:=round(pb1.Width / dx-0.5);ny:=round(pb1.Height / dy-0.5);
//  nx:=Image1.Width div dx;ny:=Image1.Height div dy;
	end
else begin;
	nx:=Str2Int(S_Before(',',s));ny:=Str2Int(s);
  if (nx<1)or(ny<1) then begin;hidepaintbox;showmessage('请在配置文件中正确设置 '+CB0.text+' 符号个数！');CB0.CurIndex:=0;exit;end;
  dx:=pb1.Width / nx;dy:=pb1.Height / ny;
//  dx:=Image1.Width div nx;dy:=Image1.Height div ny;
  end;
PB1.Visible:=true;
PB1.ResizeParent;
W.Left:=Min(W.Left,ScreenWidth-W.Width-10);//[mhb] 01/30/09
W.Top:=Min(W.Top,ScreenHeight-W.Height-10);//[mhb] 01/30/09  
end;


function GetKeys(var s:string):string;
var i,n,m:integer;
begin;
Result:=keys_paste;
s:=StrReplaceAll(s,newline,CR);
n:=Length(s);
i:=Pos(cursym,s);if i=0 then exit;
Delete(s,i,2);m:=n-i-1;
repeat
	if (s[i]=#13) and (s[i+1]=#10) then Dec(m);
	Inc(i);
until i>=n;
Result:=Result+StrRepeat(Chr(VK_LEFT),m);
end;



procedure CB1Change(Dummy:Pointer; Sender: PControl);
var keys,s,s_text,cmd,wintitle,newdir,icon,tmpfile,opts:string;
  h:THandle;i,n,m:integer;
begin
s:=TemList.Items[CB1.CurIndex];
if Pos(c_exec,CB1.Text)=1 then
  begin;
  ParseExecStr(s,s_text,cmd,wintitle,newdir,icon,tmpfile,opts);
  DoExec(s_text,cmd,wintitle,newdir,icon,tmpfile,opts);
  Exit;
  end;
keys:=GetKeys(s);
h:=Find_W(wname);
if Pos(c_template,CB1.Text)=1 then
	begin;
	SendStrTo(keys_newfile,h);
	sleep(50);
	end;
Text2Clipboard(s);
h:=Find_W(wname);
if h=0 then Exit;
SendStrTo(keys,h);
end;

procedure B6Click(Dummy:Pointer; Sender: PControl);
begin

CB1Change(nil,Sender);

end;

//[mhb] 07/04/09 
procedure B_Exit_Click(Dummy:Pointer; Sender: PControl);
begin
Halt(1);
end;

procedure CB2Change(Dummy:Pointer; Sender: PControl);
begin
CB1.CurIndex:=CB1.SearchFor(CB2.Items[CB2.CurIndex],0,true);
if CB2.Items[CB2.CurIndex]=CB1.Items[CB1.CurIndex] then CB1Change(nil,nil) else CB1.Perform(CB_SHOWDROPDOWN,1,0);
end;

procedure PB1Paint(dummy:pointer;sender:pcontrol;DC:HDC);
var i:integer;
begin;//PB1.Clear;
for i:=0 to m-1 do Image1.Draw(DC,-i*PB1.Width,Image1.Height*i);
end;

function GetSymIdx(P:tpoint):TPoint;
var P2:tpoint;
begin;
//  Result:=(x+y div Image1.Height*PB1.Width) div dx
//  +(y mod Image1.Height) div dy * nx+1;
p2.x:=round(p.y/dy-0.5)+1;
p2.y:=round(p.x/dx-0.5)+1;
result:=p2;
//result:=round(y / dy-0.5)+1*nx + round(x/dx-0.5)+1;
//w.caption:='('+int2str(x)+','+int2str(y)+')'+' row:'+int2str(round(y / dy-0.5)+1)+' | column:'+int2str(round(x/dx-0.5)+1)+' | columns:'+int2str(nx);
end;

function GetSymbolFromCursor:string;
var P,idx:TPoint;//idx:integer;
begin
result:='';
if PB1.visible then begin
    GetCursorPos(P);P:=PB1.Screen2Client(P);
		idx:=GetSymIdx(P);
    result:=Symbols.Items[(idx.x-1)*nx+idx.y];
//    idx:=GetSymIdx(P2.X,P2.Y);
//    result:=Symbols.Items[idx];
end;
end;

function Color2Str(c:TColor):string;
var s:string;
begin;
  s:=Int2Hex(c,6);
  Result:=Copy(s,5,2)+Copy(s,3,2)+Copy(s,1,2);
end;

function Color2Str2(c:TColor):string;
var s:string;r,g,b:integer;
begin;
  r:=c mod $100;
  g:=(c div $100) mod $100;
  b:=c div $10000;
  Result:=Format('0.%03d,.%03d,.%03d',[r*1000 div 256,g*1000 div 256,b*1000 div 256]);
end;

function RelPath(f,dir:string):string;
begin;
  Result:=StrReplaceAll(f,dir,'./');
  Result:=StrReplaceAll(Result,'\','/');
end;

procedure PB1MouseDown( Dummy:Pointer; Sender: PControl; var Mouse: TMouseEventData );
var P,P2:TPoint;idx,ix,iy:integer;keys,s,f:string;h,hDib:THandle;Bmp:PBitmap;
begin;

  s:=GetSymbolFromCursor;
  keys:=GetKeys(s);//w.caption:=keys;
  OpenDialog2.InitialDir:=GetWorkDir;
  if (Pos(c_color,s)>0) or (Pos(c_color2,s)>0) then
    if ColorDlg.Execute then
		begin;
		s:=StrReplaceAll(s,c_color,Color2Str(ColorDlg.Color));
		s:=StrReplaceAll(s,c_color2,Color2Str2(ColorDlg.Color));
		end;
  if (Pos(c_file,s)>0) then
    if OpenDialog2.Execute then
		begin;
		f:=RelPath(OpenDialog2.FileName,GetWorkDir);
		s:=StrReplaceAll(s,c_file,f);
		end;	  
  if (Pos(c_graphics,s)>0) then
	begin;
    OpenClipboard(0);
    hDib:=GetClipboardData(CF_DIB);
    CloseClipboard;
    if hDib<>0 then 
		begin;
		clip_no:=clip_no+1;
		Bmp:=NewBitmap(0,0);
		Bmp.PasteFromClipboard;
		f:='_clip_'+Int2Str(clip_no)+'.bmp';
		Bmp.SaveToFile(f);
		Bmp.Free;
		msg_ok('剪贴板里有个图片，已经自动把它存为'+GetWorkDir+f+' !');
		end;
    if OpenDialog2.Execute then
		begin;f:=RelPath(OpenDialog2.FileName,GetWorkDir);
		s:=StrReplaceAll(s,c_file,f);
		s:=StrReplaceAll(s,c_graphics,f);
		end;
	end;
	

  Text2Clipboard(s);//Dbg('{%d}-- %s',[idx,s]);
  h:=Find_W(wname);
  SendStrTo(keys,h);

end;

procedure PB_MouseMove(dummy:Pointer;Sender: PControl;var Mouse: TMouseEventData);
var //P:TPoint;
  dc : hDc;
  Pen : hPen;
  OldPen : hPen;
  OldBrush : hBrush;
  p,idx:tpoint;
	Rect,rc: TRect;
	sc:pcanvas;
begin
    hint:=GetSymbolFromCursor;
    getkeys(hint);
		TipVisible := True;
		if TipVisible then
		begin
			GetCursorPos(P);
			SendMessage(TT,TTM_TRACKPOSITION,0, MAKELPARAM(P.x,p.y+20));
			SendMessage(TT,TTM_TRACKACTIVATE,Integer(LongBool(True)),Integer(@ti));
		end;
end;

		
procedure B_MouseLeave(Dummy_Self: PObj; Sender: PControl;var Mouse: TMouseEventData);
var  R: Trect;s:string;P:TPoint;ti: TTOOLINFO ;
begin
  HideTipsWindow;
  GetCursorPos( P );
  P := W.Screen2Client( P );
  if Sender=W0 then Exit;
  if Sender=TB1 then Exit;
  //s:=Format('W:x=%d,y=%d,w=%d,h=%d',[P.x,P.y,W.ClientWidth,W.ClientHeight]);
  //WD.Caption:=s;
  if (P.x>0) and (P.x<W.ClientWidth) and (P.y>W.ClientHeight-W.Height) and (P.y<W.ClientHeight) then Exit;
  W.Visible:=false;
  W0.Visible:=true;
  //W0.left:=W.left;W0.top:=W.top+10;
end;


		
procedure PB0_Enter(Dummy:Pointer; Sender: PControl);
var P: TPoint;s:string;i:integer;
begin;
  GetCursorPos( P );
  P := Sender.Screen2Client( P );
  W0.Visible:=false;W.Visible:=true;
  W.left:=Min(W0.left,ScreenWidth-W.Width-10);//[mhb] 01/30/09
  W.top:=Min(W0.top-10,ScreenHeight-W.Height-10);//[mhb] 01/30/09
  //W0.Left:=W.Left;W0.Top:=W.Top;
  W.StayOnTop:=true;
end;
	

procedure PB0_paint(dummy:pointer;sender:pcontrol;DC:HDC);
var r:TRect;h:HICON;ico:TICON;
begin
  h:=LoadIcon(hInstance,'TMAC');//DrawIcon(DC,0,0,h);
  DrawIconEx(DC,0,0,h,tmac_icon_size,tmac_icon_size,0,0,DI_IMAGE);
end;

procedure TB1_paint(dummy:pointer;sender:pcontrol;DC:HDC);
var r:TRect;h:HICON;ico:TICON;i:integer;br:HBRUSH;
begin
  //br:=CreateHatchBrush(HS_DIAGCROSS,clGray);
  br:=CreateSolidBrush(clGray);
  FillRect(DC,TB1.BoundsRect,br);
  for i:=0 to ExeList.Count-1 do //DrawIcon(DC,i*tool_icon_size,0,h_icons[i]);
	  DrawIconEx(DC,x_icons[i],y_icons[i],h_icons[i],tool_icon_size,tool_icon_size,0,0,DI_IMAGE);
end;

procedure ToolIcon_Click;
var s,s_text,cmd,wintitle,newdir,icon,tmpfile,opts:string;P,P2:TPoint;
begin;
  HideTipsWindow;
  GetCursorPos( P );
  if mb=mbRight then PM0.Popup(p.x,p.y);
  P :=TB1.Screen2Client( P );
  tool_idx:=GetToolIconIdx(P.x,P.y);
  if tool_idx>=0 then
	begin;
	s:=ExeList.Items[tool_idx];
    ParseExecStr(s,s_text,cmd,wintitle,newdir,icon,tmpfile,opts);
    DoExec(s_text,cmd,wintitle,newdir,icon,tmpfile,opts);
	end;
end;


procedure TB1_Click(Dummy:Pointer; Sender: PControl);
begin;
  mb:=mbLeft;ToolIcon_Click;
end;

procedure Menu0ItemHandler(Dummy:PControl; Sender: PMenu; Item: Integer);
var f:string;
begin;
  mb:=mbRight;
  f:=PM0.ItemText[Item];
  OpenDialog1.FileName:=f;
  W0.Caption:=fn+'['+FileNameExt(f)+']';
end;

procedure TB1_MouseDown( Dummy:Pointer; Sender:PControl; var Mouse: TMouseEventData );
begin;
  if Mouse.Button<>mbRight then Exit;
  mb:=mbRight;ToolIcon_Click;
end;


procedure T1_Timer(Dummy:Pointer; Sender: PControl);
begin;
		
end;


procedure LoadMtexEnv;
var f,mtex:string;
begin;
  f:=GetStartDir+'..\mtex.env';
  mtex:=SFN(FilePath(FilePath(GetStartDir)));
  SetEnv('MTEX',mtex);
  LoadEnvFromFile(f);
end;

procedure InitObjs;var i:integer;etc:string;
const TTDT_AUTOMATIC=0; TTDT_RESHOW=1; TTDT_AUTOPOP=2; TTDT_INITIAL=3;
begin;
  etc:=GetEnv('ETC')+'\';
  if (Length(etc)=1) or not (FileExists(etc+_ini)) then etc:=GetStartDir;
  ini:=etc+_ini;clip_no:=0;
  App:=NewApplet(fn); App.IconLoad(hInstance,'TMac');
  W0:= NewForm( App, fn ).SetSize(16,16);//[mhb] 07/03/09 
  W0.IconLoad(hInstance,'TMac');
  W0.Left:=ScreenWidth div 10*5;
  W0.Top:=ScreenHeight div 12;
  //W0.Style:=W0.Style and not (WS_MAXIMIZEBOX {or WS_SIZEBOX});
  //W0.Style:=WS_DLGFRAME;
  W0.StayOnTop:=true;W0.AlphaBlend:=180;
  W0.Style:=WS_POPUP or WS_CLIPSIBLINGS {or WS_border};
  W0.ExStyle := WS_EX_TOOLWINDOW or WS_EX_TOPMOST;
  PB0:=NewPaintbox(W0).SetSize(tmac_icon_size,tmac_icon_size);
  TB1:=NewPaintbox(W0).PlaceRight.SetSize(0,tool_icon_size);
  //TB1.Width:=0;
  PM0:=NewMenu( TB1, 100, [], TOnMenuItem( MakeMethod( nil,@Menu0ItemHandler) ) );


  W := NewForm( App, '请选择模板或符号 [mhb&qhs]' );W.Icon:=App.Icon;//Load(0,'TeX_bmp');
  W.Style:=W.Style and not (WS_MAXIMIZEBOX or WS_SIZEBOX or WS_SYSMENU);
  //W.ExStyle:= WS_EX_TOOLWINDOW;
  //W.Style:=WS_DLGFRAME;
 // W.Style:=WS_POPUP or WS_CLIPSIBLINGS {or WS_border};
  //W.ExStyle := WS_EX_TOOLWINDOW or WS_EX_TOPMOST;
  W.AlphaBlend:=255;W.StayOnTop:=true;W.Visible:=false;

  //WD:=NewForm(App,'Debug').SetSize(1000,20);WD.StayOnTop:=true;
  if not JustOne(W0,fn) then Halt(0);

  SetFont(W.Font,'宋体,12');//[mathmhb]
  CB0:=NewCombobox(W,[coReadOnly]).PlaceDown.SetSize(85,0).ResizeParent;
  CB0.Font.Color:=clRed;CB0.color:=clwindow;
//	Cb0.Perform(CB_SetDroppedWidth,100,0);
  CB1:=NewCombobox(W,[coReadOnly]).PlaceRight.SetSize(210,0).ResizeParent;
  CB1.Font.Color:=clBlue;CB1.color:=clwindow;
  CB2:=NewCombobox(W,[coReadOnly]).PlaceRight.SetSize(80,0).ResizeParent;
  CB2.Font.Color:=clBlue;CB2.DroppedWidth:=100;
  CB0.DropDownCount:=40;CB1.DropDownCount:=45;CB2.DropDownCount:=40;

//  B1:=NewButton(W,'+').PlaceRight.SetSize(20,0).ResizeParent;
//  B2:=NewButton(W,'-').PlaceRight.SetSize(20,0).ResizeParent;
  B6:=NewButton(W,'发送').PlaceRight.SetSize(35,0).ResizeParent;
  //B3:=NewButton(W,'*').PlaceRight.SetSize(20,0).ResizeParent;
  //B4:=NewButton(W,'?').PlaceRight.SetSize(20,0).ResizeParent;
  B5:=NewButton(W,'>').PlaceRight.SetSize(20,0).ResizeParent;
  B_Exit:=NewButton(W,'X').PlaceRight.SetSize(20,0).ResizeParent;//[mhb] 07/04/09 
  //L0:=NewLabel(W,'').PlaceRight.SetSize(40,0);
  Image1:=NewBitmap(0,0);
  PB1:=NewPaintbox(W).PlaceDown;PB1.Transparent:=true;PB1.Visible:=false;
	CreateTipsWindow; TipVisible := False;
	W.Onmessage := TOnMessage( MakeMethod(nil, @FormMessage));
  PM:=NewMenu( B5, 100, [], TOnMenuItem( MakeMethod( nil,@MenuItemHandler) ) );
  //btns.LoadFromFile('h:\mtex-prog\buttons.bmp');
  //TB2:=NewToolbar(W0,caLeft,[],btns.Handle,['aaa','bbb','ccc'],[0]).PlaceUnder.ResizeParent;
  //W0.Height:=W0.Height+40;

  ColorDlg:=NewColorDialog(ccoFullOpen);
  OpenDialog1.Title:='请选择要打开的文件：';
  OpenDialog1.Filter:=DefFilter;
  OpenDialog2.Title:=OpenDialog1.Title;
  //\includegraphics[width=0.6\textwidth]{@@@GRAPHICS@@@}OpenDialog2.Filter:=DefFilter;
  
  DefEditor:=GetStartDir+'mini_pad.exe';
  if not FileExists(DefEditor) then DefEditor:='notepad.exe';
  editor:=ParamStr(1);wname:=ParamStr(2);

  Chdir(GetStartDir);
//  M1:=NewEditbox(W,[eoMultiline]).PlaceUnder.SetSize(450,200);
//  M2:=NewEditbox(W,[eoMultiline]).PlaceUnder.SetSize(450,70).ResizeParent;
//  M2.Visible:=false;

  //T1:=NewTimer(10000);T1.OnTimer := TOnEvent( MakeMethod( nil, @T1_Timer ) ); T1.enabled := false;

end;

procedure SetEvents;
begin;
  //B1.OnClick := TOnEvent( MakeMethod( nil, @CB1Change ) );
  CB0.OnChange := TOnEvent( MakeMethod( nil, @CB0Change ) );
  CB1.OnChange := TOnEvent( MakeMethod( nil, @CB1Change ) );
  CB2.OnChange := TOnEvent( MakeMethod( nil, @CB2Change ) );
  //B3.OnClick := TOnEvent( MakeMethod( nil, @B3Click ) );
  //B4.OnClick := TOnEvent( MakeMethod( nil, @B4Click ) );
  B5.OnClick := TOnEvent( MakeMethod( nil, @B5Click ) );
  B6.OnClick := TOnEvent( MakeMethod( nil, @B6Click ) );
  B_Exit.OnClick := TOnEvent( MakeMethod( nil, @B_Exit_Click ) );//[mhb] 07/04/09 
  //B3.OnMouseMove:=TOnMouse( MakeMethod( nil, @B_MouseMove ) );
  //B4.OnMouseMove:=TOnMouse( MakeMethod( nil, @B_MouseMove ) );
  B5.OnMouseMove:=TOnMouse( MakeMethod( nil, @B_MouseMove ) );
  B6.OnMouseMove:=TOnMouse( MakeMethod( nil, @B_MouseMove ) );
  B_Exit.OnMouseMove:=TOnMouse( MakeMethod( nil, @B_MouseMove ) );//[mhb] 07/04/09 
  PB1.OnMouseMove:=TOnMouse( MakeMethod( nil, @PB_MouseMove ) );
  //B3.OnMouseLeave:=TOnEvent( MakeMethod( nil, @B_MouseLeave ) );
  //B4.OnMouseLeave:=TOnEvent( MakeMethod( nil, @B_MouseLeave ) );
  B5.OnMouseLeave:=TOnEvent( MakeMethod( nil, @B_MouseLeave ) );
  B6.OnMouseLeave:=TOnEvent( MakeMethod( nil, @B_MouseLeave ) );
  PB1.OnMouseLeave:=TOnEvent( MakeMethod( nil, @B_MouseLeave ) );
  PB1.OnMouseDown:=TOnMouse( MakeMethod( nil, @PB1MouseDown ) );
  PB1.OnPaint:=TOnPaint( MakeMethod( nil, @PB1Paint ) );
  TB1.OnPaint := TOnPaint(MakeMethod(nil,@TB1_Paint));
  TB1.OnClick := TOnEvent(MakeMethod(nil,@TB1_Click));
  TB1.OnMouseDown := TOnMouse(MakeMethod(nil,@TB1_MouseDown));
  TB1.OnMouseMove:=TOnMouse( MakeMethod( nil, @B_MouseMove ) );
  TB1.OnMouseLeave:=TOnEvent( MakeMethod( nil, @B_MouseLeave ) );
	
  PB0.OnPaint := TOnPaint(MakeMethod(nil,@PB0_Paint));
  PB0.OnMouseEnter := TOnEvent( MakeMethod( nil, @PB0_Enter ) );
  W.OnMouseLeave := TOnEvent( MakeMethod( nil, @B_MouseLeave ) );

end;


begin;
  LoadMtexEnv;
  InitObjs;
  ReadIni;
  SetEvents;
  SetFormOnTop(W,true);
  CB0.CurIndex:=1;CB0Change(nil,nil);
  Run(App);
end.
