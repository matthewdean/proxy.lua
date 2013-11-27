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
			return value
		elseif type == 'function' then
			-- if function was not in ValueLookup, then it's probably a user-made
			-- function being newindex'd (i.e. Callback)
			local function value(...)
				local results = {ypcall(value,wrapValues(...))}
				if results[1] then
					return unwrapValues(unpack(results,2))
				else
					-- error
				end
			end

			WrapperLookup[value] = wrapper
			ValueLookup[wrapper] = value
			return value
		elseif type == 'userdata' then
			-- fail; unwrap userdata == bad
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
				local results = {ypcall(value,unwrapValues(...))}
				if results[1] then
					return wrapValues(unpack(results,2))
				else
					-- error
				end
			end

			WrapperLookup[value] = wrapper
			ValueLookup[wrapper] = value
			return wrapper
		elseif type == 'table' or type == 'userdata' then
			local wrapper = setmetatable({},userdataMT)
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
