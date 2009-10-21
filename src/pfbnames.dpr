program pfbnames;{$APPTYPE CONSOLE}

uses   windows,messages,kol,shellapi;{$I w32.pas}

//var DirInfo: SearchRec;
var DirList:TDirList;

function getFontName (fn: string): string;
const separators = [' ', ^I, ^M, ^J];
var f: file of char;
	{ 'text' would sometimes interpret one of the first 6 binary 
	  (block header) bytes as EOF . On the other hand, 'file of char' 
	  is slow (stupid Turbo, probably not buffering file input other 
	  than 'text' (Does Turbo-7 remedy this?). Maybe 'file' with 
	  block operations should be used. }
    lasttoken: string;
    lastch: char;

    procedure getchar;
    begin
         if eof (f) then lastch := chr (0)
                    else read (f, lastch)
    end;

    procedure gettoken;
    begin
	while lastch in separators do getchar;
	if lastch = '/' then begin
		lasttoken := '/';
		getchar;
	end else lasttoken := '';
	while not eof (f) and not (lastch in separators + ['/']) do begin
		lasttoken := lasttoken + lastch;
		getchar;
	end;
    end;
begin
     assign (f, fn);
     reset (f);
     lastch := ' ';
     lasttoken := '';
     while not eof (f) and (lasttoken <> '/FontName')
	do gettoken;
     gettoken;
     getFontName := lasttoken;
     close (f)
end;

var i:integer;s:string;
begin
  if paramcount > 0 then s:=getFontName (paramstr (1))+#13#10
	  
  else begin
	 DirList.ScanDirectory('.', '*.pfb',FILE_ATTRIBUTE_NORMAL); s:='';
	 for i:=0 to DirList.Count-1 do 
		 s:=s+DirList.Names[i]+':'+getFontName (DirList.Names[i])+#13#10;
  end;
  write(s);Text2Clipboard(s);

end.
