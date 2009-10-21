//{$APPTYPE CONSOLE}
uses windows,messages,kol,shellapi,koldde;
{$I w32.pas}

const 
	usage='Usage: DDE app_path dde_service dde_topic dde_command [true]'+CR
	+'Note: This command run specific DDE command. Option "true" indicates to wait for termination of DDE comand.'+CR;

var s:string;ddeconv:pddeclientconv;wait:boolean;p:PStrList;

procedure Help;
begin;
  msg_ok(usage);
  Halt(1);
end;

begin;

	//msgok(ParamStr(1));msgok(ParamStr(2));msgok(ParamStr(3));msgok(ParamStr(4));msgok(ParamStr(5));
	//halt(0);
	if ParamCount<3 then Help;
	ddeconv := NewDDEClientConv( nil );
    ddeconv.ServiceApplication :='';//ParamStr(1);

    ddeconv.ConnectMode := ddeAutomatic;
    ddeconv.DdeService  := ParamStr(2);
    ddeconv.DdeTopic    := ParamStr(3);
    ddeconv.FormatChars := True;
	if not ddeconv.OpenLink then Halt(1);
	
	s:=ParamStr(4);//msgok(s);
	wait:=ParamStr(5)='true';//wait:=true;
	//'[ForwardSearch("d:\mtex\demo\e-sample.pdf","d:\mtex\demo\e-sample.tex",100,0,0,1)]';
	try
	if Pos('@',s)<>1 then 
		ddeconv.ExecuteMacro(PChar(s),wait)
	else
		begin;Delete(s,1,1);//msgok(s);
		p:=NewStrList;p.LoadFromFile(s);//msgok(p.Text);
		ddeconv.ExecuteMacroLines(p,wait)
		end;
	finally
	//Sleep(2000);
	ddeconv.CloseLink;
	end;
		
end.