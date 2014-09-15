--[[
benefits of using local variables:
	- faster access
	- ensures that changes to the global environment will not affect this module
	- e.g. loadstring = nil
]]
local unpack = unpack
local type = type
local pairs = pairs
local setmetatable = setmetatable
local newproxy = newproxy
local getmetatable = getmetatable
local pcall = pcall
local error = error
local select = select
local tostring = tostring
local null = {}

--[[
echo used to strip stack information from error messages
local t = 5
t()
--> attempt to call local 't' (a number value)
echo(t)()
--> attempt to call a number value
credit to mniip for this hack
--]]
local function echo(...) 
	return ...
end

-- equivalent to Lua 5.2's table.pack
-- but we are in 5.1
local function pack(...) 
	return {n = select('#',...), ...}
end

local convertValue do

	-- takes a variadic list of arguments
	-- and it to the other "side"
	local convertValues = function(mt, from, to, ...)
		local results = pack(...)
		for i = 1, results.n do
			results[i] = convertValue(mt,from,to,results[i])
		end
		return unpack(results,1,results.n)
	end
	
	convertValue = function(mt, from, to, value)
		-- if there is already a wrapper, return it
		-- no point in making a new wrapper and it ensures consistency:
		-- assert(loadstring == loadstring)
		local result = to.lookup[value]
		if result then
			-- hack to get around lua's lack of meaningful nil
			if result == null then
				return nil
			else
				return result
			end
		end
		
		local type = type(value)
		if type == 'table' then
			result =  {}
			-- must be indexed before keys and values are converted
			-- otherwise stack overflow
			to.lookup[value] = result
			from.lookup[result] = value
			for key, value in pairs(value) do
				result[convertValue(mt,from,to,key)] = convertValue(mt,from,to,value)
			end
			if not from.trusted then
				-- any future changes by the user to the table
				-- will be picked up by the metatable and transferred to its partner
				setmetatable(value,mt)
			else
				setmetatable(result,mt)
			end
			return result
		elseif type == 'userdata' then
			-- create a userdata to serve as proxy for this one
			result = newproxy(true)
			local metatable = getmetatable(result)
			for event, metamethod in pairs(mt) do
				metatable[event] = metamethod
			end
			to.lookup[value] = result
			from.lookup[result] = value
			return result
		elseif type == 'function' then
			result = function(...)
				local results = pack(pcall(value,convertValues(mt,to,from,...)))
				if results[1] then
					return convertValues(mt,from,to,unpack(results,2,results.n))
				else
					error(results[2],2)
				end
			end
			-- unwrap arguments, call function, wrap arguments
			to.lookup[value] = result
			from.lookup[result] = value
			return result
		else
			-- numbers, strings, booleans, nil, and threads are returned as-is
			-- because they are harmless
			return value
		end
	end
end

-- TODO possibly echo more variables, not sure which ones need it
local default_metamethods = {
	__len       = function(a) return #echo(a) end;
	__unm       = function(a) return -echo(a) end;
	__add       = function(a, b) return echo(a) + echo(b) end;
	__sub       = function(a, b) return echo(a) - echo(b) end;
	__mul       = function(a, b) return echo(a) * echo(b) end;
	__div       = function(a, b) return echo(a) / echo(b) end;
	__mod       = function(a, b) return echo(a) % echo(b) end; -- can't use math.mod because it behaves differently
	__pow       = function(a, b) return echo(a) ^ echo(b) end;
	__lt        = function(a, b) return echo(a) < echo(b) end;
	__eq        = function(a, b) return echo(a) == echo(b) end;
	__le        = function(a, b) return echo(a) <= echo(b) end;
	__concat    = function(a, b) return echo(a) .. echo(b) end;
	__call      = function(f, ...) return echo(f)(...) end;
	__tostring  = tostring;
	__index     = function(t, k) return echo(t)[k] end;
	__newindex  = function(t, k, v) echo(t)[k] = v end;
	__metatable = getmetatable;
}

local proxy = {}

-- provide a custom implementation of a metamethod to override the default
function proxy:override(event, metamethod)
	self.metatable[event] = convertValue(self.metatable, self.trusted, self.untrusted, metamethod)
end

function proxy:get(obj)
	return convertValue(self.metatable, self.trusted, self.untrusted, obj)
end

-- whenever the untrusted sees the old value
-- it will be replaced with the new value
-- so replace(loadstring, nil) will prevent all access to loadstring
-- even pcall(loadstring, ...) will fail because loadstring will be nil
function proxy:replace(old, new)
	local wrapper
	if new == nil then
		wrapper = null
	else
		wrapper = convertValue(self.metatable, self.trusted, self.untrusted, new)
		self.trusted.lookup[wrapper] = new
	end
	self.untrusted.lookup[old] = wrapper
end

function proxy.new()
	local self = {}
	
	-- __mode metamethod allow wrappers to be garbage-collected
	self.trusted = {trusted = true,lookup = setmetatable({},{__mode='k'})}
	self.untrusted = {trusted = false,lookup = setmetatable({},{__mode='v'})}
	
	-- all objects need to share a common metatable
	-- so the metamethods will fire
	-- e.g. print(game == workspace), two different objects
	self.metatable = {}
	for event, metamethod in pairs(default_metamethods) do
		-- the metamethod will be fired on the wrapper class
		-- so we need to unwrap the arguments and wrap the return values
		self.metatable[event] = convertValue(self.metatable, self.trusted, self.untrusted, metamethod)
	end
	
	setmetatable(self, {__index = proxy, __call = proxy.get})
	return self
end

return proxy
