-- Demonstrates the lua4nt functions to expand 4NT/TCC internal variables
-- or functions and to call internal commands (see TakeCmd.h for a list of
-- commands)

local function show(s)
	local fmt='%20s: %s'
	s='%'..s
	print(fmt:format(s,lua4nt.ExpandVariables(s)))
end

-- get current working directory and full day of week
show('_cwd')
show('_dowf')

-- get free space on c:
show('@diskfree[c:,kc]')

-- Lua calls itself via 4NT
show('@lua[math.pi*3*3]')

-- do a 'dir *.lua'
print('Result of calling Command: %d\n',lua4nt.Command('dir *.lua'))

-- do a 'dir *.lua', 2nd approach
print('Result of calling int_Cmd: %d\n',lua4nt.int_Cmd('Dir_Cmd','*.lua'))

