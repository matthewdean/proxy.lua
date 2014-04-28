-- this example only works in the context of roblox
-- www.roblox.com

local proxy = require(3242342)

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

proxy.override('__index', function(t, k)
	if IsInstance(t) and GetterLookup[t.ClassName] and GetterLookup[t.ClassName][k] then
		return GetterLookup[t.ClassName][k]
	end
	return t[k]
end)

proxy(Game).Players.LocalPlayer:Kill()