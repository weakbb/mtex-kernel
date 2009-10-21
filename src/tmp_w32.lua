
m=20;
print('var')
print('\tp_func: pointer;')
print('\tF0: Function:DWord;stdcall;')
for n=1,m do 
	args='a1';
	for i=2,n do args=args..',a'..i; end
	print('\tF'..n..' :Function('..args..':DWord):DWord;stdcall;')
end

--[[
print('\nvar')
for n=0,m do 
	print('\tF'..n..' : Func'..n..';')
end
]]--

print('\nprocedure CallFunc;')
print('begin;')
print('\th:=LoadLibrary(PChar(dll));')
print('\tif h=0 then begin;quick:=true;Exit;end;')
print('\tp_func:=GetProcAddress(h,PChar(f));')
print('\tif p_func=nil then begin;quick:=true;Exit;end;')
print('\tcase Length(e) of')
for n=0,m do
	print('\t'..n..':')
	print('\t\tbegin;')
	print('\t\tF'..n..":=p_func;")
	if n==0 then 
		args=''
	else
		args='(A[1]'
		for i=2,n do args=args..',A['..i..']';end
		args=args..')'
	end
	print('\t\tret:=F'..n..args..';')
	print('\t\tend;')
end
print('\tend;')
print('\tFreeLibrary(h);')
print('end;')
	
