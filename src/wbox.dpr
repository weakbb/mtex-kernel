{
v0.66: 使用系统默认字体
v0.65: 修改默认字体与颜色；状态栏？
v0.60: 增加uncheck功能方便清除前面的选择或恢复默认选择
v0.55: 支持通过语言文件修改字体大小及属性
v0.50:多语言支持，可通过语言文件修改界面语言；对于列表控件增加select=all设置；
v0.45:自动居中；总在最上；支持环境变量替换,类似$(MTEX)。
v0.40: XP风格美化;修正直接点击关闭按钮出错的bug（直接退出，不保存对话框设置）。
v0.35: add option 'env' to help load saved value
}

{$D USE_DROPDOWNCOUNT}{$D SMALLEST_CODE}{$R MTeX.res}
uses windows,messages,kol,xptheme,shellapi;

Var App,W,p: PControl;h_dos:THandle;
  args,opts,olddir,sel: string;
  data,labels,wb: PStrList;
  types: array[0..500] Of char;
  Dlg1:TOpenSaveDialog;Dlg2:TOpenDirDialog;
  b:array[0..500] of boolean;
{$I w32.pas}

const
	C_Button=0;
	C_Label=1;
	C_RadioBox=2;
	C_CheckBox=3;
	C_EditBox=4;
	C_MemoBox=5;
	C_ListBox=6;
	C_ComboBox=7;
	C_GroupBox=8;
	C_Form=9;
	C_BitBtn=10;
	C_WordWrapLabel=11;
	C_RichEdit=12;
	C_Start=14;

Procedure MyHalt(i:integer);
begin;
  //if (h_dos<>0) then SendMessage(h_dos, WM_SYSCOMMAND, SC_RESTORE, 0 );
  Halt(i);
end;

Function ScanW: string;

Var i,j,t: integer;
  s,f,n: string;
Begin;
  Result := '';
  For i:=0 To W.ChildCount-1 Do
    With W.Children[i]^ Do
      Begin;
        t := Ord(types[i])-1;
        f := '';
        Case t Of
          C_Button,C_BitBtn: If Focused Then s := '1'
                Else s := '0';
          C_RadioBox,C_CheckBox: If Checked Then s := '1'
               Else s := '0';
          C_EditBox,C_ComboBox: begin;s := Text;end;
          C_MemoBox:
             Begin;
               s := Items[0]+CR+'_'+labels.Items[i]+'='+Format('%d',[Count]);
               f := Text;
             End;
          C_ListBox:
             Begin;
               s := Items[CurIndex]+CR+'_'+labels.Items[i]+'=';
               For j:=0 To Count-1 Do
                 If ItemSelected[j] Then
                   Begin;
                     s := s+Format('%d ',[j+1]);
                     f := f+Items[j]+CR;
                   End;
             End;
          C_RichEdit: f := Text;
        End;
        if not (t=C_Label) and not (t=C_WordWrapLabel) and (labels.Items[i]<>'') 
			then Result := Result+labels.Items[i]+'='+s+CR;
        If f<>'' Then
          Begin;
            n := StrBetween(opts,labels.Items[i]+'.save=',CR);
            If n='' Then n := 'wbox.sav';
            StrSaveToFile(n,f);
          End;
      End;
End;

procedure WClose( Sender: PControl; var Accept: Boolean );
Var i: integer;
Begin;
  ChDir(olddir);
  MyHalt(0);
End;
	

		
Procedure Click(Dummy:Pointer; Sender: PControl);
Var i: integer;
Begin;
  ChDir(olddir);
  StrSaveToFile('wbox.lst',ScanW);
  i := Sender.TabOrder;
  MyHalt(i);
End;

Procedure Click_UnCheck(Dummy:Pointer; Sender: PControl);
Var i: integer;
Begin;
  for i:=0 to Sender.TabOrder-2 do 
	  W.Children[i].Checked:=b[i] and (not Sender.Checked);
End;

procedure Open1_Click(Dummy:Pointer; Sender: PControl);
var p:PControl;
begin
Dlg1.OpenDialog:=true;
p:=PControl(Sender.CustomObj);
if p=nil then exit;
W.Visible:=false;
if Dlg1.Execute then p.Text:=Dlg1.Filename;
W.Visible:=true;
end;

procedure Save1_Click(Dummy:Pointer; Sender: PControl);
var p:PControl;
begin
Dlg1.OpenDialog:=false;
p:=PControl(Sender.CustomObj);
if p=nil then exit;
W.Visible:=false;
if Dlg1.Execute then p.Text:=Dlg1.Filename;
W.Visible:=true;
end;

procedure Opendir1_Click(Dummy:Pointer; Sender: PControl);
var p:PControl;
begin
p:=PControl(Sender.CustomObj);
if p=nil then exit;
W.Visible:=false;
if Dlg2.Execute then p.Text:=Dlg2.Path;
W.Visible:=true;
end;




Const 
  StyleCount = 2;
  StyleNames: array[1..StyleCount] Of string = ('BORDER','CAPTION');
  Styles: array[1..StyleCount] Of DWord = (WS_BORDER,WS_CAPTION);

Function Str2Style(s:String): DWord;

Var i: integer;
Begin;
  Result := 0;
  For i:=1 To StyleCount Do
    If Pos(StyleNames[i]+' ',s+' ')>0 Then Result := Result+Styles[i];
End;

Function Str2Color(s:String): TColor;
Begin;
  Result := Hex2Int(s);
End;

Procedure Help;
Begin;
  msgOK('WBOX v0.66 [mhb]—— 本工具帮助您快速建立Windows对话框。命令行：WBox wb文件名。 具体用法请参见配套文档。');
  MyHalt(0);
End;

procedure LoadRtf(p:PControl;s:string);
var Fmt: TRETextFormat;
begin;
  if not FileExists(s) then Exit;
  if LowerCase(FileExt(s))='.rtf' then
    Fmt:=reRTF
  else 
    Fmt:=reText;
  p.Re_LoadFromFile(s,Fmt,false);
end;


Procedure InitObjs;
Var lines,i,err,d,t: integer;
  s,opt,key,lab,env: string;
Begin;
  App := NewApplet('wbox');
  //App.IconLoad(0,'TeX_bmp');
  W := NewForm( App, 'wbox' );
  W.font.releasehandle;//[qhs]
  W.Font.AssignHandle(GetStockObject(DEFAULT_GUI_FONT));//[qhs]
  W.OnClose:=TOnEventAccept(MakeMethod( Nil, @WClose ) );
  //W.Icon:=App.Icon;//Load(0,'TeX_bmp');
  {with App.Font^ do begin;FontHeight:=12;FontName:='宋体';end;}
  Dlg1.Title:='请选择文件：';Dlg1.Filename:='*.*';
  Dlg2.Title:='请选择文件夹：';
  wb:=NewStrList;
  if ParamCount=0 then Help else wb.LoadFromFile(ParamStr(1));
  //args := GetArgs;
  data := NewStrList;
  labels := NewStrList;
  types := '';
  opts := '';
For lines:=0 to wb.Count do begin;
  args:=wb.Items[lines];args:=StrExpandEnv(args);
  while Length(args)>0 Do
  Begin;
    s := Parse(args,';');
    opt := ''; env:=''; sel:='';
    Str(W.ChildCount,lab);
    d := Pos(s[1],'/');
    If d>0 Then delete(s,1,1);
    t := Pos(s[1],'".*-=!@#&~$+:\');//msgok(Format('%d',[t]));
    If t>0 Then delete(s,1,1);
    If s[1]='{' Then
      Begin;
        delete(s,1,1);
        opt := Parse(s,'}');
      End;//msgok(s);
    Case t Of
      0: p := NewButton(W,s);
      1: p := NewLabel(W,s);{"}
      2: p := NewRadioBox(W,s);{.}
      3: p := NewCheckBox(W,s);{*}
      4: begin;p := NewEditBox(W,[]);p.Color:=clwhite;end;{-}
      5: begin;p := NewEditBox(W,[eoMultiline, eoNoHScroll, eoReadOnly]);p.Color:=clwhite;end;{=}
      6: p := NewListBox(W,[]);{!}
      7: begin;p := NewComboBox(W,[]);p.DropDownCount:=20;p.Color:=clwhite;{[qhs]}end; {@}
      8: p := NewGroupBox(W,s);{#}
      9: p := NewForm(W,s);{&}
      10: p := NewBitBtn(W,s,[],glyphLeft,0,0);{~}
      11: p := NewWordWrapLabel(W,s);{ $}
      12:
          Begin;
            p := NewRichEdit(W,[eoNoHScroll, eoReadOnly]);
			LoadRTF(p,s);
          End;{+}
      14:;{\}
    End;
	
    lab := Trim(s);
    If (t<13) Then 
      begin;
	  b[W.ChildCount-1]:=false;
      types[W.ChildCount-1] := Chr(t+1);
      If d=0 Then p.PlaceRight Else p.PlaceDown;
      end;

    If (t=0) Or (t=10) Then p.OnClick := TOnEvent( MakeMethod( Nil, @Click ) );
    while Length(opt)>0 Do
    Begin;
      s := Parse(opt,',');
      key := Parse(s,'=');
      Val(s,i,err);//msgok(Format('[%s:%s,%d]',[key,s,i]));
      If      key='Title' Then W.Caption := s
      Else If key='StayOnTop' Then W.StayOnTop := (s='1')
      Else If key='CanResize' Then W.CanResize := (s='1')

      //else if key='Modal' then W.Modal:=(s='1')
      Else If (key='Maximized') And (s='1') Then W.WindowState := wsMaximized
	  Else If (key='wordwrap') Then p.WordWrap:=(s='1')
      Else If (key='checked') Then 
        begin; b[p.TabOrder-1]:=true;
        if t=3 then p.Checked:=true else if t=2 then begin;p.SetRadioChecked;end;
		end
	  Else If key='uncheck' Then
		begin;p.OnClick := TOnEvent( MakeMethod( Nil, @Click_UnCheck ));end
      Else If key='w' Then p.SetSize(i,0)
      Else If key='h' Then p.SetSize(0,i)
      Else If key='dx' Then p.Shift(i,0)
      Else If key='dy' Then p.Shift(0,i)
      Else If key='env' Then env:=GetEnv(s)
      Else If key='f' Then p.Font^.FontName := s
      Else If key='fh' Then p.Font^.FontHeight := i
      Else If key='fw' Then p.Font^.FontWidth := i
      Else If key='fs' Then
             Begin;
               If Pos('b',s)>0 Then p.Font^.FontStyle := p.Font^.FontStyle+[fsBold]
               Else If Pos('i',s)>0 Then p.Font^.FontStyle := p.Font^.FontStyle+[fsItalic]
               Else If Pos('u',s)>0 Then p.Font^.FontStyle := p.Font^.FontStyle+[
                                                              fsUnderline]
               Else If Pos('s',s)>0 Then p.Font^.FontStyle := p.Font^.FontStyle+[
                                                              fsStrikeOut];
             End
      Else If key='@' Then
		if t=C_RichEdit then
			LoadRtf(p,s)
		else
             Begin;
               data.LoadFromFile(s);			   
               For i:=0 To data.Count-1 Do
                 if t=C_MemoBox then
					p.Add(data.Items[i]+CR)
				 else
					p.Add(data.Items[i]); 
             End
      Else If key='files' Then p.AddDirList(s,0)
      Else If key='label' Then lab := s
      Else If key='aleft' Then p.AlignLeft(W.Children[labels.IndexOf(s)])
      Else If key='atop' Then p.AlignTop(W.Children[labels.IndexOf(s)])
      Else If key='color' Then p.Color := Str2Color(s)
      Else If key='style' Then p.Style := Str2Style(s)
	  Else If key='select' then sel:=s
                                          //else if key='exec' then p.Color:=
      Else If key='save' Then opts := opts+CR+lab+'.save='+s
      Else If key='exec' Then opts := opts+CR+lab+'.exec='+s
      Else If key='openfiledlg' then 
        begin;p.CustomObj:=W.Children[labels.IndexOf(s)];p.OnClick := TOnEvent( MakeMethod( Nil, @Open1_Click ) );end
      Else If key='savefiledlg' then 
        begin;p.CustomObj:=W.Children[labels.IndexOf(s)];p.OnClick := TOnEvent( MakeMethod( Nil, @Save1_Click ) );end
      Else If key='opendirdlg' then 
        begin;p.CustomObj:=W.Children[labels.IndexOf(s)];p.OnClick := TOnEvent( MakeMethod( Nil, @Opendir1_Click ) );end
//      Else If key='savedirdlg' then 
//        begin;p.CustomObj:=W.Children[labels.IndexOf(s)];p.OnClick := TOnEvent( MakeMethod( Nil, @Savedir1_Click ) );end

                                      //else if key='color' then p.Color:=
      Else If s='' Then p.Add(key);
    End;
    //msgOK(labels.Items[W.ChildCount-1]);
    if t<13 then p.ResizeParent;
    //msgOK(args);	

    if t<13 then labels.Add(lab);
    if Length(env)>0 then 
      begin;
      if (t=3) then p.Checked:=true
      else if (t=2) then p.SetRadioChecked
      else p.Text:=env;
      end;
	if sel='all' then 
	  for i:=0 to p.Count-1 do p.ItemSelected[i]:=true
	else if Length(sel)>0 then
		p.ItemSelected[Str2Int(sel)]:=true;
  End;
end;
End;


Begin;
  h_dos:=Find_W('TEX-DOS');
  if (h_dos=0) then h_dos:=Find_W('4NT Prompt');
  if (h_dos<>0) then SendMessage(h_dos, WM_SYSCOMMAND, SC_MINIMIZE, 0 );
  olddir:=GetWorkDir;
  InitObjs;
  W.StayOnTop:=true;
  W.Left:=(ScreenWidth-W.Width) div 2;W.Top:=(ScreenHeight-W.Height) div 2;
  Run(App);
End.
