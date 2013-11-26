local WrapperLookup = setmetatable({},{_mode='v'})
local ValueLookup = setmetatable({},{_mode='k'})
local HookLookup = {}

local userdataMT do
	local defaults = {
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
		__metatable = function() return 'The metatable is locked' end;
	}

	userdataMT = {}

	for method,default in pairs(mtHooks) do
		userdataMT[method] = function(...)
			local hooks = HookLookup[getfenv(2)]
			local func = hooks and hooks[method] or default
			return unpack( WrapValue{func(unpack( Unwrap{...} ))} )
		end
	end
end

local function UnwrapValue(wrapper)
	-- handles function and userdata
	local value = ValueLookup[wrapper]
	if value then
		return value
	end

	local type = type(wrapper)
	if type == 'table' then
		local value = {}
		for k,v in pairs(table) do
			value[UnwrapValue(k)] = UnwrapValue(v)
		end
		return value
	elseif type == 'function' then
		-- if function was not in ValueLookup, then it's probably a user-made
		-- function being newindex'd (i.e. Callback)
		local function value(...)
			local results = {ypcall(value,unpack(WrapValue{...}))}
			if results[1] then
				return unpack(UnwrapValue(results),2)
			else
				-- error
			end
		end

		WrapperLookup[value] = wrapper
		ValueLookup[wrapper] = value
		return value
	elseif type == 'userdata' then
		return nil
	else
		return wrapper
	end
end

local function WrapValue(value)
	local wrapper = WrapperLookup[value]
	if wrapper then
		return wrapper
	end

	local type = type(value)
	if type == 'table' then
		local wrapper = {}
		for k,v in pairs(table) do
			wrapper[WrapValue(k)] = WrapValue(v)
		end
		return wrapper
	elseif type == 'function' then
		local function wrapper(...)
			local results = {ypcall(value,unpack(UnwrapValue{...}))}
			if results[1] then
				return unpack(WrapValue(results),2)
			else
				-- error
			end
		end

		WrapperLookup[value] = wrapper
		ValueLookup[wrapper] = value
		return wrapper
	elseif type == 'userdata' then
		local wrapper = setmetable({},userdataMT)
		WrapperLookup[value] = wrapper
		ValueLookup[wrapper] = value
		return wrapper
	else
		return value
	end
end

local proxy = {}

function proxy.new(options)
	local env = options.environment or {}
	HookLookup[env] = options.metamethods
	return WrapValue(env)
end

return proxy
