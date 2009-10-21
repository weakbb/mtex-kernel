{$APPTYPE Console}
library m_spell;
uses windows,messages,kol,shellapi;{$I w32.pas}
{$I m_spell.pas}

{
var F,CB1,EB1,B1,B2,B3,B4,B5,B6:PControl;
var	s:string;i:integer;w:string;

procedure B_Click(Dummy:Pointer; Sender: PControl);
begin;
StrSaveToFile('c:\m_spell.out',CB1.Text+CR+Int2Str(Sender.TabOrder)+CR+'#'+Sender.Text);
F.Hide;
end;


procedure InitObjs;
begin;
	F:=NewForm(nil,'Mini Spell Checker').SetSize(200,50);
	F.StayOnTop:=true;
	F.Style:=F.Style and not (WS_MAXIMIZEBOX or WS_SIZEBOX);
	EB1:=NewEditBox(F,[eoReadOnly]).SetSize(140,0);
	EB1.Color:=clBlue;EB1.TabStop:=false;
	CB1:=NewComboBox(F,[]).PlaceDown.SetSize(140,0);
	CB1.DropDownCount:=30;
	B1:=NewButton(F,'Ignore').PlaceRight.AlignTop(EB1).SetSize(100,0);B1.Tag:=1;
	B2:=NewButton(F,'Ignore All').PlaceUnder.SetSize(100,0);B2.Tag:=2;
	B3:=NewButton(F,'Replace').PlaceRight.AlignTop(EB1).SetSize(100,0);B3.Tag:=3;
	B4:=NewButton(F,'Replace All').PlaceUnder.SetSize(100,0);B4.Tag:=4;
	B5:=NewButton(F,'Add').PlaceRight.AlignTop(EB1).SetSize(100,0);B5.Tag:=5;
	B6:=NewButton(F,'Abort').PlaceUnder.SetSize(100,0).ResizeParent;B6.Tag:=6;
	B1.OnClick:=TOnEvent( MakeMethod( nil, @B_Click ) );
	B2.OnClick:=TOnEvent( MakeMethod( nil, @B_Click ) );
	B3.OnClick:=TOnEvent( MakeMethod( nil, @B_Click ) );
	B4.OnClick:=TOnEvent( MakeMethod( nil, @B_Click ) );
	F.Hide;
end;

procedure SpellCheckerDialog;stdcall;var DlgWnd:THandle;s:string;
var i:integer;
begin;
	s:=StrLoadFromFile('c:\m_spell.in');
	w:=S_Before(CR,s);//msg_ok(w+Int2Str(Length(S_Dict)));
	if SpellCheckerLookUp(w) then Exit;
	if F=nil then InitObjs;
	CB1.Clear;EB1.Text:=w;
	for i:=0 to P_Sug.Count-1 do CB1.Add(P_Sug.Items[i]);
	CB1.Focused:=true;
	CB1.Perform(CB_SHOWDROPDOWN,1,0);
	F.ShowModal;
	while F.Visible do F.ProcessMessage;
end;

}

exports 
	SpellCheckerInit,
	SpellCheckerExit,
	SpellCheckerSuggestions,
	ReadMainDict,
	ReadUserDicts;
	// SpellCheckerLookUp,
	// SpellCheckerDialog;
	
begin;
	//F:=nil;
end.