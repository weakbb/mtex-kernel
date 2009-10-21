{$APPTYPE CONSOLE}
uses windows,messages,kol,shellapi;
{$I w32.pas}

var s,fn:string;f:Text;p:TStrList;
begin;
	fn:=GetEnv('MSGLOG_FILE');
	if Length(fn)=0 then fn:='MSGLOG.LOG';
	//assign(f,fn);append(f);
	p.Text:=GetArgs;
	writeln(p.Text);
	p.AppendToFile(fn);
	//writeln(f,s);
end.