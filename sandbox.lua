local proxy = require(script.Parent.Proxy)
local sandbox = {}

function sandbox.run(source, options)

	options = options or {}

	local result = {}
	result.output = {}
	
	local function print(...)
		local t = {...}
		for i = 1, select('#', ...) do
			t[i] = tostring(t[i])
		end
		table.insert(result.output, table.concat(t, ' '))
	end
	
	local f, err = loadstring(source, "chunk")
	if f == nil then
		result.success = false
		result.error = err
		return result
	end
	
	local _ENV = options.environment
	_ENV = setmetatable({print=print}, {__index=options.environment})
	setfenv(f, proxy.new(_ENV))
	
	local success, err = ypcall(f)
	result.success = success
	if not success then
		result.error = err
		if err == "Game script timout" then
			wait() --FIXME hack
		end
	end
	return result
end

return sandbox
