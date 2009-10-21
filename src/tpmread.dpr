{$APPTYPE CONSOLE}
uses windows,messages,kol,shellapi;
{$I w32.pas}

function Get_prop_TPM(s_tpm,prop:string):string;
var s:string;
begin;
	s:=StrBetween(s_tpm,'<TPM:'+prop,'</TPM:'+prop+'>');
	S_Before('>',s);
	s:=StrReplaceAll(s,CR,'');
	s:=StrReplaceAll(s,'"','');
	s:=StrReplaceAll(s,'&amp;','&');
	Result:='"'+s+'"';
end;

function Get_TPM_info(f:string):string;
var s:string;
begin;
	s:=StrLoadFromFile(f);
	Result:=Get_prop_TPM(s,'Name')+','+Get_prop_TPM(s,'Title')+','+Get_prop_TPM(s,'Description')+',';
end;



var s1,s2:string;i:integer;
begin;

	s1:=Get_TPM_info(ParamStr(1));
    if ParamCount>1 then 
		begin;
		s2:=StrLoadFromFile(ParamStr(2));
		StrSaveToFile(ParamStr(2),s2+CR+s1);
		end
	else
		writeln(s1);
end.