-- test
function test(x)
	print('test',x)
	if x>0 then test(x-1) end
end

print('Hello, world')
print('in utest1')
test(5)
