-- test
function test(x)
	print('test',x)
	if x>0 then test(x-1) end
end

print('Hello, world')
print('in test1')
test(5)
