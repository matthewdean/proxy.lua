proxy.lua
===================
Control access to objects through metatables. Currently only works for Lua 5.1.

It's great for embedded systems where you don't control the C-side. If you use it as a sandbox, keep in mind that the end user will always be able to crash it, but he won't be able to break out of it.

Usage
------------------
```lua
local proxy = require(Game.ServerScripts.Proxy)
```

```lua
local env = proxy.new {
  environment = setmetatable({}, {__index = getfenv(1), __metatable = "The metatable is locked"}),
  metatable = {__tostring = function(instance) return instance.ClassName end}
}
setfenv(1, env)
print(Game) --> DataModel
```

Notes
-----------------
 * __call only gets called when you do userdata() or table(). It won't happen if you call a function.

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
    
TODO
-----------------
Add filter function
