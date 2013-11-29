proxy.lua
===================
* Intended for ROBLOX, which uses Lua 5.1 for its embedded scripting language
* Proxies access to tables, userdata, and functions. You can specify metamethods to override the default ones.
* Useful for sandboxing or extending an environment

Example
------------------
    local proxy = require(script.Parent.Proxy)
    local env = proxy.new(getfenv(1), {
        __index=function(t,k)
            print(t,'indexed at',k)
            return t[k]
        end
    }))
    setfenv(1,env)
    print(Game.PlaceId)
    --> table: 0B0DE4A8 indexed at print
    --> table: 0B0DE4A8 indexed at Game
    --> Game indexed at PlaceId
    --> 0

Known Issues:
------------------
Errors thrown in user-supplied metamethods may be incorrect:

    local a = proxy.new(getfenv(0), {
        __call = function(f, ...) return f(...) end
    })
    Game()
    --> attempt to call local 'f' (a userdata value)
    
The solution is for the user to avoid supplying a custom metamethod unless necessary. For example, if he does not need to hook into userdata or tables being called, he should not supply the above metamethod.
