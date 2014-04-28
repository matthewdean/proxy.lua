--[[
	issues:
		sandboxed print does not use global environment's tostring?
]]

--[[
	using local variables, in addition to the performance benefits,
	ensures that changes to the global environment will not affect this module
	e.g. loadstring = nil
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

local function echo(...) -- credit to mniip
	return ...
end

local function pack(...) -- equivalent to Lua 5.2's table.pack
	return {n = select('#',...), ...}
end

local convertValue do

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
				local results = pack(pcall(convertValues,mt,to,from,...))
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
	__mod       = function(a, b) return echo(a) % echo(b) end; -- or math.mod
	__pow       = function(a, b) return echo(a) ^ echo(b) end; -- or math.pow
	__lt        = function(a, b) return echo(a) < echo(b) end;
	__eq        = function(a, b) return echo(a) == echo(b) end;
	__le        = function(a, b) return echo(a) <= echo(b) end;
	__concat    = function(a, b) return echo(a) .. echo(b) end;
	__call      = function(f, ...) return echo(f)(...) end;
	__tostring  = function(a) return '__tostring' end;--return tostring(a) end; -- or tostring
	__index     = function(t, k) return echo(t)[k] end;
	__newindex  = function(t, k, v) echo(t)[k] = v end;
	__metatable = function(t) return getmetatable(t) end; -- or getmetatable
}

local proxy = {}

function proxy.new()

	local self = {}
	-- __mode metamethod allow wrappers to be garbage-collected
	self.trusted = {trusted = true,lookup = setmetatable({},{__mode='k'})}
	self.untrusted = {trusted = false,lookup = setmetatable({},{__mode='v'})}
	
	self.metatable = {}
	for event, metamethod in pairs(default_metamethods) do
		-- the metamethod will be fired on the wrapper class
		-- so we need to unwrap the arguments and wrap the return values
		self.metatable[event] = convertValue(self.metatable, self.trusted, self.untrusted, metamethod)
	end
	
	setmetatable(self, {
		__index = proxy,
		__call = function(self, value)
			return convertValue(self.metatable, self.trusted, self.untrusted, value)
		end
	})
	
	return self
end

function proxy:override(real, fake)
	if fake == nil then
		self.untrusted.lookup[real] = null
	elseif type(real) == 'string' then
		local event = real
		self.metatable[event] = convertValue(self.metatable, self.trusted, self.untrusted, fake)
	else
		self.trusted.lookup[fake] = fake
		self.untrusted.lookup[real] = fake
	end
end

return proxy
