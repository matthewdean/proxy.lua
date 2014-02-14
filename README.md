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

### proxy.new(table options = {})

* `environment` - the environment to wrap. defaults to an empty table.
* `metatable` if you do something like tostring(proxy), the __tostring metamethod, will be called. defaults to an empty table meaning you aren't hooking into any events. Note that metamethods only fire on tables and userdata. e.g. t[k] = 5

Limitations
------------------
1. Error messages sometimes break the illusion

    ```lua
    setfenv(1, proxy.new())
    nonExtantFunction()
    --> attempt to call local 'f' (a userdata value)
    ```
    
TODO
-----------------
Add filter function
