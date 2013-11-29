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
			if not from.trusted then
				setmetatable(value,mt)
			else
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
				local results, n = getReturnValues(ypcall(function(...) return value(...) end,convertValues(mt,to,from,...)))
				if results[1] then
					return convertValues(mt,from,to,unpack(results,2,n))
				else
					error(results[2],2)
				end
			end
			return result
		else
			return value
		end
	end
end

local proxy = {}

proxy.new = function(environment, hooks)

	local trusted = {trusted = true,lookup = {}}
	local untrusted = {trusted = false,lookup = {}}

	local mt = {}
	for method,func in pairs(hooks or {}) do
		mt[method] = convertValue(mt,trusted,untrusted,func)
	end

	return convertValue(mt,trusted,untrusted,environment)
end
