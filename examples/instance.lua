local proxy = require(script.Parent.Proxy)

local function IsInstance(value)
	if type(value) == 'userdata' then
		local success,out = pcall(Game.GetService, Game, value)
		return success and out == nil
	end
	return false
end

local GetterLookup = {
	Player = {
		Kill = function(player)
			if player.Character and player.Character:FindFirstChild("Humanoid") then
				player.Character:BreakJoints()
			end
		end,
	}
}

local env = proxy.new({
	environment = getfenv(0),
	metamethods = {
		__index = function(t, k)
			if IsInstance(t) and GetterLookup[t.ClassName] and GetterLookup[t.ClassName][k] then
				return GetterLookup[t.ClassName][k]
			end
			return t[k]
		end
	}
})

-- keep in mind that upvalues will leak to this function
setfenv(function() Game.Players.LocalPlayer:Kill() end, env)()
