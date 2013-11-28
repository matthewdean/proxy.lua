proxy.lua
===================
* Intended for ROBLOX, which uses Lua 5.1 for its embedded scripting language
* Proxies access to tables, userdata, and functions. You can specify metamethods to override the default ones.
* Useful for sandboxing or extending an environment

Usage
------------------
    local proxy = require(script.Parent.Proxy
    
    local isInstance = function(value)
        if type(value) == 'userdata' then
                local success,out = pcall(Game.GetService, Game, value)
                return success and out == nil
        end
        return false
    end
    
    local env = proxy.new({
        environment = getfenv(0),
        metamethods = {
            __index == function(t, k)
                if isInstance(t[k]) then
                    return nil
                end
                return t[k]
            end
        }
    })
    
    setfenv(0, env)
    
    print(Game) --> nil
    print(Workspace) --> nil
    print(Instance.new('Part')) --> Part
