proxy.lua
===================
Control access to objects through metatables. Currently aimed at Lua 5.1

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

Notes:
__call only gets called when you do userdata() or table(). It won't happen if you call a function.

Limitations
------------------
1. Error messages sometimes break the illusion

    ```lua
    local env = proxy.new {
        environment = getfenv(1),
        metatable = { __call = function(f, ...) return f(...) end }
    }
    setfenv(1, env)
    Game()
    --> attempt to call local 'f' (a userdata value)
    ```
