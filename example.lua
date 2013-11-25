local ProxyEnvironment = require(script.Parent.ProxyEnvironment)

local function IsInstance(value)
	if type(value) == 'userdata' then
		local success,out = pcall(Game.GetService, Game, value)
		return success and out == nil
	end
	return false
end

local env = ProxyEnvironment.new {
	environment = getfenv(0),
	metamethods = {
		__index = function(t, k)
			if IsInstance(t) and t.ClassName == "DataModel" and k == "PlaceId" then
				return 1818
			end
			return t[k]
		end
	}
}

setfenv(function() print(Game.PlaceId) end, env)()
