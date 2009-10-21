{$APPTYPE CONSOLE}
uses windows,messages,kol,shellapi;
{$I w32.pas}

var s:string;d:DWord;SFI: TShFileInfo;d1,d2:Word;
begin;
	s:=ParamStr(1);
	d:=SHGetFileInfo( PChar(s),FILE_ATTRIBUTE_NORMAL,SFI,0,SHGFI_EXETYPE );
	d1:=LoWord(d);
	d2:=HiWord(d);
	if (d1=$5A4D) and (d2=0) then s:='Dos'
	else if (d1=$454E) then
		if (d2=0) then s:='Win16Console' else s:='Win16'
	else if (d1=$4550) then
		if (d2=0) then s:='Win32Console' else s:='Win32'
	else s:='Unknown';
	writeln(s);
	writeln(Int2Hex(d1,4),':',Int2Hex(d2,4));
end.