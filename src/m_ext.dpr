library M_ext;//my mini lib to extend lua

uses windows,messages,kol,shellapi;{$I w32.pas}
// procedure SpellCheckerInit;export;
// procedure SpellCheckerExit;export;
// function SpellCheckerLookUp(w:string):boolean;export;

const 
	MExtTempIn='\MExtTemp.in';
	MExtTempOut='\MExtTemp.out';
	MAX_SIZE=5120;


var 
s,f,e,dll,v,dir:string;
p,res:TStrList;
A:array[1..20] of DWord;
n,ret:DWord;
h:HMODULE;
buf:array[0..MAX_SIZE] of char;
ptr: ^char;
quick:boolean;

{$I tmp_w32.pas}


// {$I m_spell.pas}

// procedure SpellCheck();
// var i:integer;
// begin;
	// res.Clear;
	// if Length(S_Dict)<20 then SpellCheckerInit;
	// if Length(p.Items[1])=0 then begin;msgok('xxx');SpellCheckerExit;Exit;end;
	// if not SpellCheckerLookUp(p.Items[1]) then res.Text:=P_Sug.Text;
// end;			




function bool2str(b:boolean):string;
begin;
	if b then Result:='1' else Result:='0';
end;

procedure ReadArgs;var i,j:integer;
begin;
	s:=StrLoadFromFile(dir+MExtTempIn);
	p.Clear;p.Text:=s;res.Clear;
	e:=S_Before(CR,s);
	dll:=S_Before(';',e);
	f:=S_Before('@',dll);
	quick:=f[1]='#';
	if quick then exit;
	//msg_ok('Func=' +f+CR+'Dll=' +dll+CR+'Extra=' +e+CR+CR+'A2=' +p.Items[2]+CR+'A3=' +p.Items[3]+CR+'Args=' +s);
	FillChar(buf,MAX_SIZE+1,#0);j:=0;
	for i:=1 to Length(e) do 
		begin;
		v:=p.Items[i];StrCopy(buf+j,PChar(v));n:=Str2Int(v);
		if e[i]='n' then A[i]:=n 
		else if e[i]='s' then A[i]:=DWord(buf+j)
		else if e[i]='b' then begin;if v='true' then A[i]:=1 else A[i]:=0;end
		else if e[i]='t' then begin;ptr:=AllocMem(n+1);A[i]:=DWord(ptr);end
		else if e[i]='*' then begin;ptr:=AllocMem(MAX_SIZE);FillChar(ptr,0,MAX_SIZE);A[i]:=DWord(ptr);end;
		j:=j+Length(v)+1;
		end;
end;

procedure WriteResults;var i,j:integer;data:string;
begin;
	if not quick then 
		begin;
		res.Add(Int2Str(ret));
		for i:=1 to Length(e) do 
			begin;
			v:=p.Items[i];n:=Str2Int(v);data:='';
			if e[i]='t' then 
				begin;
				ptr:=Pointer(A[i]);
				for j:=0 to n-1 do data:=data+Int2Str(Integer(PChar(ptr)[j]))+' ';
				res.Add(data);
				FreeMem(ptr);
				end
			else if e[i]='*' then 
				begin;
				ptr:=Pointer(A[i]);
				data:=StrPas(PChar(ptr));
				res.Add(data);
				FreeMem(ptr);
				end;
			end;
		end;
	res.SaveToFile(dir+MExtTempOut);
end;


			
procedure Perform(); const _CR=#255;
begin;
	if Length(dll)>0 then CallFunc
	else if f='winexec' then WinExec(buf,SW_SHOW)
	else if f='shellexec' then ShellExecute(0,'open',buf,'' ,'' ,SW_SHOW)
	else if f='msgbox' then MessageBox(0,buf,'',MB_OK)
	else if f='#WinExec' then 
		res.Text:=Int2Str(WinExec(PChar(p.Items[1]),Str2Int(p.Items[2]) ))
	else if f='#ShellExec' then 
		res.Text:=Int2Str(ShellExecute(0,'open',PChar(p.Items[1]),'' ,'' ,Str2Int(p.Items[2]) ))
	else if f='#DlgChoice' then 
		res.Text:=Int2Str(ShowQuestion2(StrReplaceAll(p.Items[1],_CR,CR),p.Items[2],p.Items[3]))
	else if f='#ShellRun' then 
		shell(p.Items[1],Str2Int(p.Items[2]),p.Items[3]='true')
	else if f='#ExecWait' then
		res.Text:=bool2str(ExecuteWait('',p.Items[1],'',Str2Int(p.Items[2]),INFINITE,nil))
	// else if f='#SpellCheck' then
		// SpellCheck;
	//msg_ok(f+CR+s);
end;

procedure DoFunc;export;
begin;
	ReadArgs;
	Perform;
	WriteResults;
end;



	
exports DoFunc;

begin;
	dir:=GetEnv('Temp');
	dir:=ExcludeTrailingChar(dir,'\');
	if Length(dir)=0 then dir:='c:';
end.