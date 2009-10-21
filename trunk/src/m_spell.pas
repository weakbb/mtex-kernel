{$X+}
const maxn_ofs=10;maxn_userdict=20;
var 
	S_Dict:string;Ofs_user:DWord;
	dict_number:integer;
	P_Ind:PStrList;
	P_Sug:PStrList;
	dict_path:string;
	dict_file:string;//='D:\MTeX\WinEdt\Dict\English\eng_com.dic';
	userdict_file:string;//='D:\MTeX\WinEdt\Dict\English\centre.dic';
	userdicts:array[1..maxn_userdict] of string;
	index_level:integer;//=1;
	max_errors:integer;//=3;
	max_error_ratio:real;//=0.5;
	max_word_length:integer;//30  [mhb] 04/19/09
	max_lookups:integer;//=2000;
	max_suggestions:integer;//=24;
	check_uppercase:integer;//=0;
	check_ignore_case:integer;//=0
	keep_capital_initial:integer;//=0;
	in_file,out_file:string;
	ofs_table:array[1..maxn_ofs*2] of DWord;
	ofs_table_n:integer;
	debugging:integer;
	
function GetWord(ofs:DWord;var new_ofs:DWord):string;
begin;
	Result:='';
	while (Ord(S_Dict[ofs])<>13) and (Ord(S_Dict[ofs])<>10) and (ofs<=Length(S_Dict)) do
		begin;Result:=Result+S_Dict[ofs];Inc(ofs);end;
	while (S_Dict[ofs]=#13) or (S_Dict[ofs]=#10) do Inc(ofs);
	new_ofs:=ofs;
end;

function GetW(ofs:DWord):string;
var tmp:DWord;
begin;
	Result:=GetWord(ofs,tmp);
end;
	
function GetIndKey(s:string):string;
begin;
	Result:=Chr(Length(s)+32*dict_number)+Copy(s,1,index_level);
end;

function GetDictNumber(k:string):integer;
begin;
	Result:=Ord(k[1]) div 32;
end;
	
procedure AddInd(key:string;ofs:DWord);
begin;
	P_Ind.Add(key+'='+UInt2Str(ofs));
end;

function QFind(P:PStrList;const S: String; var Index: Integer): Boolean;
var
  L, H, I, C: Integer;
  k: String;
begin
  Result := FALSE;
  L := 0;
  H := P.Count - 1;
  while L <= H do
  begin
    I := (L + H) div 2;
	k:=P.Items[I];
    if check_ignore_case=1 then k:=LowerCase(k);
	//writeln(s:10,k:10,L:10,H:10,I:10);
	if S<k then C:=1
	else if S=k then C:=0
	else C:=-1;
    if C < 0 then L := I + 1 else
    begin
      H := I - 1;
      if C = 0 then
      begin
        Result := TRUE;
        L := I;
      end;
    end;
  end;
  Index := L;
end;


function FindInd(key:string;delta:integer):DWord;
var k,s:string;i:integer;
begin;
	// P_Ind.Find(key,i);
	QFind(P_Ind,key,i);
	s:=P_Ind.Items[i];
	k:=S_Before('=',s);//writeln(key:8,k:8,s:8);
	if k<>key then
		begin;
		s:=P_Ind.Items[i+delta];
		k:=S_Before('=',s);
		end;
	Result:=0;
	for i:=1 to length(s) do 
		Result:=Result*10+Ord(s[i])-Ord('0');
	// Result:=Str2Int(s);
end;
	
	

procedure LoadDict(dict:string);
begin;
	if dict='' then Exit;
	if not FileExists(dict) then Exit;
	S_Dict:=S_Dict+StrLoadFromFile(dict)+#13#10;
	if debugging>1 then msgok(dict);
end;

procedure ReadMainDict;
var s,s_ind,dict:string;p,p_Next:PChar;c:Char;ofs,new_ofs:DWord;i:integer;
begin;
	ChDir(GetStartDir);
	if (length(dict_path)>0) and DirectoryExists(dict_path) then ChDir(dict_path);
	P_Ind.Clear;
	S_Dict:='';
	LoadDict(dict_file);
	P_Ind.Sort(true);
	Ofs_user:=Length(S_Dict)+1;
	s_ind:='';ofs:=1;dict_number:=1;
	repeat
		s:=GetWord(ofs,new_ofs);
		s:=GetIndKey(s);
		if s<>s_ind then begin;AddInd(s,ofs);s_ind:=s;end;
		ofs:=new_ofs;
	until ofs>=Length(S_Dict);
end;

procedure ReadIni;forward;
		
procedure ReadUserDicts;
var s,s_ind,dict:string;p,p_Next:PChar;c:Char;ofs,new_ofs:DWord;i:integer;
begin;
	ReadIni;
	ChDir(GetStartDir);
	if (length(dict_path)>0) and DirectoryExists(dict_path) then ChDir(dict_path);
	if (Length(S_Dict)>0) and (Ofs_user>1) then
		SetLength(S_Dict,Ofs_user-1);

	for i:=1 to maxn_userdict do 
		LoadDict(userdicts[i]);
	LoadDict(userdict_file);
end;

procedure ReadDicts;
var s,s_ind,dict:string;p,p_Next:PChar;c:Char;ofs,new_ofs:DWord;i:integer;
begin;
	ReadMainDict;
	ReadUserDicts;
	if debugging>0 then 
		StrSaveToFile('c:\all.ind',P_Ind.Text);
	if debugging>1 then 
		StrSaveToFile('c:\all.dic',S_Dict);
end;

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

procedure ReadIni;
const f_ini:string='m_spell.ini';
var dir:string;p_ini:PStrList;i:integer;
begin;
	dir:=GetStartDir;
	Chdir(dir);
	dict_path:='';
	dict_file:='D:\MTeX\WinEdt\Dict\English\eng_com.dic';
	userdict_file:='D:\MTeX\WinEdt\Dict\English\centre.dic';
	index_level:=4;
	max_errors:=2;
	max_error_ratio:=0.45;
	max_word_length:=30;
	max_lookups:=6000;
	max_suggestions:=30;
	check_uppercase:=0;	
	keep_capital_initial:=0;
	in_file:='c:\m_spell.in';
	out_file:='c:\m_spell.out';
	debugging:=0;
	for i:=1 to maxn_userdict do userdicts[i]:='';
	if not FileExists(f_ini) then Exit;
	p_ini:=NewStrList;
	p_ini.LoadFromFile(f_ini);
	dict_path:=p_ini.Values['dict_path'];
	dict_file:=p_ini.Values['dict_file'];
	userdict_file:=p_ini.Values['userdict_file'];
	debugging:=Str2Int(p_ini.Values['debugging']);
	index_level:=Str2Int(p_ini.Values['index_level']);
	max_errors:=Str2Int(p_ini.Values['max_errors']);
	max_error_ratio:=Str2Double(p_ini.Values['max_error_ratio']);
	max_word_length:=Str2Int(p_ini.Values['max_word_length']);
	max_lookups:=Str2Int(p_ini.Values['max_lookups']);
	max_suggestions:=Str2Int(p_ini.Values['max_suggestions']);
	check_uppercase:=Str2Int(p_ini.Values['check_uppercase']);
	check_ignore_case:=Str2Int(p_ini.Values['check_ignore_case']);
	keep_capital_initial:=Str2Int(p_ini.Values['keep_capital_initial']);
	in_file:=p_ini.Values['in_file'];
	out_file:=p_ini.Values['out_file'];
	for i:=1 to maxn_userdict do 
		userdicts[i]:=p_ini.Values['userdict_'+Int2Str(i)];
	p_ini.Destroy;
end;		
		
		
	
procedure SpellCheckerInit;
begin;
	P_Ind:=NewStrList;P_Sug:=NewStrList;
	ReadIni;
	ReadDicts;		
end;
		
procedure SpellCheckerExit;
begin;
	S_Dict:='';
	P_Sug.Destroy;
	P_Ind.Destroy;
	DeleteFiles(in_file);
	DeleteFiles(out_file);
end;
	
function LookUpRange(w:string;ofs1,ofs2:DWord;var n:integer):boolean;
var ofs,new_ofs:DWord;s,s2,r:string;d,j,maxn:integer;
begin;
	Result:=true;ofs:=ofs1;maxn:=max_lookups;
	if (ofs2=0) and (ofs1>0) then begin;ofs2:=Length(S_Dict);maxn:=MAXINT;end;
	if debugging>0 then 
		msgok('Look up ['+w+'] from '+Int2Str(ofs1)+'['+GetW(ofs1)+'] to '+Int2Str(ofs2)+'['+GetW(ofs2)+']. Checked '+Int2Str(n)+' words.');
	while(ofs<ofs2) and (n<=maxn) do 
		begin;
		s:=GetWord(ofs,new_ofs);
		if check_ignore_case=1 then s2:=LowerCase(s) else s2:=s;
		Inc(n);
		ofs:=new_ofs;
		if s[1]<>'%' then 
			begin;
			d:=Word_Distance(w,s2);
			r:=Chr(d+Ord('0'))+s;
			if d=0 then begin;//writeln('Found!!!');
				Exit;end
			else if (d<=max_errors) and (d*1.0<=max(Length(w),5)*max_error_ratio) then 
				begin;
				if not P_Sug.Find(r,j) then 
					begin;P_Sug.Insert(j,r);//writeln(ofs:10,n:5,r:16);
				end;
				end;
			end;
		end;
	Result:=false;
end;

procedure GenOfsTable(key:string);
var i,j:integer;k,k2:string;a,b,old_a,old_b:DWord;
begin;
	for i:=1 to maxn_ofs*2 do ofs_table[i]:=0;
	ofs_table[1]:=Ofs_user;
	ofs_table[2]:=Length(S_Dict);
	
	j:=2;old_a:=0;old_b:=0;
	for i:=index_level+1 downto 0 do 
		begin;
		k:=Copy(key,1,i);
		a:=FindInd(k,-1);
		if i>0 then
			begin;
			k2:=k;
			k2[i]:=Chr(Ord(k2[i])+1);
			b:=FindInd(k2,0);
			end
		else
			b:=Ofs_user;
		if debugging>1 then 
			msgok('['+k+']:'+Int2Str(a)+','+Int2Str(b));
		if i>index_level then
			begin;
			Inc(j);ofs_table[j]:=a;
			Inc(j);ofs_table[j]:=b;
			end
		else
			begin;
			Inc(j);ofs_table[j]:=a;
			Inc(j);ofs_table[j]:=old_a;
			Inc(j);ofs_table[j]:=old_b;
			Inc(j);ofs_table[j]:=b;
			end;
		old_a:=a;old_b:=b;
		end;
	ofs_table_n:=j;
	if debugging>1 then
	 for i:=1 to j div 2 do 
		msgok(Int2Str(i)+':'+Int2Str(ofs_table[2*i-1])+','+Int2Str(ofs_table[2*i]));
end;

function LoCase(c:char):char;
var k:integer;
begin;
	Result:=c;
	if (c<'A') or (c>'Z') then Exit;
	Result:=Chr(Ord(c)+32);
end; 

function SpellCheckerLookUp(w:string):boolean;
var key,k,s,r,w0:string;n,i,d,j:integer;ofs1,ofs2:DWord;
begin;
	P_Sug.Clear;n:=0;Result:=true;j:=0;
	if w='' then Exit;
	if Length(w)>max_word_length then Exit;
	for i:=1 to Length(w) do 
		if Ord(w[i])>127 then Exit;
	if (check_uppercase=0) and (w=UpperCase(w)) then Exit;
	w0:=w;
	if (keep_capital_initial=1) and (w[1]=UpCase(w[1])) then 
		w[1]:=LoCase(w[1]);
	if check_ignore_case=1 then w:=LowerCase(w);
	key:=GetIndKey(w);
	GenOfsTable(key);
	
	for i:=1 to ofs_table_n div 2 do 
		begin;
		ofs1:=ofs_table[i*2-1];
		ofs2:=ofs_table[i*2];
		//writeln(i:10,ofs1:10,ofs2:10,n:10);
		if LookUpRange(w,ofs1,ofs2,n) then begin;P_Sug.Clear;Exit;end;
		end;
	
	// n:=0;
	// if LookUpRange(w,1,0,n) then begin;writeln('n=',n:10);P_Sug.Clear;Exit;end;
	// writeln('n=',n:10);
	
	Result:=false;
	P_Sug.Sort(true);
	for j:=0 to P_Sug.Count-1 do 
		begin;
		s:=P_Sug.Items[j];
		d:=Ord(s[1])-Ord('0');
		s:=Copy(s,2,Length(s)-1)+','+Int2Str(d);
		if (keep_capital_initial=1) and (w0[1]=UpCase(w0[1])) then
			s[1]:=UpCase(s[1]);
		P_Sug.Items[j]:=s;
		end;
	if debugging>0 then
		msgok(P_Sug.Text);
	if max_suggestions<P_Sug.Count then 
		for j:=P_Sug.Count-1 downto max_suggestions do
		P_Sug.Delete(j);

end;
		

procedure SpellCheckerSuggestions;
var w:string;
begin;
	if not FileExists(in_file) then Exit;
	P_Sug.LoadFromFile(in_file);
	w:=Trim(P_Sug.Items[0]);
	P_Sug.Clear;
	DeleteFiles(out_file);
	if SpellCheckerLookUp(w) then Exit;
	P_Sug.SaveToFile(out_file);
end;