--[[
Some definitions:

- user region : Code that is run by the user. Arbitrary and dangerous.
- proxy-thing region : Code that is run internally. Initial environment variables, roblox instances, etc
- wrap : To pass a value from the proxy-thing region to the user region.
- unwrap : To pass a value from the user region to the proxy-thing region.
- wrapped [value] : A value as it exists in the user region.
- unwrapped [value] : A value as it exists in the proxy-thing region.

Notes:

Values like functions and tables created in the user region are considered
wrapped, even though they technically don't have anything wrapped around them.
Consider the definitions.

]]

local defaultMetamethods = {
	__len       = function(a) return #a end;
	__unm       = function(a) return -a end;
	__add       = function(a, b) return a + b end;
	__sub       = function(a, b) return a - b end;
	__mul       = function(a, b) return a * b end;
	__div       = function(a, b) return a / b end;
	__mod       = function(a, b) return a % b end;
	__pow       = function(a, b) return a ^ b end;
	__lt        = function(a, b) return a < b end;
	__eq        = function(a, b) return a == b end;
	__le        = function(a, b) return a <= b end;
	__concat    = function(a, b) return a .. b end;
	__call      = function(f, ...) return f(...) end;
	__tostring  = function(a) return tostring(a) end;
	__index     = function(t, k) return t[k] end;
	__newindex  = function(t, k, v) t[k] = v end;
	__metatable = function(t) return getmetatable(t) end;
}

local proxy = {}

function proxy.new(options)
	local env = options.environment or {}
	local hooks = options.metamethods or {}

	local WrapperLookup = setmetatable({},{_mode='v'})
	local ValueLookup = setmetatable({},{_mode='k'})

	local userdataMT

	local WrapValue
	local UnwrapValue

	local function wrapValues(...)
		local args = {...}
		local n = select('#',...)
		for i = 1,n do
			args[i] = WrapValue(args[i])
		end
		return unpack(args,1,n)
	end

	local function unwrapValues(...)
		local args = {...}
		local n = select('#',...)
		for i = 1,n do
			args[i] = UnwrapValue(args[i])
		end
		return unpack(args,1,n)
	end

	local function getArgs(...)
		return {...},select('#',...)
	end

	function UnwrapValue(wrapper)
		-- handles function and userdata
		local value = ValueLookup[wrapper]
		if value then
			return value
		end

		local type = type(wrapper)
		if type == 'table' then
			-- assumes table is immutable
			local value = {}
			for k,v in pairs(wrapper) do
				value[UnwrapValue(k)] = UnwrapValue(v)
			end
			-- Table is not lookup'd; if the contents of the wrapped table
			-- change, then the unwrapped table would be outdated. CONFLICT!
			-- Will create a new unwrapped table each time the same wrapped
			-- table is passed. e.g. bad for setmetatable, rawset, etc. Q: Why
			-- can't we reference them? A: They are mutable. Q: Use
			-- metamethods? This would be in the user region. Q: Aren't there
			-- cases where functions wont invoke metamethods? A: Those
			-- functions would be wrapped, so they would be not-invoking
			-- unwrapped metamethods.
			return value
		elseif type == 'function' then
			-- if function was not in ValueLookup, then it's probably a user-made
			-- function being newindex'd (i.e. Callback)
			local function value(...)
				local results,n = getArgs(ypcall(value,wrapValues(...)))
				if results[1] then
					return unwrapValues(unpack(results,2,n))
				else
					-- ruh roh! UnwrapValue may be recursive, leading to wrong stack error level
					error(results[2],2)
				end
			end

			WrapperLookup[value] = wrapper
			ValueLookup[wrapper] = value
			return value
		elseif type == 'userdata' then
			error('unwrapped userdata',2)
		else
			return wrapper
		end
	end

	function WrapValue(value)
		local wrapper = WrapperLookup[value]
		if wrapper then
			return wrapper
		end

		local type = type(value)
		if type == 'function' then
			local function wrapper(...)
				local results,n = getArgs(ypcall(function(...) return value(...) end,unwrapValues(...)))
				-- anonymous function necessary because ypcall(C function) fails e.g. ypcall(wait)
				if results[1] then
					return wrapValues(unpack(results,2,n))
				else
					error(results[2],2)
				end
			end

			WrapperLookup[value] = wrapper
			ValueLookup[wrapper] = value
			return wrapper
		elseif type == 'table' or type == 'userdata' then
			-- we could use a table and do wrapper = setmetatable({},userdataMT)
			-- advantage is fewer metatables (less waste)
			-- but the __len metamethod wouldn't fire
			-- so if _G was {1,2,3}, #_G would be 0 which is unacceptable
			local wrapper = newproxy(true)
			local metatable = getmetatable(wrapper)
			for method, func in pairs(userdataMT) do
				metatable[method] = func
			end
			WrapperLookup[value] = wrapper
			ValueLookup[wrapper] = value
			return wrapper
		else
			return value
		end
	end

	userdataMT = {}
	for method,default in pairs(defaultMetamethods) do
		userdataMT[method] = function(...)
			local func = hooks[method] or default
			return wrapValues(func(unwrapValues(...)))
		end
	end

	return WrapValue(env)
end

return proxy
