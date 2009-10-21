{$APPTYPE Console}
uses windows,messages,kol,shellapi;{$I w32.pas}
//{$I m_spell.pas}

procedure SpellCheckerInit; stdcall; far; external 'm_spell_dll.dll';
procedure SpellCheckerExit; stdcall; far; external 'm_spell_dll.dll';
procedure SpellCheckerDialog; stdcall; far; external 'm_spell_dll.dll';
procedure SpellCheckerSuggestions; stdcall; far; external 'm_spell_dll.dll';

{
var F,CB1,EB1,B1,B2,B3,B4:PControl;
var	s:string;i:integer;w:string;

procedure B_Click(Dummy:Pointer; Sender: PControl);
begin;
StrSaveToFile('c:\m_spell.out',CB1.Text+CR+Int2Str(Sender.TabOrder)+':'+Sender.Text);
F.Close;
//F.Perform(WM_QUIT,0,0);
end;


procedure SpellDialog;var i:integer;
begin;
	F:=NewForm(nil,'Mini Spell Checker').SetSize(200,50);
	F.StayOnTop:=true;
	F.Style:=F.Style and not (WS_MAXIMIZEBOX or WS_SIZEBOX);
	EB1:=NewEditBox(F,[eoReadOnly]).SetSize(140,0);
	EB1.Color:=clBlue;EB1.TabStop:=false;
	B1:=NewButton(F,'Ignore').PlaceRight.SetSize(100,0);
	B2:=NewButton(F,'Replace').PlaceRight.SetSize(100,0);
	CB1:=NewComboBox(F,[]).PlaceDown.SetSize(140,0);
	B3:=NewButton(F,'Add').PlaceRight.SetSize(100,0);
	B4:=NewButton(F,'Abort').PlaceRight.SetSize(100,0).ResizeParent;
	B1.OnClick:=TOnEvent( MakeMethod( nil, @B_Click ) );
	B2.OnClick:=TOnEvent( MakeMethod( nil, @B_Click ) );
	B3.OnClick:=TOnEvent( MakeMethod( nil, @B_Click ) );
	B4.OnClick:=TOnEvent( MakeMethod( nil, @B_Click ) );
	CB1.Clear;EB1.Text:=w;
	for i:=0 to P_Sug.Count-1 do CB1.Add(P_Sug.Items[i]);
	F.Show;CB1.Focused:=true;
	CB1.Perform(CB_SHOWDROPDOWN,1,0);
	Run(F);
	F.Close;
end;
}

function Word_Distance(s1,s2:string):integer;
var T:array[0..30] of array[0..30] of integer;i,j,m,n,c:integer;
begin;
	m:=Length(s1);n:=Length(s2);
	for i:=0 to m do for j:=0 to n do T[i][j]:=0;
    for i:=0 to m do T[i][0]:=i;
	for j:=0 to n do T[0][j]:=j;
    for i := 1 to m do
      for j := 1 to n do
		begin;
		if s1[i]=s2[j] then c:=0 else c:=1;
        T[i][j]:=min(T[i-1][j-1]+c,T[i][j-1]+1);
		T[i][j]:=min(T[i][j],T[i-1][j]+1);
		end;
	Result:=T[m][n];
end;


const 
	in_file='c:\m_spell.in';
	out_file='c:\m_spell.out';

var w,w2:string;p:PStrList;
begin;
	
	SpellCheckerInit;
	p:=NewStrList;
	repeat
		write('??');readln(w);
		if Pos(',',w)>0 then
			begin;
			w2:=S_Before(',',w);
			writeln(w:20,w2:20,Word_Distance(w,w2):10);
			end
		else
		if Length(w)>0 then 
			begin;
			StrSaveToFile(in_file,w);
			StrSaveToFile(out_file,'');
			// SpellCheckerDialog;
			SpellCheckerSuggestions;
			p.LoadFromFile(out_file);
			writeln(p.Items[0]);
			writeln(p.Items[1]);
			writeln(p.Items[2]);
			//msgok('xxx');
			end;
	until Length(w)=0;
	
	SpellCheckerExit;

end.