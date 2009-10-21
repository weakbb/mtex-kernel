{$APPTYPE CONSOLE}
uses windows,messages,kol,shellapi; {$I w32.pas}
var Bmp:PBitmap;
	w,h,bw,bh,bx,by,i,j,fh:integer;
	s,fn,opts:string;
	outfile,loadfile:string;
	fg,bg:TColor;
	fs:TFontStyle;
const 
	usage=
	'TEXT2BMP v0.1 [mathmhb]: 本工具用于以命令行方式把文字转成图片或图标文件。'+CR
	+'用法: TEXT2BMP 输出文件 {选项}待转换文本'+CR
	+'选项: w=宽度,h=高度,x=左边界,y=上边界,font=字体名,fontsize=字体大小,fg=前景颜色,bg=背景颜色,load=作为背景的图片文件'+CR
	+'注意: 必须以半角,分隔各选项；颜色以RRGGBB形式来指定.'+CR
	+'例子1: TEXT2BMP test.bmp MTEX'+CR
	+'例子2: TEXT2BMP test.bmp {w=32,h=32,x=5,y=4,font=Tahoma,fontsize=10,fg=0000FF,bg=FF0000}MTEX'+CR
	+'例子3: TEXT2BMP test.bmp {load=back.bmp}MTEX'+CR;
	
	
procedure SetArgs;var opt,val:string;
begin;
	if ParamCount<2 then begin;Writeln(usage);Halt(1);end;
	outfile:=ParamStr(1);
	bw:=32;bh:=32;bx:=-1;by:=-1;
	fn:='Tahoma';fh:=-10;fs:=[];
	fg:=clBlue;bg:=clGreen;
	s:=ParamStr(2);loadfile:='';
	if Pos('{',s)<>1 then Exit;
	Delete(s,1,1);
	opts:=S_Before('}',s);//msgok(opts);
	repeat
		val:=S_Before(',',opts);
		opt:=S_Before('=',val);
		//Writeln(opt,':',val);
		if opt='w' then bw:=Str2Int(val)
		else if opt='h' then bh:=Str2Int(val)	
		else if opt='x' then bx:=Str2Int(val)
		else if opt='y' then by:=Str2Int(val)
		else if opt='fontsize' then fh:=-Str2Int(val)
		else if opt='fg' then fg:=Hex2Int(val)
		else if opt='bg' then bg:=Hex2Int(val)
		else if opt='load' then loadfile:=(val)	
		else if opt='font' then fn:=(val)	
		else if opt='bold' then fs:=fs+[fsBold]	
		else if opt='italic' then fs:=fs+[fsItalic]	
		else if opt='underline' then fs:=fs+[fsUnderline]
		else if opt='strikeout' then fs:=fs+[fsStrikeOut];	
	until Length(opts)=0;
end;

begin;
	SetArgs;
	Bmp:=NewBitmap(bw,bh);
	Bmp.PixelFormat:=pf4bit;
	Bmp.BkColor:=clWhite;
	for i:=0 to bw-1 do 
		for j:=0 to bh-1 do 
			Bmp.Canvas.Pixels[i,j]:=clWhite;
	Bmp.Canvas.Font.Color:=fg;
	Bmp.Canvas.Font.FontHeight:=fh;
	Bmp.Canvas.Font.FontName:=fn;
	Bmp.Canvas.Font.FontStyle:=fs;	
	if Length(loadfile)>0 then Bmp.LoadFromFile(loadfile);
	w:=Bmp.Canvas.WTextWidth(s);
	h:=Bmp.Canvas.WTextHeight(s);
	if bx<0 then bx:=(bw-w+1) div 2;
	if by<0 then by:=(bh-h+1) div 2;
	Bmp.Canvas.WTextOut(bx,by,s);
	for i:=0 to bw-1 do 
		for j:=0 to bh-1 do 
			if Bmp.Canvas.Pixels[i,j]=clWhite then Bmp.Canvas.Pixels[i,j]:=bg;
	Bmp.SaveToFile(outfile);
	Writeln('Text "'+s+'"('+Int2Str(w)+'x'+Int2Str(h)+') has converted to bitmap file "'+outfile+'" ('+Int2Str(bw)+'x'+Int2Str(bh)+')!');
end.