proxy.lua
===================
Control access to a table, userdata, or function by passing in a metatable which will be called. Works recursively.

Usage
------------------
```lua
local proxy = require(Game.ServerScripts.Proxy)

local options = {}
options.environment = getfenv(1)
options.metatable = {
    __index = function(t, k)
        print(t, 'indexed at', k)
        return t[k]
    end
}

local environment = proxy.new(options)
```
And now:
```lua
setfenv(1, environment)
print(Game.PlaceId)
--> table: 0B0DE4A8 indexed at print
--> table: 0B0DE4A8 indexed at Game
--> Place1 indexed at PlaceId
--> 0
```

Known Issues:
------------------
Errors thrown in user-supplied metamethods may be incorrect:

```lua
local a = proxy.new(getfenv(0), {
    __call = function(f, ...) return f(...) end
})
Game()
--> attempt to call local 'f' (a userdata value)
```

The solution is for the user to avoid supplying a custom metamethod unless necessary. For example, if he does not need to hook into userdata or tables being called, he should not supply the above metamethod.
