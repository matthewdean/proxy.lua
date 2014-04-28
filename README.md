proxy.lua
=========
Control access to Lua objects.

```lua
local proxy = require('proxy').new()

-- comment here
proxy.override('__index', function(t, k)
	if t == _G and then
	
	end
	return t[k]
end)

-- calling proxy() wraps the given object and returns a proxy object
_G = proxy(_G)
shared = proxy(shared)
```

You can also override specific values:

```lua
proxy.override(loadstring, nil)
print(loadstring) --> nil
```