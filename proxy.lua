local proxy do

	proxy = {}

	local WeakMode = {
		Key = {__mode = "k"},
		Value = {__mode = "v"},
		KeyValue = {__mode = "kv"}
	}
	
	local WrapperLookup = setmetatable({}, WeakMode.Value)
	local DataLookup = setmetatable({}, WeakMode.Key)
	local IsTrusted = setmetatable({}, WeakMode.Key)

	local Metamethods = {
		__len = function(a)
			return #a
		end,
		__unm = function(a)
			return -a
		end,
		__add = function(a, b)
			return a + b
		end,
		__sub = function(a, b)
			return a - b
		end,
		__mul = function(a, b)
			return a * b
		end,
		__div = function(a, b)
			return a / b
		end,
		__mod = function(a, b)
			return a % b
		end,
		__pow = function(a, b)
			return a ^ b
		end,
		__lt = function (a, b)
			return a < b
		end,
		__eq = function (a, b)
			return a == b
		end,
		__le = function (a, b)
			return a <= b
		end,
		__concat = function(a, b)
			return a .. b
		end,
		__call = function(f, ...)
			return f(...)
		end,
		__tostring = function(a)
			return tostring(a)
		end,
		__index = function(t, k)
			return t[k]
		end,
		__newindex = function(t, k, v)
			t[k] = v
		end,
		__metatable = function(t)
			return getmetatable(t)
		end,
	}
	
	local WrapData
	
	local WrapReturnValues = function(func, returnValues)
		for i, value in pairs(returnValues) do
			
			-- if the return value has never been seen before
			-- it must be from the environment, trust it
			if IsTrusted[value] == nil then
				IsTrusted[value] = true
			end

			-- if the function was trusted, wrap the return values
			if IsTrusted[func] == true then
				returnValues[i] = WrapData(value)
			end
		end
	end
	
	local function UnwrapArguments(func, args)
		for i, arg in pairs(args) do
			
			-- if the argument has never been seen before
			-- it must be user-created
			if IsTrusted[arg] == nil then
				IsTrusted[arg] = false
			end

			-- only unwrap the argument if we trust the function
			if IsTrusted[func] == true then
				args[i] = DataLookup[arg] or arg
			end
		end
	end
	
	local WrapFunction = function(f)
		return function(...)
			local n = select("#", ...)
			local args = {...}
			UnwrapArguments(f, args)
			local results = { ypcall(function(...) return f(...) end, unpack(args, 1, n)) }
			local success = table.remove(results, 1)
			WrapReturnValues(f, results)
			if success then
				return unpack(results, 1, n)
			else
				error(results[1], 2)
			end
		end
	end
	
	local function SetMetamethod(index, metamethod)
		IsTrusted[metamethod] = true
		Metamethods[index] = WrapData(metamethod)
	end
	
	WrapData = function(data)
		local wrapper = WrapperLookup[data]
		if wrapper then
			return wrapper
		end
		if type(data) == "table" or type(data) == "userdata" then
			wrapper = setmetatable({}, Metamethods)
			DataLookup[wrapper] = data
			WrapperLookup[data] = wrapper
			return wrapper
		elseif type(data) == "function" then
			wrapper = WrapFunction(data)
			DataLookup[wrapper] = data
			WrapperLookup[data] = wrapper
			return wrapper
		else
			return data
		end
	end
	
	for index, metamethod in pairs(Metamethods) do
		SetMetamethod(index, metamethod)
	end
	
	proxy.new = function(options)
		local result = WrapData(options.environment)
		print('env has been wrapped')
		options.metamethods = options.metamethods or {}
		for index, metamethod in pairs(options.metamethods) do
			SetMetamethod(index, metamethod)
		end
		return result
	end
end

return proxy
