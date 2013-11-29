local convertValue do

	local convertValues = function(mt, from, to, ...)
		local results = {...}
		local n = select('#',...)
		for i = 1, n do
			results[i] = convertValue(mt,from,to,results[i])
		end
		return unpack(results,1,n)
	end
	
	local getReturnValues = function(...)
		return {...}, select('#', ...)
	end
	
	-- from = trusted
	-- to = untrusted

	convertValue = function(mt, from, to, value)
		local result = to.lookup[value]
		if result then
			return result
		end
		
		local type = type(value)
		if type == 'table' then
			result =  {}
			to.lookup[value] = result
			from.lookup[result] = value
			for key, value in pairs(value) do
				result[convertValue(mt,from,to,key)] = convertValue(mt,from,to,value)
			end
			if from.trusted == false then
				-- changes to the user-made table (from user side) will replicate
				-- to the "true" table which is given to the trusted side unwrapped
				setmetatable(value,mt)
			else
				-- being passed back to the user side
				-- so its a proxy table and changes will be replicated
				setmetatable(result,mt)
			end
			return result
		elseif type == 'userdata' then
			result = newproxy(true)
			local userdataMT = getmetatable(result)
			for method, func in pairs(mt) do
				userdataMT[method] = func
			end
			to.lookup[value] = result
			from.lookup[result] = value
			return result
		elseif type == 'function' then
			result = function(...)
				-- must wrap the function in an anonymous function to prevent
				-- ypcall(wait)
				local results, n = getReturnValues(ypcall(function(...) return value(...) end,convertValues(mt,from,to,...)))
				if results[1] then
					return convertValues(mt,to,from,unpack(results,2,n))
				else
					error(results[2],2)
				end
			end
			to.lookup[value] = result
			return result
		else
			return value
		end
	end
end

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

proxy.new = function(environment, hooks)

	local trusted = {trusted = true,lookup = {}}
	local untrusted = {trusted = false,lookup = {}}

	local mt = {}
	for method,default in pairs(defaultMetamethods) do
		mt[method] = convertValue(mt,untrusted,trusted, hooks[method] or default)
	end

	return convertValue(mt,trusted,untrusted,environment)
end

local env = proxy.new(getfenv(1), {
	__index = function(t,k) print(t,'indexed at',k) return t[k] end
})
env.print(env.Game.PlaceId)
local f = function(Game) print(Game.PlaceId) end
env.f = f
env.f(env.Game)
