{$APPTYPE console}
uses windows,messages,kol,shellapi; {$I w32.pas}
const
	usage=
	'BMP2XPM v0.1 [by mathmhb]:This tool can convert bitmap file to XPM file.'+CR 
	+'Usage: BMP2XPM bmpfile [xpmfile] ==) Convert bitmap file to xpmfile.';
var Bmp:PBitmap;
	infile,outfile:string;
	L_Color,L_XPM:TStrList;
procedure ScanColors;var x,y,k:integer;c:string;
begin;
	L_Color.Clear;
	for y:=0 to Bmp.Height-1 do 
		for x:=0 to Bmp.Width-1 do 
			begin;
			c:=Int2Hex(Bmp.Canvas.Pixels[x,y],6);
			k:=L_Color.IndexOf(c);
			if k=-1 then L_Color.Add(c);
			end;
	L_Color.Sort(true);
end;

function ColorChar(k:integer):string;
begin;
	if k>93 then begin;Result:=ColorChar(k div 94)+ColorChar(k mod 94);Exit;end;
	Result:=Chr(k+32);
	if Result='"' then Result:=Chr(126)
	else if Result='\' then Result:=Chr(127);
end;
			
procedure MakeXPM;var x,y,k:integer;nam,ch,v:string;
begin;
	L_XPM.Clear;
	L_XPM.Add('/* XPM */');
	L_XPM.Add('static char *Bmp2XPM_'+ExtractFileNameWOext(outfile)+'[] = {');
	L_XPM.Add('/* width height num_colors chars_per_pixel */');
	L_XPM.Add('"   '+Int2Str(Bmp.Width)+'    '+Int2Str(Bmp.Height)+'        '
			+Int2Str(L_Color.Count)+'            '+Int2Str(L_Color.Count div 95+1)+'",');
	L_XPM.Add('/* colors */');
	for k:=0 to L_Color.Count-1 do 
		begin;
		nam:=L_Color.Items[k];
		ch:=ColorChar(k);
		L_XPM.Add('"'+ch+' c #'+nam+'",');
		end;
	L_XPM.Add('/* pixels */');
	for y:=0 to Bmp.Height-1 do 
		begin;
		v:='"';
		for x:=0 to Bmp.Width-1 do 
			v:=v+ColorChar(L_Color.IndexOf(Int2Hex(Bmp.Canvas.Pixels[x,y],6)));
		if y<Bmp.Height-1 then v:=v+'",' else v:=v+'"';
		L_XPM.Add(v);
		end;
	L_XPM.Add('};');
	//Writeln(L_XPM.Text);
	
end;
			
begin;
	if ParamCount=0 then begin;Writeln(usage);Halt(1);end;
	infile:=ParamStr(1);
	outfile:=ParamStr(2);
	if ParamCount=1 then outfile:=ChangeFileExt(infile,'.XPM');
	Bmp:=NewBitmap(0,0);
	Bmp.LoadFromFile(infile);
	ScanColors;//msgok(L_Color.Text);
	MakeXPM;
	L_XPM.SaveToFile(outfile);
end.