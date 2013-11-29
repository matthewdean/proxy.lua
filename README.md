proxy.lua
===================
* Intended for ROBLOX, which uses Lua 5.1 for its embedded scripting language
* Proxies access to tables, userdata, and functions. You can specify metamethods to override the default ones.
* Useful for sandboxing or extending an environment

Known Issues:
------------------
Errors thrown in user-supplied metamethods may be incorrect:

    local a = proxy.new(getfenv(0), {
        __call = function(f, ...) return f(...) end
    })
    Game()
    --> attempt to call local 'f' (a userdata value)
    
The solution is for the user to avoid supplying a custom metamethod unless necessary. For example, if he does not need to hook into userdata or tables being called, he should not supply the above metamethod.

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
    
    local env = proxy.new(getfenv(0), {
        __index == function(t, k)
            if isInstance(t[k]) then
                return nil
            end
            return t[k]
        end
    })
    
    setfenv(0, env)
    
    print(Game) --> nil
    print(Workspace) --> nil
    print(Instance.new('Part')) --> Part
