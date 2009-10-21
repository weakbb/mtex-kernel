//dcc32 -CC 
uses windows,messages,md5,kol,shellapi;{$I w32.pas}
const 
    usage='Usage: m-md5 file ==> Print md5sum of a file'; 
var m:MD5Digest;s:string;

procedure Help;
begin;
    writeln(usage);Halt(1);
end;

begin;
    if ParamCount=0 then Help;
    s:=StrLoadFromFile(ParamStr(1));
    if s='' then Halt(2);
    m:=MD5String(s);
    s:=MD5Print(m);
    writeln(s);
	Text2Clipboard(s);
    //ShowMessage(s);
end.

