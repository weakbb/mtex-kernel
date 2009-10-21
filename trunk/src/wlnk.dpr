{
v0.35: fix detection of "~~"
v0.30: add detection of delim "~~"
}
uses windows,messages,kol,shlobj,ShellAPI, ActiveX;{$I w32.pas}

const N=5;

var 
d:string;
Param:array[1..N] of string;
ParamCnt:integer;
const usage='本工具用于创建快捷方式。[mhb & qhs] v0.35'+CR+'格式：WLnk lnkfile exefile [args workdir iconfile icon_no]'+CR
	+'您可以在lnkfile中指定 $SendTo,$Desktop,$Startup,$Fonts,$Programs等路径。';

const
{$IFNDEF VER130}
  CLSID_ShellLink: TGUID  = '{00021401-0000-0000-C000-000000000046}';
  IID_IShellLink: TGUID   = '{000214EE-0000-0000-C000-000000000046}';
{$ENDIF}
  IID_IPersistFile: TGUID = '{0000010B-0000-0000-C000-000000000046}';

function CreateLinkDesc( const FileName,Arguments,WorkDir,IconFile:String;
                              IconNumber:integer;LinkName:String; 
                              Description:String): Boolean;
var
  Psl      : IShellLink;
  Ppf      : IPersistFile;                  
  sFileName: string;                        
  wFileName: array[0..MAX_PATH] of WideChar;
begin
Result := TRUE;
CoInitialize(nil);
if CoCreateInstance(CLSID_ShellLink, nil, CLSCTX_INPROC_SERVER, IID_IShellLinkA, Psl) <> S_OK then Exit;
  
  Psl.SetPath(PChar(FileName));
  Psl.SetArguments(PChar(Arguments));
  Psl.SetWorkingDirectory(PChar(WorkDir));
  Psl.SetIconLocation(PChar(IconFile),IconNumber);
  Psl.SetDescription(PChar(Description));

//  Psl.SetHotkey(HOTKEY.HOTKEY);
//  Psl.SetShowCmd(WindowStates[TWindowState(cbxWindowStates.ItemIndex)]);

//  if Failed(Psl.QueryInterface(IID_IPersistFile, Ppf)) then
//    raise Exception.Create('Error in query interface');
if Psl.QueryInterface(IID_IPersistFile, Ppf) <> S_OK then Exit;
//msgok(ExtractFilePath(LinkName));
  if not DirectoryExists(ExtractFilePath(LinkName)) then
    CreateDir( ExtractFilePath(LinkName) );

  if ExtractFileExt(LinkName) <> '.lnk' then
    LinkName := LinkName + '.lnk';

  sFileName := LinkName;

  MultiByteToWideChar(CP_ACP, 0, PChar(sFileName), -1, wFileName, MAX_PATH);
  if Ppf.Save(wFileName, true)<> S_OK then Exit;
  CoUninitialize;
end;

procedure SetParams;
var i,k:integer;s:string;
begin;
  for i:=1 to N do Param[i]:='';
  for i:=1 to N do
    begin;
    s:=ParamStr(i);
    k:=Pos('~~',s);
    if k<1 then Param[i]:=s
    else begin;Param[i]:=Copy(s,1,k-1);Exit;end;
    end;
end;

begin
SetParams;
//for i:=1 to 5 do msgok(ParamStr(i));
d:=ExpandDir(Param[1]);//msgok(d);
if length(Param[2])>0 then
  CreateLinkDesc( Param[2], Param[3],Param[4],Param[5], 0, d,'')
else
  MsgOK(usage);
end.