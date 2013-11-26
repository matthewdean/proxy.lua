Usage
===================
    local proxy = require(Game.ServerScriptService.Proxy)
    
    local env = proxy.new(getfenv(0), {
      __index = function(t, k)
        if t == getfenv(0) and k == "print" then
          return function(...) print('muhahah hijacked print', ....)
        end
        return t[k]
      end
    })
    
    setfenv(function() print(1492) end, env)()
