{
v0.98: 使用系统默认字体
v0.97: 使用新版cct来支持中文；加状态栏；默认模板和命令作为资源；数学符号激活TMac
v0.95: 支持通过语言文件修改字体大小及属性
v0.90:多语言界面，可通过语言文件修改界面语言；ini文件格式改变，不使用中文
v0.85:XP风格美化；可从环境变量ETC指定的目录读配置文件；加入dvipng支持??
v0.80:修正刚启动程序时的公式显示区域的不正常显示；增加调试显示的内容。
v0.75:修正了颜色功能；临时文件改为临时目录里生成。
}
{$D SMALLEST_CODE} //{$R MTeX.res}
program tex_bmp;
{$R tex-bmp.res}
uses
  windows,messages,kol,xptheme,CommCtrl,shellapi;

{$I w32.pas}

resourcestring
  DefTex2ps='@echo off'+CR  
    +'if exist %1.ctx        cct %1.ctx'+CR
    +'if exist %1.ty         tyc -d%_Res%  %1.ty'+CR
    +'call %_Cmd% %1'+CR
    +'if not exist %1.dvi    goto END'+CR
    +'if exist %1.ty         pkttf -d%_Res%'+CR
    +'if not exist %1.ctx    goto next'+CR
    +'copy %1.dvi ~tmp.dvi'+CR
    +'patchdvi ~tmp.dvi %1.dvi -r%_Res% -y'+CR
    +'rem or: cdvia  ~tmp.dvi %1.dvi -P %PKDIR% -r %_Res%'+CR
    +'del ~tmp.dvi'+CR
    +':next'+CR
    +'call makepk %1.dvi -r%_Res%'+CR
    +'if %_Bmp%==bmpmono       call dvi2bmp %1 %1.bmp /r%_Res%'+CR
    +'if not exist %1.bmp      call dvips -D %_Res% -E %1'+CR
    +':END';
	
  DefTemplate=
    '\documentclass{article}\pagestyle{empty}'+CR
    +'\usepackage{latexsym,amssymb,amsmath,amsbsy,amsopn,amstext,color}'+CR
	+'\b'+'egin{document}'+CR+CR
	+'\e'+'nd{document}'+CR;

const
  CS=#12;fn='_tex_bmp';fn_ini='tex-bmp.ini';
  f_tmp='_tex_tmp.bat';latexmac='tmac.exe';  
  ctex='\ctex\texmf\miktex\bin';emtex='\emtex';
  DefPaths=ctex+';'+emtex;


var 
  App,W,P1,M1,M2,B_1,B_2,B_3,B_4,B_5,B_6,CB3,B_7,B_8,B_9,B_10,B_11,CB1,CB2,CB4,C1,C2,C3,C4,L0,L1,L2,B1,B3,B2,B4,PB:PControl;
  OpenDialog1,SaveDialog1,OpenDialog2: TOpenSaveDialog;
  ColorDialog1: TColorDialog;
  exepath,tmp,comspec,ext,template,cmd,tex2ps,paths,editor,f_ini: string;
  idx: integer;
  TeXList,codes:TStrList;
  Image1,Image2:PBitmap;
  Ini:PIniFile;
  TT:HWND;ti: TOOLINFO;hint:string;TipVisible:boolean;


procedure ReadIni;
var s_ini,s_nam,s_sec,s_key,s_val:string;
begin;
  s_ini:=StrLoadFromFile(f_ini);ParseIniHead(s_ini);
  repeat 
    ParseIniSec(s_ini,s_nam,s_sec);//msgok(s_nam);msgok(s_sec);
	if s_nam='tex2ps' then tex2ps:=s_sec
	else if s_nam='Template' then template:=s_sec
	else if s_nam='Settings' then
		repeat 
			ParseIniStr(s_sec,s_key,s_val);
			if s_key='Comspec' then comspec:=s_val
			else if s_key='Res' then CB2.Text:=s_val
			else if s_key='Format' then CB3.Text:=s_val
			else if s_key='Paths' then paths:=s_val
			else if s_key='Editor' then editor:=s_val;
		until s_sec='';
  until s_ini='';
end;

procedure WriteIni;
var s:string;
begin;
  s:='[Settings]'+CR
+'Res='+CB2.Text+CR
+'Format='+CB3.Text+CR
+'Paths='+paths+CR
+'Editor='+editor+CR
+'[tex2ps]'+CR
+tex2ps+CR
+'[Template]'+CR
+template{+CR};
StrSaveToFile(f_ini,s);
{
  SetIniStr(f_ini,'Settings','Res',CB2.Text);
  SetIniStr(f_ini,'Settings','Format',CB3.Text);
  SetIniStr(f_ini,'Settings','Paths',paths);
  SetIniStr(f_ini,'Settings','Editor',editor);
  SetIniSec(f_ini,'tex2ps',tex2ps);
  SetIniSec(f_ini,'Template',template+CR);
}
end;			

function MikPaths(i:integer):string;
var k:HKEY;
begin;
  k:=RegKeyOpenRead(HKEY_LOCAL_MACHINE,'SOFTWARE\MiK\MiKTeX\CurrentVersion\MiKTeX');
  Result:=RegKeyGetStrEx(k,'Install Root');
  if (Length(Result)=0) or (i=0) then Exit;
  if i=1 then Result:=Result+'\miktex\bin';
end;

  
procedure B_MouseMove(dummy:Pointer;Sender: PControl;var Mouse: TMouseEventData);
var  P:TPoint;i,dy:integer;
begin
  W.SimpleStatusText:=PChar(Sender.CustomData);
end;
  


procedure B_11Click(Dummy:Pointer; Sender: PControl);
begin;
  WriteIni;
end;



procedure GetBBox(s:string;var b1,b2,b3,b4:integer);
const boundbox='%%BoundingBox:';
var i:word;
begin
b1:=-1;
i:=pos(boundbox,s);
if i=0 then ShowMessage('没找到 bounding box.'
  +' 请检查您的TeX代码、本软件的Tex2ps设置(调用dvips时请加上选项 -E)、路径设置(gswin32c).');
if i=0 then exit;
i:=i+ length(boundbox)+1;
b1:=get_num(s,i);
b2:=get_num(s,i);
b3:=get_num(s,i);
b4:=get_num(s,i);
//ShowMessage(Format('%d,%d,%d,%d',[b1,b2,b3,b4]));
end;

procedure CleanFiles;
begin;
    DeleteFile(f_tmp);
    DeleteFile(PChar(fn+'.bmp'));
    DeleteFile(PChar(fn+'.tex'));
    DeleteFile(PChar(fn+'.aux'));
    DeleteFile(PChar(fn+'.log'));
    DeleteFile(PChar(fn+'.dvi'));
    DeleteFile(PChar(fn+'.ctx'));
    DeleteFile(PChar(fn+'.ty'));
    DeleteFile(PChar(fn+'.ps'));
    DeleteFile(PChar(fn+'.bb'));
end;

procedure MakeBmp;
var
  fac:real;s:string;
  b1,b2,b3,b4:integer;
begin
  ChDir(tmp);  
  CleanFiles;
  if C2.Checked then ShowMessage('进入文件夹：'+tmp);
  if C2.Checked then ShowMessage('可执行文件搜索路径为：'+GetEnv('PATH'));
  if (Pos('{cct',M1.Items[0])>0) and (Pos('CJK',M1.Items[0])=0) then ext:='.ctx' 
  else if Pos('\input tyinput',M1.Text)>0 then ext:='.ty'
  else ext:='.tex';
  StrSaveToFile(fn+ext,M1.Text);
  if Pos('\b'+'egin{document}',M1.Text)=0 then cmd:='tex' else cmd:='latex';
  s:='@set _Res='+CB2.Text+CR
    +'@set _Bmp='+CB3.Text+CR
    +'@set _Cmd='+cmd+CR
    +tex2ps+CR
    +'if exist %1.ps  '+'gswin32c.exe -dNOPAUSE -dBATCH -sDEVICE=bbox -sOutputFile=- %1.ps > %1.bb'+CR;
  StrSaveToFile(f_tmp,s);
  if C2.Checked then ShowMessage('将运行以下命令：['+comspec+' '+f_tmp+' '+fn+']'+CR+s);
//  WinExec(PChar(comspec+' ' +f_tmp+' '+fn),SW_SHOW);Sleep(2000);
  Shell(comspec+' ' +f_tmp+' '+fn,SW_SHOW,true);
  //ExecuteWait('',comspec+' ' +f_tmp+' '+fn,'',SW_SHOW,INFINITE,nil);
  if FileExists(fn+'.bmp') then exit
  else if C2.Checked then ShowMessage('没有发现文件 '+fn+'.bmp！');
  s:=StrLoadFromFile(fn+'.bb')+StrLoadFromFile(fn+'.ps');
  GetBBox(s,b1,b2,b3,b4);//Inc(b3,8);//Inc(b4,4);
  if b1>=0 then 
    begin;
    fac:=4.167*Str2Double(CB2.Text)/300.0;
    cmd:='gswin32c  -q -dNOPAUSE -dBATCH'+
      ' -sDEVICE='+CB3.Text
      +' -r'+CB2.Text
      +' -sOutputFile='+fn+'.bmp '
      +' -g'+Int2Str(round((b3-b1)*fac))+'x'+Int2Str(round((b4-b2)*fac))
      +' -c -'+Int2Str(b1)+' -'+Int2Str(b2)+' translate  -q '
      +fn+'.ps';
    if C2.Checked then begin;ShowMessage('将运行以下命令：['+comspec+' '+cmd+']'+CR+s);end;
    ExecuteWait('',comspec+' ' +cmd,'',SW_SHOWMINIMIZED,INFINITE,nil);
    end;
end;

procedure TransBmp;
var i,j:integer;c:TColor;dc:HDC;
begin;Image2.Assign(Image1);
if C3.Checked then
with Image1^ do
  begin
  //Image2.Width:=Width;Image2.Height:=Height;Image2.PixelFormat:=PixelFormat;
  c:=DIBPixels[0,0];Image2.PixelFormat:=pf24bit;
  for i:=0 to Width-1 do
    for j:=0 to Height-1 do
      if DIBPixels[i,j]=c then Image2.DIBPixels[i,j]:=L0.Color
      else Image2.DIBPixels[i,j]:=L0.Font.Color;
  end;
end;




procedure ChooseTEX(i:integer);
begin;
	M1.Text:=Trim(TeXList.Items[i-1]);
	CB1.Text:=Int2Str(i);
end;



procedure DrawBmp;
begin;
  if Image1.Empty then exit;
  TransBmp;Image2.CopyToClipboard;
  PB.Width:=Image2.Width;
  PB.Height:=Image2.Height;
  PB.Visible:=true;
//  PB.Canvas.CopyRect(PB.ControlRect,W.Canvas,B1.ControlRect);
//	W.Canvas.CopyRect(PB.ControlRect,W.Canvas,B1.ControlRect);

end;

procedure paint(dummy:pointer;sender:pcontrol;DC:HDC);
var r:TRect;
begin
  //r:=Image2.BoundsRect;Image2.StretchDraw(DC,PB.BoundsRect);//PB.Canvas.CopyToClipboard;
  if Image2.Width>0 then Image2.Draw(DC,0,0);//  Image1.StretchDraw(DC,B1.BoundsRect);
end;



procedure B_1Click(Dummy:Pointer; Sender: PControl);
begin;
  if M2.Visible then 
    begin 
    B_10.Caption:='设定命令'; M2.Visible:=false;
    if ShowMsg('您可能修改了当前设置,应用并保存当前设置?', MB_YESNO)=ID_YES then
       begin tex2ps:=M2.Text;B_11Click(Dummy,Sender);end
    end;
  MakeBmp;
  if FileExists(fn+'.bmp') then
    begin;
    Image1.Dormant;Image2.Dormant;
    Image1.LoadFromFile(fn+'.bmp');
    DrawBmp;// msgok('xx');  
    TeXList.Add(M1.Text+CS);
    idx:=TeXList.Count;
    CB1.Add(Int2Str(idx));
    CB1.Text:=Int2Str(idx);
    if CB4.Text<>'' then SendTo(CB4.Text);
    end;
  if not C2.Checked  then CleanFiles;
end;

procedure B_2Click(Dummy:Pointer; Sender: PControl);
begin
M1.Text:=template;
//M1.CaretPos:=Point(0,3);
M1.Focused:=true;
Image1.Width:=0;
end;

procedure B_3Click(Dummy:Pointer; Sender: PControl);
begin
template:=M1.Text;
end;


procedure B_4Click(Dummy:Pointer; Sender: PControl);
begin
idx:=idx-1;if idx<1 then idx:=TeXList.Count;
ChooseTEX(idx);Image1.Clear;
end;


procedure S_Split(var L:TStrList;s:string);
var i1,i2:integer;
begin;
i1:=1;i2:=1;idx:=1;L.Clear;CB1.Clear;
repeat
  i2:=PosEx(CS,s,i1);if i2=0 then break;
  L.Add(Copy(s,i1,i2-i1+1));
  CB1.Add(Int2Str(idx));
  Inc(idx);  i1:=i2+1;
until false;
end;

procedure B_5Click(Dummy:Pointer; Sender: PControl);
begin
SaveDialog1.Title:='另存为：';
SaveDialog1.DefExtension:='txl';
if SaveDialog1.Execute then
  if pos('.txl',SaveDialog1.FileName)=0 then
    StrSaveToFile(SaveDialog1.FileName,M1.Text)
  else
    StrSaveToFile(SaveDialog1.FileName,TeXlist.Text);
//DrawBmp;
end;


procedure B_6Click(Dummy:Pointer; Sender: PControl);
var i1,i2:integer; s:string;
begin
OpenDialog1.Title:='打开：';
if OpenDialog1.Execute then
  if pos('.txl',OpenDialog1.FileName)=0 then
    M1.Text:=StrLoadFromFile(OpenDialog1.FileName,)
  else
    begin;s:=StrLoadFromFile(OpenDialog1.FileName);
    S_Split(TeXList,s);ChooseTeX(1);end;
//DrawBmp;   
end;

procedure CB1Change(Dummy:Pointer; Sender: PControl);
begin
ChooseTEX(Str2Int(CB1.Text));
end;




function SearchTreeForFile(RootPath,InputPathName,OutputPathBuffer:PChar):BOOL;stdcall;external 'imagehlp.dll';

function SearchFile(f,d:string):string;
var buf:LPSTR;
begin
buf:=AllocMem(255);
SearchTreeForFile(PChar(d),PChar(f),buf);
Result:=buf;FreeMem(buf);
end;

function GetDir(f:string;search:boolean):string;
begin{
if search then
  begin
  //Result:=SearchFile(f,'c:\');
  //if Result='' then Result:=SearchFile(f,'d:\');
  end
else}
  with OpenDialog2 do
  begin
  Title:='请选择文件夹：';
  Filter:='可执行文件('+f+')|'+f;Filename:=f;
  if Execute then Result:=Filename;
  end;
Result:=ExtractFilePath(Result);
end;


procedure B_9Click(Dummy:Pointer; Sender: PControl);
var s:string;
begin
  msgOk('本软件需要用到latex、dvips、gswin32c等命令，请分别指定其路径。');
  s:=GetDir('gswin32*.exe',false)+';'
    +GetDir('tex*.exe',false)+';'
    +GetDir('dvips*.exe',false);
if ShowMsg('本次运行将使用如下路径：'+s+CR, MB_YESNO)=ID_YES then
  begin;paths:=s;SetEnvironmentVariable('PATH',PChar(s+';'+GetEnv('Path')));end
end;

procedure B_10Click(Dummy:Pointer; Sender: PControl);
begin
M2.Visible:=not M2.Visible;
if M2.Visible then
  begin B_10.Caption:='应用';M2.Text:=tex2ps;end
else
  begin B_10.Caption:='设定命令';tex2ps:=M2.Text;end
end;


procedure B_7Click(Dummy:Pointer; Sender: PControl);
begin
ShowMessage(
'本软件可作为TexPoint的替代品，但适用范围更广泛，'
+'它使您将LaTeX/TeX强大的排版功能（特别是数学公式）轻松用于各种文档。'
+'TexPoint使用比较方便，但只能在Office2000中搭配PowerPoint使用，'
+'而且前提是要求系统装有VBA。'
+'本软件则可以与任何支持图片粘贴的软件配合，当然啦，'
+'写字板/Word/Excel/PowerPoint/WpsOffice/CCED2000/FrontPage/Maple/……都不在话下了:)'+CR+CR

+'运行本软件只需装有LaTeX,dvips和GhostScript（这些都含在CTEX套装里了）。'
+'不需要VBA的支持，因此网上流行的Office97迷你版（功能齐全但只占用20多兆磁盘空间）或其它字处理软件里都可以用上LaTeX了！呵呵。。。'
+'本软件同时支持CJK、CCT、天元这三种中文LaTeX，这是TexPoint做不到的。'
+'顺便提一句，用TexPoint做出的幻灯片文件比较大，而用本软件则可做得比较小。'
+'本软件为绿色软件，不需要安装，体积很小，可直接运行。'
+'另外，本软件搭配自由软件LaTeX macros，更易于使用！'+CR+CR

+'第一次使用时，记得要首先做些必要的设定哟：'
+'如果latex,dvips,gswin32c这几个命令不在系统的搜索路径中了，可以点 [设定路径] 设置一下；'
+'若还不行，恐怕要再点 [设定命令] 进一步设定一下怎么把.tex文件转换成.ps文件喽'
+'（别忘了点 [应用] 使更改生效）。'
+'设置好后没有问题的话，记着保存设置哟。'+CR+CR

+'不会使用？太简单啦：'
+'在右边的框里将你的LaTeX代码粘贴过来（或直接敲进去），'
+'然后点 [编译成位图] ，这些代码将被自动编译，'
+'没有错误的话就自动生成一个图片（可在下面预览），并放在剪贴板里，'
+'您在其它软件中只要粘贴一下（一般按Ctrl+V就可以）就行了！'
+'您还嫌麻烦？选择最上面的程序列表，就可以自动把图片送入相应的程序！'
+CR+CR

+'想来点颜色看看？首先确认勾上[颜色]选项，然后分别用鼠标左键或右键点点 [abc]，有什么效果？（再试试这一招吧：'
+'在document环境中输入：\pagecolor{blue}\color{red}$\sqrt{2}=?$，试试看得到了什么？）'+CR+CR

+'还想把中文搞进去？那就点击[中/英]，这时您就可以使用中文了！不妨输入“\kaishu 中文”看看效果！ '
+CR+CR

+'有人会问：我以前生成的位图可以再次编辑吗？没问题！'
+'比如你在做一个幻灯片，需要很多数学公式，它们都由本软件生成；'
+'然后又发现有的公式需要作修改，怎么办？'
+'不断点 [后退] 或从其下拉列表中直接选公式的编号，就可以找到你需要的公式了！'
+'重新编辑，再次编译就可以了！当然以后如果还想用这些公式，'
+'别忘了点 [存为] 将它们存盘，以后还可调出来，这可是好习惯啊！'+CR+CR

+'其它的功能，自己琢摩吧！实在不明白哪个按钮干什么用，用鼠标在上面停留一会，就有个简短的功能提示哟。'+CR+CR
);
end;


procedure B_8Click(Dummy:Pointer; Sender: PControl);
begin
ShowMessage(
 'TeX位图工具 version 0.98'+CR+CR
+'欢迎广大LaTeX/TeX用户免费使用。'+CR+CR
+'版权所有 2004--2008 马宏宾。'+CR
+'     '+CR
+'作者保留对本软件的所有权利。'+CR
+'如有问题或建议，请到MTeX-suite论坛讨论。'+CR
+'E-mail: mtex-suite@googlegroups.com'+CR
);
end;



procedure C1Click(Dummy:Pointer; Sender: PControl);
begin
W.StayOnTop:=C1.Checked;
end;

procedure FormResize(Dummy:Pointer; Sender: PControl);
begin
M1.Width:=W.Width-M1.Left-2;
M2.Width:=M1.Width;
M2.Height:=W.Height-M2.Top-10;
DrawBmp;
end;



procedure L0MouseDown( Dummy : Pointer; Sender : PControl; var Mouse : TMouseEventData );
begin
if Mouse.Button=mbLeft then
  begin
  ColorDialog1.Color:=L0.Color;
  if ColorDialog1.Execute then L0.Color:=ColorDialog1.Color;
  end
else
  begin
  ColorDialog1.Color:=L0.Font.Color;
  if ColorDialog1.Execute then L0.Font.Color:=ColorDialog1.Color;
  end;
DrawBmp;
end;

procedure B3MouseDown( Dummy : Pointer; Sender : PControl; var Mouse : TMouseEventData );
begin
if Mouse.Button=mbLeft then
  begin
  StrSaveToFile(fn+'.tex',M1.Text);
  shell(editor+' '+fn+'.tex',SW_SHOW,true);
  M1.Text:=StrLoadFromFile(fn+'.tex');
  end
else
  begin
  OpenDialog2.Filter:='可执行文件(*.exe;*.com;*.bat;*.cmd)|*.exe;*.com;*.bat;*.cmd';
  if OpenDialog2.Execute then editor:=OpenDialog2.FileName;
  end;
//DrawBmp;
end;

Function EnumWindowsProc (Wnd: HWND; LParam: LPARAM): BOOL; stdcall;
begin
Result := True;
if (IsWindowVisible(Wnd) or IsIconic(wnd)) and
((GetWindowLong(Wnd, GWL_HWNDPARENT) = 0) or
(GetWindowLong(Wnd, GWL_HWNDPARENT) = GetDesktopWindow)) and
(GetWindowLong(Wnd, GWL_EXSTYLE) and WS_EX_TOOLWINDOW = 0) then
CB4.add(GetText(Wnd));
end;
  
  

procedure B1Click(Dummy:Pointer; Sender: PControl);
var
Param : Longint;
begin
CB4.Clear;CB4.Add('');
EnumWindows(@EnumWindowsProc , Param);
end;

procedure B2Click(Dummy:Pointer; Sender: PControl);
begin;WinExec(latexmac,SW_SHOW);end;

procedure B4Click(Dummy:Pointer; Sender: PControl);
const _c='[CJK]{cctart}';_e='{article}';var s:string;
begin;//M1.Items[0]:='\documentclass{cctart}\pagestyle{empty}'+CR;
s:=M1.Items[0];
if StrReplace(s,_e,_c) then M1.Items[0]:=s+CR
else if StrReplace(s,_c,_e) then M1.Items[0]:=s+CR;
end;


procedure CB4Change(Dummy:Pointer; Sender: PControl);
begin
if CB4.Text<>'' then SendTo(CB4.Text);
end;


procedure InitObjs;
begin;
  //App := NewApplet( 'TeX_Bmp' ); App.IconLoad(0,'TeX_bmp');

  W := NewForm( nil, 'TeX位图 [mhb]' );//W.Icon:=App.Icon;//Load(0,'TeX_bmp');
  if not JustOne(W,fn) then Halt(0);
  //SetFont(W.Font,'宋体,12');
  W.font.releasehandle;//[qhs]
  W.Font.AssignHandle(GetStockObject(DEFAULT_GUI_FONT));//[qhs]
  B_1:=NewButton(W,'编译成位图').PlaceUnder.SetSize(140,0);
  B_2:=NewButton(W,'新的TeX位图').PlaceUnder.SetSize(140,0);
  B_3:=NewButton(W,'设为新的TeX模板').PlaceUnder.SetSize(140,0);

  B_4:=NewButton(W,'后退').PlaceUnder.SetSize(45,0);
  B_5:=NewButton(W,'存为…').PlaceRight.SetSize(45,0);
  B_6:=NewButton(W,'打开…').PlaceRight.SetSize(45,0);
  CB1:=NewCombobox(W,[]).PlaceDown.SetSize(45,0);
  CB1.DropDownCount:=20;
  B_7:=NewButton(W,'帮助').AlignLeft(B_5).PlaceRight.SetSize(45,0);
  B_8:=NewButton(W,'关于…').PlaceRight.SetSize(45,0);
  CB1.Shift(0,-2);

  P1:=NewPanel(W,esLowered).PlaceDown.SetSize(140,100);
  B2:=NewButton(P1,'π∫').PlaceRight.SetSize(45,0);
  B3:=NewButton(P1,'编辑器').PlaceRight.SetSize(45,0);
  B4:=NewButton(P1,'中/英').PlaceRight.SetSize(45,0);
  C1:=NewCheckbox(P1,'在最上').PlaceDown.SetSize(65,0);
  C2:=NewCheckbox(P1,'调试').PlaceRight.SetSize(65,0);
  C3:=NewCheckbox(P1,'颜色').PlaceDown.SetSize(65,0);
  L0:=NewLabel(P1,'abc').PlaceRight.SetSize(40,0);
  L0.Color:=clWhite;

  L1:=NewLabel(P1,'分辨率').PlaceDown.SetSize(65,0);
  CB2:=NewCombobox(P1,[]).PlaceRight.SetSize(65,0);
  CB2.DropDownCount:=20;
  L2:=NewLabel(P1,'位图格式').PlaceDown.SetSize(65,0);
  CB3:=NewCombobox(P1,[]).PlaceRight.SetSize(65,0).ResizeParent;
  CB3.DropDownCount:=20;

  B_9:=NewButton(W,'设定路径').PlaceDown.SetSize(70,0);
  B_10:=NewButton(W,'设定命令').PlaceRight.SetSize(70,0);
  B_11:=NewButton(W,'保存TeX模板和设定').PlaceDown.SetSize(140,0).ResizeParent;

  B1:=NewButton(W,'刷新').PlaceRight.AlignTop(B_1).SetSize(60,0);
  CB4:=NewCombobox(W,[coReadOnly]).PlaceRight.SetSize(340,0);
  CB4.DropDownCount:=20;
  M1:=NewEditbox(W,[eoMultiline]).PlaceUnder.AlignLeft(B1).SetSize(450,200);
  M2:=NewEditbox(W,[eoMultiline]).PlaceUnder.AlignLeft(B1).SetSize(450,70).ResizeParent;
  M2.Visible:=false;
  PB:=NewPaintbox(W).PlaceUnder.AlignTop(M2).AlignLeft(B1);
  PB.Visible:=false;
  with CB2^ do begin;Add('300');Add('600');Add('1200');end;
  CB2.Text:='600';
  with CB3^ do begin;Add('bmpmono');Add('bmpgray');Add('bmp16');Add('bmp256');Add('bmp16m');end;
  Image1:=NewBitmap(0,0);//M2.Width,M2.Height);
  Image2:=NewBitmap(0,0);
  OpenDialog1.Filter:='TeX list file(*.txl)|*.txl|TeX file(*.tex;*.ctx)|*.tex;*.ctx';
  SaveDialog1.Filter:=OpenDialog1.Filter;
  
  W.SimpleStatusText:=PChar('本软件帮您在任何windows软件中使用latex强大的数学排版功能！移动鼠标查看每个按钮的功能提示！');
  B_1.CustomData:=PChar('编译右框中的latex代码为位图，然后将它复制到剪贴板里（并发送到您选择的应用程序）。');
  B_2.CustomData:=PChar('在右框中重置为默认的latex模板。');  
  B_3.CustomData:=PChar('将右框中的latex代码设置为默认的latex模板。');
  B_4.CustomData:=PChar('退回到上一次编译的latex代码。');
  B_5.CustomData:=PChar('将编译历史存到txl文件中，以备以后重新调入使用。');
  B_6.CustomData:=PChar('打开txl文件，从而可重新编译生成以往用过的数学公式。');
  B_7.CustomData:=PChar('显示本软件简单的帮助提示。');  
  B_8.CustomData:=PChar('显示本软件的版权信息。');
  B_9.CustomData:=PChar('设定本软件要用到的一些程序（latex、dvips、gswin32c）的路径。');
  B_10.CustomData:=PChar('设定本软件编译latex代码过程中运行的批处理命令。');
  B_11.CustomData:=PChar('将您设定的latex模板、程序路径和编译命令存到配置文件tex-bmp.ini中，使下次启动时自动调入。');
  B1.CustomData:=PChar('刷新当前windows应用程序列表，以供您选择。');  
  B2.CustomData:=PChar('打开模板符号选择工具，供您选择各种数学符号。');
  B3.CustomData:=PChar('用默认的编辑器打开当前的latex代码。');
  B4.CustomData:=PChar('这个按钮用来切换是否使右框中的latex模板支持中文。');
  C1.CustomData:=PChar('选中后可使本软件总置于其它应用程序窗口的上方。');  
  C2.CustomData:=PChar('选中进入调试模式，编译过程中显示更多信息。');
  C3.CustomData:=PChar('选中可使生成的位图具有色彩，背景、前景色分别由鼠标左右键单击文字[abc]来设置。');
  L0.CustomData:=C3.CustomData;
  L1.CustomData:=PChar('分辨率决定生成的图片的分辨率大小以及图片的放缩比例。');  
  L2.CustomData:=PChar('默认的位图格式是透明的单色位图bmpmono，您可改成其它格式来增加latex色彩支持，但会增大生成图片数据的大小。');
  
  exepath:=GetStartDir;
  tmp:=GetEnv('TMP');
  if tmp='' then tmp:=exepath;
  f_ini:=GetEnv('ETC')+'\'+fn_ini;
  if not FileExists(f_ini) then f_ini:=exepath+fn_ini;
  comspec:=exepath+'tex-dos.exe';
  if not FileExists(comspec) then comspec:='command.com /c';
  ext:='.tex';
  paths:=MikPaths(1);
  idx:=0;
  template:=DefTemplate;
  tex2ps:=DefTex2ps;
  editor:='notepad';
  TeXList.Clear;

  if FileExists(f_ini) then ReadIni;
  
  M1.Text:=template;
  SetEnvironmentVariable('PATH',PChar(exepath+';'+paths+';'+GetEnv('Path')));
  //msgOK(GetEnv('Path'));
  DeleteFile(PChar(fn+'.ctx'));
  DeleteFile(PChar(fn+'.tex'));
end;


procedure SetEvents;
begin;
  B_1.OnClick := TOnEvent( MakeMethod( nil, @B_1Click ) );
  B_2.OnClick := TOnEvent( MakeMethod( nil, @B_2Click ) );
  B_3.OnClick := TOnEvent( MakeMethod( nil, @B_3Click ) );
  B_4.OnClick := TOnEvent( MakeMethod( nil, @B_4Click ) );
  B_5.OnClick := TOnEvent( MakeMethod( nil, @B_5Click ) );
  B_6.OnClick := TOnEvent( MakeMethod( nil, @B_6Click ) );
  B_7.OnClick := TOnEvent( MakeMethod( nil, @B_7Click ) );
  B_8.OnClick := TOnEvent( MakeMethod( nil, @B_8Click ) );
  B_9.OnClick := TOnEvent( MakeMethod( nil, @B_9Click ) );
  B_10.OnClick := TOnEvent( MakeMethod( nil, @B_10Click ) );
  B_11.OnClick := TOnEvent( MakeMethod( nil, @B_11Click ) );

  C1.OnClick := TOnEvent( MakeMethod( nil, @C1Click ) );
  CB1.OnChange := TOnEvent( MakeMethod( nil, @CB1Change ) );
  CB4.OnChange := TOnEvent( MakeMethod( nil, @CB4Change ) );

  B1.OnClick := TOnEvent( MakeMethod( nil, @B1Click ) );
  L0.OnMouseDown := TOnMouse( MakeMethod( nil, @L0MouseDown ) );
  B3.OnMouseDown := TOnMouse( MakeMethod( nil, @B3MouseDown ) );
  B2.OnClick := TOnEvent( MakeMethod( nil, @B2Click ) );
  B4.OnClick := TOnEvent( MakeMethod( nil, @B4Click ) );
  W.OnResize := TOnEvent( MakeMethod( nil, @FormResize ) );
  PB.OnPaint := TOnPaint(MakeMethod(nil,@Paint));
  
  B_1.OnMouseMove:=TOnMouse( MakeMethod( nil, @B_MouseMove ) );
  B_2.OnMouseMove:=TOnMouse( MakeMethod( nil, @B_MouseMove ) );
  B_3.OnMouseMove:=TOnMouse( MakeMethod( nil, @B_MouseMove ) );
  B_4.OnMouseMove:=TOnMouse( MakeMethod( nil, @B_MouseMove ) );
  B_5.OnMouseMove:=TOnMouse( MakeMethod( nil, @B_MouseMove ) );
  B_6.OnMouseMove:=TOnMouse( MakeMethod( nil, @B_MouseMove ) );
  B_7.OnMouseMove:=TOnMouse( MakeMethod( nil, @B_MouseMove ) );
  B_8.OnMouseMove:=TOnMouse( MakeMethod( nil, @B_MouseMove ) );
  B_9.OnMouseMove:=TOnMouse( MakeMethod( nil, @B_MouseMove ) );
  B_10.OnMouseMove:=TOnMouse( MakeMethod( nil, @B_MouseMove ) );
  B_11.OnMouseMove:=TOnMouse( MakeMethod( nil, @B_MouseMove ) );
  B1.OnMouseMove:=TOnMouse( MakeMethod( nil, @B_MouseMove ) );
  B2.OnMouseMove:=TOnMouse( MakeMethod( nil, @B_MouseMove ) );
  B3.OnMouseMove:=TOnMouse( MakeMethod( nil, @B_MouseMove ) );
  B4.OnMouseMove:=TOnMouse( MakeMethod( nil, @B_MouseMove ) );
  C1.OnMouseMove:=TOnMouse( MakeMethod( nil, @B_MouseMove ) );
  C2.OnMouseMove:=TOnMouse( MakeMethod( nil, @B_MouseMove ) );
  C3.OnMouseMove:=TOnMouse( MakeMethod( nil, @B_MouseMove ) );
  L1.OnMouseMove:=TOnMouse( MakeMethod( nil, @B_MouseMove ) );
  L2.OnMouseMove:=TOnMouse( MakeMethod( nil, @B_MouseMove ) );
  L0.OnMouseMove:=TOnMouse( MakeMethod( nil, @B_MouseMove ) );
  //B_1.OnMouseMove:=TOnMouse( MakeMethod( nil, @B_MouseMove ) );


end;

begin
  InitObjs;
  SetEvents;
  B1.Click;
  Run(W);
  CleanFiles;
end.

