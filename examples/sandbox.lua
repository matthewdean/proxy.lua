local proxy = require('proxy')
local sandbox = {}

sandbox.run = function(source)
	local output = {}
	
	-- compile
	local f, err = loadstring(source, 'chunk')
	if not f then
		return { error = err, output = output }
	end
	
	-- create a copy of the current environment
	-- and use this as the sandbox environment
	-- if we don't create a copy, the user could change stuff
	-- e.g. loadstring = 5
	--local env = {}
	--for k,v in pairs(getfenv(0)) do
	--	env[k] = v
	--end
	
	--setmetatable(env,{__index=getfenv(0)})
	env = proxy(getfenv(0))
	-- problem: using same env as this will mean
	-- getfenv(0).loadstring = 5
	-- will cause problems
	setfenv(f, env)
	
	-- override print so we can get the output
	proxy.override(print, function(...)
		local t = {...}
		for i = 1, select('#', ...) do
			t[i] = tostring(t[i])
		end
		output[#output+1] = table.concat(t, ' ')
	end)
	
	-- loadstring normally gives the compiled function the environment of the caller
	-- which in this case would be bad, since it would be outside of the sandbox
	-- so we need to manually set the function's environment
	proxy.override(loadstring, function(s, chunkname)
		-- pcall is necessary because loadstring can error
		-- loadstring({}) throws an error
		local success, f, err = pcall(loadstring, s, chunkname)
		if not success then
			error(f, 2)
		end
		if not f then
			return nil, err
		end
		setfenv(f, env)
		return f
	end)
	
	-- execute
	local success, err = pcall(f)
	return { error = err, output = output }
end

return sandbox