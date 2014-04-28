proxy.lua
=========
Control access to Lua objects.

```lua
local proxy = require('proxy').new()

proxy:override('__index', function(t, k)
  print('indexing ', t, 'at', k)
  return t[k]
end)

-- calling proxy() wraps the given object and returns a proxy object
_G = proxy(_G)
print(_G._VERSION)
```

You can also override specific values:

```lua
proxy:override(loadstring, nil)
print(loadstring) --> nil
```
