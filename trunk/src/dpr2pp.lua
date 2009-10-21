local n=0
local r={}
local res,myres
local vars
local inits
function replace_delphi_str(s)
	local m,b,ch
	if string.find(s,'lnkfile') then print(s);end
	if string.find(s,'begin%A') then return;end
	if string.find(s,'end%A') then return;end
	if string.find(s,'var%A') then return;end
	if string.find(s,'function%A') then return;end
	if string.find(s,'procedure%A') then return;end
	
	print('---',s)
	m=string.len(s)
	ch=0
	xx=''
	for i=1,m do 
	  b=string.byte(s,i,i)
	  xx=xx..' '..b
	  if b>127 then ch=1;break;end
	end
	if ch==0 then return s;end
	
	for i,v in ipairs(r) do
		if r[i]==s then return 'MyRes_['..(i)..']';end
	end
	n=n+1
	r[n]=s	
	res=res..'MyRes_['..(n)..']:='..s..';\n'
	s=string.gsub(s,"^'","")
	s=string.gsub(s,"'$","")
	myres=myres..s..'\n'
	return 'MyRes_['..(n)..']'
end
function replace_const_str(s)
	if string.find(s,'then') then return s;end
-- 	ch=0
-- 	m=string.len(s)
-- 	xx=''
-- 	for i=1,m do 
-- 	  b=string.byte(s,i,i)
-- 	  xx=xx..' '..b
-- 	  if b>127 then ch=1;break;end
-- 	end
-- 	if ch==0 then return s;end
	
	local s0,s1,s2
	_,_,s0,s1,s2=string.find(s,'([%p%s\t])(%w[%w_]-)%s*=%s*(.+);')
	vars=vars..'\t'..s1..': string;\n'
	inits=inits..'\t'..s1..' := '..s2..';\n'
	print(s1)
	return s0
end
function add_resource_string(s)
	--print(s)
	return s..'\n'..res
end
function add_init_string(s)
	--print(s)
	return s..';_Init_Strings;'
end

function file_name(s)
	for w in string.gmatch(s,'\\([%w_%-]+)%.') do return w;end
end

function f_write(file,s,mode)
	if not mode then mode='w';end
	local f=io.open(file,mode)
	if not f then return;end
	if type(s)=='table' then s=table.concat(s,'\n');end
	f:write(s)
	f:close()
	return s
end


function collect_strings(prog)
	local f1=io.input(prog)
	s=io.read('*a')
	io.close(f1)
	local prog_new=string.gsub(prog,'dpr','pp')
	print(prog,'==>',prog_new)
	n=0
	vars='MyRes_:array[1..1024] of string;\n'
	res='';myres=''
 	inits='procedure _Read_Strings(f:string);var i:integer;S:PStrList;\n'
 	inits=inits..'\tbegin;\n'
	inits=inits..'\tS:=NewStrList;\n'
	inits=inits..'\tS.LoadFromFile(f);\n'
	inits=inits..'\tfor i:=1 to S.Count do MyRes_[i]:=S.Items[i-1];\n' 
	inits=inits..'\tend;\n'
	inits=inits..'procedure _Init_Strings;var f_:string;\n\tbegin;\n'
	inits=inits..'\t{$I '..string.gsub(prog,'%.dpr','%.r')..'}\n'
	inits=inits.."\tf_:=ReplaceFileExt(ParamStr(0),'.'+GetMTeXLang);\n"
	inits=inits.."\tif not FileExists(f_) then f_:=ReplaceFileExt(ParamStr(0),'.0');\n"
	inits=inits..'\tif FileExists(f_) then _Read_Strings(f_);\n'
	local f2=io.output(prog_new,'wb')
-- 	rep=string.gsub(s,"('.-')%)",replace_delphi_str) 
--   string.gsub("ad'xxx'{ddd}asasddf","'[^\n]-'",function (s) print(s);return s;end)

	rep=string.gsub(s,"'[^\n]-'",replace_delphi_str)
	rep=string.gsub(rep,"[%p%s\t]%w[%w_]-%s*=[%s]*MyRes_[%w+'%s_{}%[%]\n\r]-;",replace_const_str)
	--rep=string.gsub(rep,"%s*DefTex2ps=.-;",replace_const_str)
	rep=string.gsub(rep,"%s*usage=.-;",replace_const_str)
	rep=string.gsub(rep,"%s*help=.-;",replace_const_str)
	inits=inits..'\tend;'
	if vars~='' then 
		vars='var\n'..vars
	end
	print(res)
	f_write(string.gsub(prog,'%.dpr','%.r'),res..'\n','w')
	f_write(string.gsub(prog,'%.dpr','%.936'),myres,'w')
	res=vars..inits..'\n'
	--print(vars,'*****',inits)
	res2=string.gsub(rep,'{%$I%s+w32%.pas}',add_resource_string)
	if not string.find(rep,'{%$I%s+w32%.pas}') then
	res2=string.gsub(rep,'(uses .-;)',add_resource_string)
	end
	res2=string.gsub(res2,'(resourcestring)%s*procedure','procedure')
	res2=string.gsub(res2,'(const)[%s]*{','{')
	res2=string.gsub(res2,'(const)[%s]*var%s','var ')
	res2=string.gsub(res2,'(const)[%s]*begin[%s%p]','begin;')
	res2=string.gsub(res2,'(const)[%s]*function%s','function ')
	res2=string.gsub(res2,'(const)[%s]*procedure%s','procedure ')
	res3=string.gsub(res2,'(%s[Ee]nd;[\t\n%s]*[bB]egin)',add_init_string)
	io.write(res3)
	io.close(f2)
	
	--print(res)
end

function change_enrfiles(v)
	local prog_name=file_name(v)
	local f1=io.input('res/'..prog_name..'.en.r')
	if not f1 then return;end
	s=io.read('*a')
	io.close(f1)
	if not s then return;end
	s=string.gsub(s,'resourcestring\n','')
	s=string.gsub(s,"\tRes_%d-='","")
	s=string.gsub(s,"';","")
	print(s)
	f_write(prog_name..'.0',s,'w')
end

if table.getn(arg)>0 then collect_strings(arg[1]); end

--[[
files=scite_Files('h:\\prog\\mtex\\tex-bmp.dpr')
for _,v in ipairs(files) do 
	print('---',v)
	collect_strings(v)
-- 	change_enrfiles(v)
end
]]
