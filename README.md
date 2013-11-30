proxy.lua
===================
Control access to objects through metatables in RBX.Lua.

Usage
------------------
```lua
local proxy = require(Game.ServerScripts.Proxy)

local env = proxy.new {
    environment = getfenv(1),
    metatable = { __index = function(t, k) print(t, 'indexed at', k) return t[k] end }
}
setfenv(1, env)
print(Game.PlaceId)
--> table: 0B0DE4A8 indexed at print
--> table: 0B0DE4A8 indexed at Game
--> Place1 indexed at PlaceId
--> 0
```

Known Issues
------------------
1. Errors thrown in user-supplied metamethods can be revealing:

    ```lua
    local env = proxy.new {
        environment = getfenv(1),
        metatable = { __call = function(f, ...) return f(...) end }
    }
    setfenv(1, env)
    Game()
    --> attempt to call local 'f' (a userdata value)
    ```
    This is why users should supply only necessary metamethods.
