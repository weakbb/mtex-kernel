{
v0.91: 根据CTAN网站搜索功能的改变，修改默认设置和相关代码，允许CTAN_Find里面用***代表文件名
v0.90: 允许用户设置CTAN_Find、CTAN_TPM，并提供国内搜索的url，从而方便教育网用户不用出国代理就能搜索CTAN资源
v0.88: 修正查找tfm异常退出的bug
v0.87: 使用系统默认字体
v0.86: WorkDir设置允许用环境变量；实现线程
v0.85:
v0.80: 支持通过语言文件修改字体大小及属性
v0.75: 多语言支持，可通过语言文件修改界面语言；加入google搜索？？
v0.70:下载tfm文件对应的字体；默认选择zip文件；
v0.65:修改处理zip包的命令，以支持长文件名。
v0.60:加入宏包文件搜索功能。可以解析ftp地址中的用户名与密码。
v0.55:XP风格美化；可从环境变量ETC指定的目录读配置文件；
v0.5:将站点列表更新为ctan上的所有镜像站点(上一版只包括ftp站点).
     修改代理功能,目前支持http、socks4、ftp代理及http代理认证.
     支持解压cab和zip包,需外部文件cabarc.exe和pkunzip.exe支持.
     其他一些界面上的修改.
v0.4:增加代理服务器功能。增加修改配置文件功能。
v0.3:增加tpm文件来判断选择的文件。增加处理bibtex/makeindex样式文件的命令。
v0.2:增加ftp站点列表配置及选择。修正下载程序。增加提示。修正安装脚本。
v0.1:
}
program net_pkg;
{$D SMALLEST_CODE}
uses
  windows,messages,kol,CommCtrl,wininet,xptheme,shellapi{,httpsend,ftpsend};{$I w32.pas}
//{$R MTeX.res}
{$R net_pkg.res}
const
   BufferSize = 65536;
   fn_ini='net_pkg.ini';
   f_ftp='net_pkg.ftp';
   usage='本工具用于帮您在网上搜索宏包，并下载下来装到MTeX中。[mhb & qhs] v0.90'+CR
	+'按钮0:该按钮用来检查MTeX是否已有指定宏包(并将宏包文件路径拷贝到剪贴板)。'+CR
	+'按钮1:在网上搜索宏包→按钮2:下载选择的文件→按钮3:安装宏包。'+CR
	+'您还可以用按钮[...]选择文件下载的目标文件夹，默认情况下直接下载到MTeX宏包目录中。'+CR
	+'如果您需要使用代理服务器或修改其它默认配置，请点击按钮[配置]。';
   s_pattern='***';
   // def_ctan_find='http://www.ctan.org/cgi-bin/filenameSearch.py?filename=';
   def_ctan_find='http://www.ctan.org/search/?&search_type=filename&filename_number=1000&filename_start=0&search=***';
   def_ctan_tpm='http://www.ctan.org/tex-archive/systems/win32/fptex/current/package/';
   // pre_beg='<pre class=''filename_search_hits''>';pre_end='</pre>';
   // a_beg='<a href=';a_mid='>';a_end='</a>';
   pre_beg='<table class=''pkg_info''>';pre_end='</table>';
   a_beg='<a href=';a_mid='>';a_end='</a>';
   def_comspec='mtex-dos.exe';
   def_pkglist='pkg.lst';
   def_workdir='texlocal\_new\';
   def_ftpsite='ftp://ftp.ctex.org/CTAN';
   bit_ctan_mirror='http://mirror.bitunion.org/CTAN';
   //'localhost';ftp://ftp.comp.hkbu.edu.hk/pub/TeX/CTAN;ftp://ftp.ccu.edu.tw/pub/tex;http://ctan.cdpa.nsysu.edu.tw;ftp://ftp.nctu.edu.tw/pub/tex
   //'http://www.ctan.org/get?fn=/'
   def_extlist='.sty.cls.fd.fdd.fdx.sfd.enc.dtx.ins.ini.con.cfg.def.dat.cap.cpx.pro.ps.tex.clo.ist.doc.mbs.tss.new.mf.tfm.pfb';
   def_extractcab='for %a in (*.cab) call cabarc -p -o X %a';
   def_extractzip='unzip -j -o *.zip';
   def_cmd_install=
    '@echo off'+CR
	+'cd "%1"'+CR
	+def_extractcab+CR
	+def_extractzip+CR
	+'for %a in (*.ins) call latex %a'+CR
	+'call copyfnts . %1'+CR
	+'copy *.bst;*.csf %MTEX\texlocal\bibtex\'+CR
	+'copy *.ist %MTEX\texlocal\mkidx\'+CR
	+'if exist %MTEX\pkg.lst call updpkg .'+CR;

//   cmd_install='@echo off'+CR
//   +def_extractcab+CR
//   +def_extractzip+CR
//   +'for %a in (*.ins) call latex %a'+CR
//   +'call copyfnts . %1'+CR
//   +'copy *.bst;*.csf %MTEX\emtex\bibtex\'+CR
//   +'copy *.ist %MTEX\emtex\mkidx\'+CR
//   +'if exist %MTEX\pkg.lst call updpkg .'+CR;
var TipVisible:Boolean;TT:HWND;ti: TOOLINFO;hint:string;
var App,W,B0,B1,B2,B3,B4,B5,B6,E1,E2,E3,E4,L1,L2,L3,L4,LB1,CB1,CB2,CB3,CB4,P1,C1,EB1,PB1:PControl;
	p,pkg:PStrList;s:string;
//	osd:POpenSaveDialog;
	odd:POpenDirDialog;
	T:PTimer;
	cnt:integer;

	f_ini,mtex,pkgname,comspec,extractcab,extractzip,searchtpm,cmd_install,ftp_site,ctan_find,ctan_tpm,extlist,pkglist,workdir,ftp_proxy,http_proxy,HttpProxyUser,HttpProxyPass,ftps,s_tpm,s_files:string;
	Th:PThread;
	Th_Session,Th_Connect:HInternet;
	Th_fileURL,Th_FileName,Th_proxy: String;
	
	Th_Downloaded,Th_UseFTP:boolean;
//	FTP:PFTPSend;

procedure ReadIni;forward;
function IsSelected(f:string):boolean;forward;
function Download:bool;forward;

function File_Name(fn:string):PChar;
begin;
Result:=StrRScan(PChar(fn),'/')+1;
end;

function ProxyAuthentication(hConnect: HInternet{; HttpProxyUser,HttpProxyPass: string}): boolean;
label again;
var dwLength, dwCode, dwSize, dwReserved: DWORD;
    nilptr:Pointer;
    bInitalRequest: boolean;
begin
  Result := false;
  bInitalRequest := true;
  again:
  if not bInitalRequest then
  begin
    if not HttpSendRequest(hConnect, nil, 0, nil, 0) then begin;Exit;end;
  end;
  dwSize := sizeof(dwCode);
  if not InternetQueryOption(hConnect, INTERNET_OPTION_HANDLE_TYPE, @dwCode, dwSize) then
    begin;Exit;end;//msgok(int2str(dwCode));
  if ((dwCode = INTERNET_HANDLE_TYPE_HTTP_REQUEST) or (dwCode = INTERNET_HANDLE_TYPE_CONNECT_HTTP)) then
  begin
    dwSize := sizeof(DWORD); dwReserved := 0;
    if not HttpQueryInfo(hConnect, HTTP_QUERY_STATUS_CODE or HTTP_QUERY_FLAG_NUMBER, @dwCode, dwSize, dwReserved) then begin;Exit;end;
    if dwCode = HTTP_STATUS_PROXY_AUTH_REQ then
    begin
      if not InternetQueryDataAvailable(hConnect, dwLength, 0,0) then
	begin;Exit;end;//msgok(HttpProxyUser);msgok(HttpProxyPass);
	if (Length(HttpProxyUser)>0)and(Length(HttpProxyPass)>0) then
	begin
          if not InternetSetOption(hConnect, INTERNET_OPTION_PROXY_USERNAME, pchar(HttpProxyUser), length(HttpProxyUser)+1) then
          begin
            {showmessage('InternetSetOptionFailed: INTERNET_OPTION_PROXY_USERNAME');}exit;
          end;
          if not InternetSetOption(hConnect, INTERNET_OPTION_PROXY_PASSWORD, pchar(HttpProxyPass), length(HttpProxyPass)+1) then
          begin
	    {showmessage('InternetSetOptionFailed: INTERNET_OPTION_PROXY_PASSWORD');}exit;
          end;
	  if not bInitalRequest then
	  begin;MsgBox('代理服务器的用户名或密码错误! 请点击[配置]按钮重新设置!',MB_OK or MB_SETFOREGROUND );Exit;end;
	  bInitalRequest := FALSE;
          goto again;
	end else begin
          if (InternetErrorDlg (GetDesktopWindow(),
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
  end;
  Result := true;
end;

function GetInetFile (const fileURL: String; var Response: PStrList): boolean;
var hSession, hConnect: HInternet;
    Buffer: array[1..BufferSize] of char;
    BufferLen, dwLength, dwCode, dwSize, dwReserved: DWORD;
    content: string;
    bInitalRequest: bool;
begin
     Result := False;
     if Length(http_proxy) > 0 then
     begin
       if http_proxy='ie' then begin;
         hSession := InternetOpen('Net_pkg', INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, INTERNET_FLAG_KEEP_CONNECTION);end
       else begin;
         hSession := InternetOpen('Net_pkg', INTERNET_OPEN_TYPE_PROXY, pchar(http_proxy), nil, INTERNET_FLAG_KEEP_CONNECTION);end
     end
     else begin;
       hSession := InternetOpen('Net_pkg',INTERNET_OPEN_TYPE_DIRECT, nil, nil, 0);
     end;
     if hSession=nil then begin;Exit;end;
     try
        hConnect := InternetOpenURL(hSession, PChar(fileURL), nil,0, INTERNET_FLAG_DONT_CACHE or INTERNET_FLAG_KEEP_CONNECTION or INTERNET_FLAG_RELOAD,0);

        if hConnect=nil then begin;Exit;end;
	if ((Length(http_proxy)>0)and(pos('http://',http_proxy)=1))or(http_proxy='ie') then
	begin;
	  if not ProxyAuthentication(hConnect{,HttpProxyUser,HttpProxyPass}) then begin;Exit;end;
        end;
        try
	   content := '';
           repeat
             FillChar(Buffer, SizeOf(Buffer), 0);
             if not InternetReadFile(hConnect, @Buffer, SizeOf(Buffer), BufferLen) then
	     begin;Exit;end;
             content := content+copy(Buffer,1,BufferLen);
	     W.processmessage;
           until BufferLen = 0;
           Response.Add(content);
           Result := True;
        finally
          InternetCloseHandle(hConnect);
        end
     finally
       InternetCloseHandle(hSession);
     end
end;

function DownloadURL (hSession:HInternet;const fileURL,sFileName,proxy: String): bool;//integer;
label again;
var hConnect: HInternet;
    Buffer: array[1..BufferSize] of char;
    BufferLen, dwLength: DWORD;
    DownloadedFile: PStream;
//    fsize: Integer;
begin
  Result := false;//0;
  hConnect := InternetOpenURL(hSession, PChar(fileURL), nil,0,
            INTERNET_FLAG_DONT_CACHE or INTERNET_FLAG_KEEP_CONNECTION or INTERNET_FLAG_RELOAD,0);
  if hConnect=nil then begin;Exit;end;
  try
    if ((Length(proxy)>0)and(pos('http://',proxy)=1))or(http_proxy='ie')then begin;
      if not ProxyAuthentication(hConnect{,HttpProxyUser,HttpProxyPass}) then begin;Exit;end;
    end;
    DownloadedFile := NewWriteFileStream(sFileName);
    try
//      fsize:= 0;
      repeat
        if not InternetReadFile(hConnect, @Buffer, SizeOf(Buffer), BufferLen) then
          begin;Exit;end;
				//showmessage(copy(Buffer,1,bufferlen));
//	fsize:= fsize+BufferLen;
        if (BufferLen>0)and(WriteFileStream(DownloadedFile,Buffer,BufferLen)<>BufferLen)then
          begin;exit;end;
        W.processmessages;
      until BufferLen = 0;
      Result := true;//fsize;//msgok(int2str(fsize));
    finally
       CloseFileStream(DownloadedFile);
    end;
  finally
    InternetCloseHandle(hConnect);
  end;
end;

function Th_OnExec( Sender: PThread ): Integer;
begin;

  if not Th_UseFTP then
	Th_Downloaded:=DownloadURL (Th_Session,Th_fileURL,Th_FileName,Th_proxy)
  else
	Th_Downloaded:=FtpGetFile(Th_Connect,PChar(Th_fileURL), PChar(Th_FileName),False,File_Attribute_Normal,Ftp_Transfer_Type_Binary, 0);
  T.Enabled:=false;
end;  		
		
function ThreadDownloadURL (hSession:HInternet;const fileURL,sFileName,proxy: String): bool;
begin;
  Th_UseFTP:=false;
  Th_Session:=hSession;
  Th_fileURL:=fileURL;
  Th_FileName:=sFileName;
  Th_proxy:=proxy;
  Th_Downloaded:=false;
  T.Enabled:=true;
  Th:=NewThreadAutoFree( TOnThreadExecute ( MakeMethod( nil, @Th_OnExec) ) );
  repeat
    W.ProcessMessages;
  until not T.Enabled;
  T.Enabled:=false;
  Result:=Th_Downloaded;
end;	

function ThreadGetFile (hConnect:HInternet; ftpURL,sFileName,proxy: String):bool;
begin;
  Th_UseFTP:=true;
  Th_Connect:=hConnect;
  Th_fileURL:=ftpURL;
  Th_FileName:=sFileName;
  Th_Downloaded:=false;
  T.Enabled:=true;
  Th:=NewThreadAutoFree( TOnThreadExecute ( MakeMethod( nil, @Th_OnExec) ) );
  repeat
    W.ProcessMessages;
  until not T.Enabled;
  T.Enabled:=false;
  Result:=Th_Downloaded;
end;
		
function GetHttpFile (hSession:HInternet; ftp_site: String;const proxy:string):bool;
var i,fsize: Integer;
    s,fname: String;
begin;
Result := false;
for i:=0 to LB1.Count-1 do
begin;
  if (LB1.ItemSelected[i]) and (LB1.Items[i]<>'') then
  begin;
    EB1.add('正在下载 '+ftp_site+LB1.Items[i]+' ... ');
    sendmessage(EB1.handle, WM_VSCROLL, SB_BOTTOM, 0);
    W.processmessages;
		fname:=FileNameExt(LB1.Items[i]);
    //if not DownloadURL(hSession, ftp_site+LB1.Items[i], fname,proxy) then
    if not ThreadDownloadURL(hSession, ftp_site+LB1.Items[i], fname,proxy) then
      EB1.add('失败'+CR)
    else begin;
      fsize := FileSize(fname);
			if (pos(lowercase(ExtractFileExt(fname)),'.htm.html')=0) and (fsize<5120) then begin
				p.loadfromfile(fname);s:=uppercase(copy(p.text,1,100));p.clear;
				if (pos('<!DOCTYPE HTML PUBLIC',s)>0) or (pos('<HTML>',s)>0) then
				begin
					DeleteFiles(fname);
					EB1.add('失败'+CR);
					continue;
				end;
			end;
      EB1.add(' 成功 '+format('[%d.%d KB]',[fsize div 1024, (fsize mod 1024)*10 div 1024])+CR);
			Result:= true;
    end;
  end;
end;
//Result:= true;
end;

				
				
function GetFtpFile (hSession:HInternet; ftpsite: String{;const proxy:string}):bool;
var hConnect: HINTERNET;
    s,ftp_host,ftp_dir,ftp_usr,ftp_pwd:string;
    i,fsize: Integer;
	b:boolean;
begin
Result := false;ftp_pwd:='' ;
if Pos('ftp://',ftpsite)=1 then delete(ftpsite,1,6) else Exit;
if Pos('@',ftpsite)>0 then ftp_pwd:=S_Before('@' , ftpsite) else ftp_pwd:='anonymous:a@a.a' ;
ftp_usr:=S_Before(':' ,ftp_pwd);
ftp_host:=S_Before('/',ftpsite);ftp_dir:=ftpsite;

try
  EB1.add('正在连接 '+ftp_site+' ... ');W.processmessages;
  hConnect:= InternetConnect(hSession,PChar(ftp_host),21,PChar(ftp_usr),PChar(ftp_pwd),INTERNET_SERVICE_FTP,0,100);
  if hConnect=nil then begin;EB1.add('失败'+CR);Exit;end;
  if not FtpSetCurrentDirectory(hConnect, PChar(ftp_dir)) then begin;EB1.add('失败'+CR);Exit;end;
  EB1.add('成功'+CR);
  for i:=0 to LB1.Count-1 do
  begin
    if (LB1.ItemSelected[i]) and (LB1.Items[i]<>'') then
    begin;
      EB1.add('正在下载 '+ftp_site+LB1.Items[i]+' ... ');
      sendmessage(EB1.handle, WM_VSCROLL, SB_BOTTOM, 0);
      W.processmessages;
	  b:=ThreadGetFile(hConnect,LB1.Items[i],FileNameExt(LB1.Items[i]),'');
//      if not FtpGetFile(hConnect,PChar(LB1.Items[i]), File_Name(LB1.Items[i]),                        False,File_Attribute_Normal,Ftp_Transfer_Type_Binary, 0) then
	  if not b then
        EB1.add('失败'+CR)
      else begin
        fsize := FileSize(File_Name(LB1.Items[i]));
        EB1.add('成功 '+format('[%d.%d KB]',[fsize div 1024, (fsize mod 1024)*10 div 1024])+CR);
      end;
    end;
  end;
  Result:=b;//Result:= true;
finally
  InternetCloseHandle(hConnect);
end;
end;


procedure ParseCmdline;
var s,flag:string;
begin;
if ParamCount=0 then begin;Exit;end;
pkgname:=ParamStr(1);
if pkg.IndexOf_NoCase(ExtractFileName(pkgname))<0 then exit;
if ParamStr(2)='/q' then Halt(1);
showmessage('宏包'+pkgname+'可能已经安装,点击[确定]可以从网上查找更新的宏包文件。');
end;

procedure CheckTPM;
var s0,s1,s2,url,server:string;
begin;
s0:=pkgname+'.tpm';
EB1.add('开始到 CTAN 网上搜索 '+s0+'（将根据该文件智能选择宏包文件），请等待 ... ');W.processmessages;
url:=ctan_tpm+s0;
server:= trim(CB2.Text);
if Pos('/',ctan_tpm)=1 then url:=server+url;
EB1.add(CR+url+' ');W.processmessages;
p.Clear;
if not GetInetFile(url,p) then begin;EB1.add('失败'+CR);exit;end;
s_tpm:=p.Text; s_files:='';
if not (Pos('<!DOCTYPE rdf:RDF',s_tpm)=1) then begin;EB1.add('失败'+CR);exit;end;
EB1.add('成功'+CR);
s0:=s_tpm;
S_Before('<TPM:RunFiles ',s0);
S_Before('>',s0);
s_files:=S_Before('</TPM:RunFiles>',s0);
s_files:=LowerCase(s_files);
end;

function IsSelected(f:string):boolean;
var ext,sname:string;
begin;
Result:=false;
sname:=StrRScan(PChar(f),'/');
ext:=ExtractFileExt(f);
if ext='.tpm' then Exit;

if Pos(sname,s_files)>0 then Result:=true;
if Length(s_files)>0 then Exit;

if ((Pos('/'+pkgname+'/',f)>0) or (Pos('/'+pkgname+'.',f)>0)) and (Length(ext)>0) then
    Result:=(Pos(ext+'.',extlist)>0);
end;

function GetFamilyTFM(tfm:string):string;
var s,s0:string;fn:Pchar;b:boolean;i:integer;
begin;

//[mhb] 06/29/09 : to fix a bug on finding tfm file; reported by user
i:=Pos('.tfm',tfm);
if i>0 then Result:=Copy(tfm,1,i-1) else Result:=tfm;

tfm:='/tfm/'+tfm;
p.Clear;
EB1.add(CR+'开始到 CTAN 网上搜索 '+tfm+'，请等待 ... ');W.processmessages;
EB1.add(CR+ctan_find+tfm);W.processmessages;
b:=GetInetFile(ctan_find+tfm,p);
if (not b) or (pos('<!DOCTYPE html',p.Text)<=0) then
  begin;
    EB1.add('失败'+CR);EB1.add('在网上搜索失败，请检查您能否上网。');W.processmessages;Exit;
  end;
LB1.Clear;s:=p.Text;//showmessage(s);
if pos('Sorry;',s)>0 then Exit; //[mhb] 06/29/09 : CTAN has changed the sorry message
S_Before(pre_beg,s);s:=S_Before(pre_end,s);
s:=S_Before(tfm,s);//S_Before('>fonts/',s);
fn:=File_Name(s);
if Msg_OkCancel('发现字体文件 '+'*/'+fn+tfm+'，是否搜索并下载整个字体族['+fn+']?')=ID_OK then Result:=fn;
end;

function Search:bool;
var s0,s1,s2,ss,ext,url:string;zip_exists,zip_selected:boolean;
begin;
Result:=false;
if trim(CB1.Text) = '' then begin;Showmessage('请先输入要查找的宏包名称!');Setfocus(CB1.handle);Exit;End;
pkgname:=LowerCase(trim(CB1.Text));
ext:=ExtractFileExt(pkgname);//showmessage(ext);

//[mhb] added: Install a font family
if ext='.tfm' then
	begin;pkgname:=GetFamilyTFM(pkgname);CB1.Text:=pkgname;end;

if Pos(ext+'.','.sty.cls.')>0 then pkgname:=ExtractFileNameWOExt(pkgname);
EB1.clear;

//[mhb]03/06/12 added: to show proxy settings
if Length(http_proxy) > 0 then EB1.add('使用代理服务器'+http_proxy+CR);

if (searchtpm='1') and (Pos('.',pkgname)=0) then CheckTPM;//[mhb]: do not check TPM for filename
p.Clear;LB1.Clear;

if Pos(s_pattern,ctan_find)>0 then 
  url:=StrReplaceAll(ctan_find,s_pattern,pkgname)
else 
  url:=ctan_find+pkgname;
  
EB1.add('开始到 CTAN 网上搜索 '+pkgname+'，请等待 ... ');W.processmessages;
EB1.add(CR+url+' ');W.processmessages;

if (not GetInetFile(url,p)) 
//[mhb]03/06/12 commented: or (pos('<!DOCTYPE html',p.Text)<=0) 
then
  begin;
    EB1.add('失败'+CR);EB1.add('在网上搜索失败，请检查您能否上网。');W.processmessages;Exit;
  end;
s:=p.Text;//showmessage(s);
// if pos('Sorry; no matches found.',s)>0 then
if pos(' no ',s)>0 then
begin;
  EB1.add('失败'+CR);EB1.add('未找到任何关于宏包 '+pkgname+' 的文件，请确认宏包名称是否正确！');Exit;
end;
EB1.add('成功'+CR);
S_Before(pre_beg,s);s:=S_Before(pre_end,s);


//[mhb] added: select zip automatically
zip_exists:=(Pos('/'+pkgname+'.zip',s)>0);
zip_selected:=false;



repeat
  s0:=S_Before(a_beg,s);
  s1:=S_Before(a_mid,s);
  s2:=S_Before(a_end,s);
  if Pos('/',s2)=1 then 
    begin;
    LB1.Add(s2);
    if not zip_exists then LB1.ItemSelected[LB1.Count-1]:=IsSelected(LowerCase(s2))
    else if zip_exists and (not zip_selected) and (Pos('/'+pkgname+'.zip',s2)>0) then
        begin;LB1.ItemSelected[LB1.Count-1]:=true;zip_selected:=true;end
    else begin;LB1.ItemSelected[LB1.Count-1]:=false;end;
    end;
until s='';//[mhb] fix a bug: s0=''

EB1.add('可能的宏包文件已经为您自动选中，您可以按住 Ctrl 键调整选中的文件。'
+'选好需要下载的文件后，您可以点击按钮 2 下载这些文件到默认目录或您自选的目录。');
sendmessage(EB1.handle, WM_VSCROLL, SB_BOTTOM, 0);
W.processmessages;
Result:=true;
end;



function Download:bool;
const f_cmd = '_ftp_cmd.tmp';
var i, k: integer;
    dir, header, proxy: string;
    hSession: HINTERNET;
    useftp: bool;
begin;
Result:=false;
if LB1.Count < 1 then begin;showmessage('下载列表为空!');Exit;end;

ftp_site := trim(CB2.Text);
k := pos('://',ftp_site);
if (ftp_site='') or not( k in [4,5]) then
begin;showmessage('请选择下载服务器!');Setfocus(CB2.handle);Exit;end;
header := lowercase(copy(ftp_site,1,k-1));//showmessage(header);
if (header<>'ftp') and (header<>'http') then
  begin;showmessage('请选择正确的下载服务器!');Exit;end;

dir:=E1.Text;
if dir='' then begin;dir:={GetStartDir+'..\'+}workdir+ExtractFileNameWOext(CB1.Text);end;
if not ForceDirectories(dir) then
  begin;showmessage('不能创建本地目录：'+dir+'，请重新选择下载目录。');Exit;end;
ChDir(dir);

EB1.clear;W.processmessages;
if CopyTail(ftp_site,1)<>'/' then ftp_site:=ftp_site+'/';

useftp:= false;proxy:='';
if header='ftp' then
begin;
  if (Length(ftp_proxy)>1) then begin
    if (pos('ftp=',ftp_proxy)=1)or(pos('socks=',ftp_proxy)=1) then begin; useftp := true;end;
    if ftp_proxy='ie' then begin;//useftp := true;
      hSession := InternetOpen('Net_pkg', INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, INTERNET_FLAG_KEEP_CONNECTION);
    end else begin
      hSession := InternetOpen('Net_pkg', INTERNET_OPEN_TYPE_PROXY, pchar(ftp_proxy), nil, INTERNET_FLAG_KEEP_CONNECTION);//showmessage('ftp_proxy:'+ftp_proxy);
    end;
    proxy:=ftp_proxy;
  end else if (ftp_proxy='0')and(Length(http_proxy)>0) then begin
    if (pos('socks=',http_proxy)=1)or(pos('ftp=',http_proxy)=1) then begin; useftp := true;end;
    if http_proxy='ie' then begin
      hSession := InternetOpen('Net_pkg', INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, INTERNET_FLAG_KEEP_CONNECTION);
    end else begin
      hSession := InternetOpen('Net_pkg', INTERNET_OPEN_TYPE_PROXY, pchar(http_proxy), nil, INTERNET_FLAG_KEEP_CONNECTION);//showmessage('http_proxy1:'+http_proxy);
    end;
    proxy:=http_proxy;
  end else begin
    hSession := InternetOpen('Net_pkg', INTERNET_OPEN_TYPE_DIRECT, nil, nil, 0);//showmessage('noproxy');
    useftp := true;
  end;
end
else if header='http' then begin
  if (Length(http_proxy)>0) then begin;
    hSession := InternetOpen('Net_pkg', INTERNET_OPEN_TYPE_PROXY, pchar(http_proxy), nil, INTERNET_FLAG_KEEP_CONNECTION);
    proxy:=http_proxy;
  end else
    hSession := InternetOpen('Net_pkg',INTERNET_OPEN_TYPE_DIRECT, nil, nil, 0);
end;
if hSession=nil then begin;exit;end;
Th_Session:=hSession;	

try
  if useftp then begin;
    if not GetFtpFile(hSession,ftp_site{,proxy}) then begin;EB1.add('无法下载宏包文件!'+CR);Exit;end;
  end else begin;
    if not GetHttpFile(hSession,ftp_site,proxy) then begin;EB1.add('无法下载宏包文件!'+CR);Exit;end;
  end;
finally
  InternetCloseHandle(hSession);
end;

EB1.add('下载完毕。现在您可以点击按钮 3 安装该宏包到 MTeX 中。'+CR);
sendmessage(EB1.handle, WM_VSCROLL, SB_BOTTOM, 0);
Result:=true;
//W.StayOnTop:=false;
end;

procedure Install;
const f_bat='_install.bat';
var f_ins,s,cmd,dir:string;
begin;
cmd:=cmd_install;dir:=ExtractFileNameWOext(CB1.Text);
if Length(E1.Text)>0 then cmd:=cmd+CR+'except (*.bat) copy *.* %MTEX\texlocal\%1\'+CR;
StrSaveToFile(f_bat,cmd);//showmessage(cmd+CR+comspec+' '+f_bat+' '+CB1.Text);
Shell(comspec+' '+f_bat+' '+dir,SW_SHOW,true);
DeleteFile(f_bat);
EB1.clear;EB1.add('已完成宏包的安装！');
ChDir(GetStartDir);
end;

function Kwhich(f,e:string):string;
begin;
if Length(e)>0 then f:=ReplaceFileExt(f,e);
Result:=RunDos('kwhich.exe ' +f, true,true,SW_HIDE);
Result:=StrReplaceAll(Result,'/' , '\');
end;

procedure B0Click(Dummy:Pointer; Sender: PControl);
var s,t:string;i:integer;
const M=5;
const Ext:array[1..M] of string=('','.cls','.sty','.tex','.ini');
begin;
s:='' ;t:='' ;
LB1.Clear;
for i:=1 to M do
  begin;
  s:=Kwhich(CB1.Text,Ext[i]);
  if Length(s)>0 then begin;LB1.Add(s);t:=t+s+CR;end;
  end;
if LB1.Count=0 then ShowMessage('未能发现宏包或文件' + CB1.Text) else Text2Clipboard(t);
end;


procedure B1Click(Dummy:Pointer; Sender: PControl);
begin;
B2.enabled:=false;
B3.enabled:=false;
if Search then B2.enabled:=true;
end;

procedure CB1Change(Dummy:Pointer; Sender: PControl);
begin;
end;

//procedure CB2Change(Dummy:Pointer; Sender: PControl);
//begin;
//s:=CB2.Text;
//ftp_host:=S_Before('/',s);ftp_dir:=s;
//end;

procedure B2Click(Dummy:Pointer; Sender: PControl);
begin;
//B2.enabled:=false;
if T.Enabled then
	begin;
	T.Enabled:=false;
	Th_Downloaded:=false;
	Th.Terminate;
	Th.Destroy;
	InternetCloseHandle(Th_Session);
	end
else
	if Download then B3.enabled:=true;
end;

procedure B3Click(Dummy:Pointer; Sender: PControl);
begin;
B3.enabled:=false;
Install;
end;

procedure B4Click(Dummy:Pointer; Sender: PControl);
begin;
if odd.Execute then
  begin;E1.Text:=odd.Path;ChDir(E1.Text);end;
end;

procedure B5Click(Dummy:Pointer; Sender: PControl);
begin;
showmessage(usage);
end;

procedure B6Click(Dummy:Pointer; Sender: PControl);
var cmd:string;
begin
cmd:='notepad';
winexec(PChar(cmd+' '+f_ini),SW_SHOW);
MsgBox('编辑好配置文件后，请点击[确定]调入新的配置。',MB_OK or MB_SETFOREGROUND );
ReadIni;
end;

procedure CB1Keydown(Dummy:Pointer;Sender: PControl; var Key: Longint; Shift: DWORD );
begin
  if (Key = VK_RETURN) then
  begin
    B1.Click;
  end;
end;

{procedure B_MouseMove(dummy:Pointer;Sender: PControl;var Mouse: TMouseEventData);
var  R: Trect;s:string;P:TPoint;
begin
  if Sender=B1 then hint:='搜索宏包'
  else if Sender=B2 then begin;hint:='下载宏包';end
  else if Sender=B3 then begin;hint:='安装宏包';end
	else begin
		exit;
	end;
  TipVisible := True;
	if TipVisible then
  begin
	  GetCursorPos(P);
    SendMessage(TT,TTM_TRACKPOSITION,0, MAKELPARAM(P.x,p.y+20));
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

procedure B_MouseLeave(Dummy_Self: PObj; Sender: PControl;var Mouse: TMouseEventData);
var  R: Trect;s:string;P:TPoint;ti: TTOOLINFO ;
begin
  HideTipsWindow;
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
end;}

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

procedure ReadIni;
var s,LastSite:string;s_dir:array[0..255] of char;i:integer;
begin;
pkg.Clear;
//ftp_site:=GetIniStr(f_ini,'General','FTP',def_ftpsite);
//s:=GetIniStr(f_ini,'General','FTP',def_ftpsite);
//ftp_host:=S_Before('/',s);ftp_dir:=s;
extlist:=GetIniStr(f_ini,'General','Extensions',def_extlist)+'.';
pkglist:=GetIniStr(f_ini,'General','Packages',def_pkglist);
workdir:=GetIniStr(f_ini,'General','WorkDir',def_workdir);
workdir:=StrExpandEnv(workdir);
comspec:=GetIniStr(f_ini,'General','Comspec',def_comspec);
// extractcab:=GetIniStr(f_ini,'General','ExtractCab',def_extractcab);
// extractzip:=GetIniStr(f_ini,'General','ExtractZip',def_extractzip);
searchtpm :=GetIniStr(f_ini,'General','SearchTPM','1');
ctan_tpm :=GetIniStr(f_ini,'General','CTAN_TPM',def_ctan_tpm);
ctan_find :=GetIniStr(f_ini,'General','CTAN_Find',def_ctan_find);
cmd_install:=GetIniSec(f_ini,'Install');
if Length(cmd_install)<10 then cmd_install:=def_cmd_install;

http_proxy:=LowerCase(GetIniStr(f_ini,'ProxySettings','http_proxy',''));
HttpProxyUser:=GetIniStr(f_ini,'ProxySettings','username','');
HttpProxyPass:=GetIniStr(f_ini,'ProxySettings','Password','');
ftp_proxy:=LowerCase(GetIniStr(f_ini,'ProxySettings','ftp_proxy',''));
if Pos('ftp=',ftp_proxy)=1 then
  begin;Delete(ftp_proxy,1,4);ftp_proxy:='ftp=ftp://'+ftp_proxy;end;
if pos('http=',ftp_proxy)=1 then
  begin;Delete(ftp_proxy,1,5);ftp_proxy:='http://'+ftp_proxy;end;
if pos('http=',http_proxy)=1 then
  begin;Delete(http_proxy,1,5);http_proxy:='http://'+http_proxy;end;
ftps:=GetIniStr(f_ini,'General','FTP',def_ftpsite);
if IsInBIT then ftps:=bit_ctan_mirror;
ChDir(GetStartDir);
if FileExists(f_ftp) then ftps:=ftps+CR+StrLoadFromFile(f_ftp);
p.Text:=ftps;LastSite:=CB2.text;CB2.clear;for i:=0 to p.Count-1 do CB2.Add(p.Items[i]); p.clear;
if LastSite<>'' then CB2.text:=LastSite;
ChDir('..');
if FileExists(pkglist) then pkg.LoadFromFile(pkglist);
Chdir(GetStartDir);
end;

procedure T_Timer(Dummy: Pointer; Sender: PControl);
begin;
  W.ProcessMessages;
  PB1.Progress:=PB1.Progress+1;
  if PB1.Progress>=PB1.MaxProgress then PB1.Progress:=0;
end;

procedure WClose( Sender: PControl; var Accept: Boolean );
Var i: integer;
Begin;
  if Th<>nil then begin;Th.AutoFree:=true;Th.Terminate;end;
  Halt(0);
End;

procedure Init;{var i:integer;}
begin;
  p:=NewStrList;
  pkg:=NewStrList;
  f_ini:=GetEnv('ETC')+'\'+fn_ini;
  if not FileExists(f_ini) then f_ini:=GetStartDir+fn_ini;

  W := NewForm( nil, '中文MTeX套装 宏包下载/安装程序 [mhb & qhs]' );
  W.font.releasehandle;//[qhs]
  W.Font.AssignHandle(GetStockObject(DEFAULT_GUI_FONT));//[qhs]
  //W.Font.FontHeight:=12;
  W.style := W.style and not (WS_MAXIMIZEBOX or WS_THICKFRAME);
  if not JustOne(W,W.Caption) then Halt(0);
  CB1:=NewCombobox(W,[]).PlaceDown.SetSize(100,0).ResizeParent;
  CB1.color:=clWindow;CB1.DropDownCount:=40;
  B0:=NewButton(W,'0.?').PlaceRight.SetSize(40,0).ResizeParent;
  B1:=NewButton(W,'1.★').PlaceRight.SetSize(40,0).ResizeParent;
  B2:=NewButton(W,'2.↓').PlaceRight.SetSize(40,0).ResizeParent;B2.enabled:=false;
  B3:=NewButton(W,'3.◇').PlaceRight.SetSize(40,0).ResizeParent;B3.enabled:=false;
  CB2:=NewCombobox(W,[]).PlaceRight.SetSize(160,0).ResizeParent;
  CB2.color:=clWindow;CB2.DropDownCount:=40;
//  p.Text:=ftps;for i:=0 to p.Count-1 do CB2.Add(p.Items[i]);
  NewLabel(W,'  ==>').PlaceRight.SetSize(30,0).ResizeParent;
  E1:=NewEditbox(W,[]).PlaceRight.SetSize(50,0).ResizeParent;E1.color:=clWindow;
  B4:=NewButton(W,'...').PlaceRight.SetSize(20,0).ResizeParent;
  B5:=NewButton(W,' ? ').PlaceRight.SetSize(30,0).ResizeParent;
  B6:=NewButton(W,'配置').PlaceRight.SetSize(50,0).ResizeParent;
  LB1:=NewListbox(W,[loMultiSelect]).PlaceDown.SetSize(W.clientWidth,200).ResizeParent;
//  P1:=NewPanel(W,esLowered).PlaceDown.SetSize(W.clientWidth,60).ResizeParent;
//  L1:=NewWordWrapLabel(P1,usage).PlaceDown.SetSize(P1.Width,20{P1.Height - 2});
  PB1:=NewProgressBar(W).PlaceDown.SetSize(W.clientWidth,10).ResizeParent;
  EB1:=NewEditBox(W,[ eoMultiline, eoReadonly, eoNoHScroll ]).PlaceUnder.SetSize(W.clientWidth,80).ResizeParent;//EB1.color:=clWindow;
  EB1.add(usage);
//L2:=NewLabel(P1,'*').PlaceRight.Shift(-20,0).SetSize(15,0);
//  osd:=NewOpenSaveDialog('Select a file to open/save:','',[]);
  odd:=NewOpenDirDialog('请选择下载文件存放的文件夹（建议您点击[取消]使用默认位置！）:',[]);
//	TT:=CreateTooltipWindow(W.Handle,HInstance);
 { CreateTipsWindow; TipVisible := False;
	W.Onmessage := TOnMessage( MakeMethod(nil, @FormMessage));}
  CB1.OnChange := TOnEvent( MakeMethod( nil, @CB1Change ) );
	CB1.OnKeydown := TOnKey( MakeMethod( nil, @CB1Keydown ) );
//  CB2.OnChange := TOnEvent( MakeMethod( nil, @CB2Change ) );
  B0.OnClick := TOnEvent( MakeMethod( nil, @B0Click ) );
  B1.OnClick := TOnEvent( MakeMethod( nil, @B1Click ) );
  B2.OnClick := TOnEvent( MakeMethod( nil, @B2Click ) );
  B3.OnClick := TOnEvent( MakeMethod( nil, @B3Click ) );
  B4.OnClick := TOnEvent( MakeMethod( nil, @B4Click ) );
  B5.OnClick := TOnEvent( MakeMethod( nil, @B5Click ) );
  B6.OnClick := TOnEvent( MakeMethod( nil, @B6Click ) );
{	B1.OnMouseMove:=TOnMouse( MakeMethod( nil, @B_MouseMove ) );
  B2.OnMouseMove:=TOnMouse( MakeMethod( nil, @B_MouseMove ) );
  B3.OnMouseMove:=TOnMouse( MakeMethod( nil, @B_MouseMove ) );
	B1.OnMouseLeave:=TOnEvent( MakeMethod( nil, @B_MouseLeave ) );
	B2.OnMouseLeave:=TOnEvent( MakeMethod( nil, @B_MouseLeave ) );
	B3.OnMouseLeave:=TOnEvent( MakeMethod( nil, @B_MouseLeave ) );}
  T:=NewTimer(50);T.OnTimer := TOnEvent( MakeMethod( nil, @T_Timer ) );
  T.Enabled:=false;
  SetCenterOnScreen(W.handle);
  W.OnClose := TOnEventAccept(MakeMethod( Nil, @WClose ) );
  ReadIni;
  ParseCmdline;  CB1.Text:=pkgname;
end;

begin;
  Init;
  Run(W);
end.
