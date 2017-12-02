# lua-resty-couchbase
Nginx lua couchbase client (binary memcached protocol)

Ideas got from:
  * [Lua-couchbase](https://github.com/kolchanov/Lua-couchbase)

# Status

Under development.
* Structure may be changed beacuse active development is in progress.
* `git commit --amend` may be used until the development will not be finished.


# Example

## Module:
```
local _M = {
  _VERSION = "1.0"
}

local couchbase = require "resty.couchbase"

local cluster = couchbase.cluster {
  bucket = "default",
  host = "10.0.10.2",
  user = "Administrator",
  password = "Administrator"
}

function _M.set(key, value)
  local cb = cluster:new()
  local r = cb:set(key, value)
  r = cb:get(key)
  cb:setkeepalive()
  return r
end

function _M.get(key)
  local cb = cluster:new()
  local r = cb:get(key)
  cb:setkeepalive()
  return r
end

return _M

```

## Config
```
server {
  listen 4444;
  location /set {
    content_by_lua_block {
      local cb = require "cb"
      local cjson = require "cjson"
      ngx.say(cjson.encode(cb.set(ngx.var.arg_key, ngx.var.arg_value)))
    }
  }
  location /get {
    content_by_lua_block {
      local cb = require "cb"
      local cjson = require "cjson"
      ngx.say(cjson.encode(cb.get(ngx.var.arg_key)))
    }
  }
}
```

