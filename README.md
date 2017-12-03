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

-- one bucket
local bucket1 = couchbase.bucket {
  bucket = "b1",
  host = "10.0.10.2",
  user = "Administrator",
  password = "Administrator",
  bucket_password = "1111",
  VBUCKETAWARE = true
}

-- second bucket
local bucket2 = couchbase.bucket {
  bucket = "b2",
  host = "10.0.10.2",
  user = "Administrator",
  password = "Administrator",
  bucket_password = "2222",
  VBUCKETAWARE = true
}

function _M.test_b1(key, value)
  local cb = bucket1:new()
  local r = cb:set(key, value)
  r = cb:get(key)
  cb:setkeepalive()
  return r
end

function _M.test_b2(key, value)
  local cb = bucket2:new()
  local r = cb:set(key, value)
  r = cb:get(key)
  cb:setkeepalive()
  return r
end

return _M

```

## Config
```
server {
  listen 4444;
  location /test_b1 {
    content_by_lua_block {
      local cb = require "cb"
      local cjson = require "cjson"
      ngx.say(cjson.encode(cb.test_b1(ngx.var.arg_key, ngx.var.arg_value)))
    }
  }
  location /test_b2 {
    content_by_lua_block {
      local cb = require "cb"
      local cjson = require "cjson"
      ngx.say(cjson.encode(cb.test_b2(ngx.var.arg_key, ngx.var.arg_value)))
    }
  }
}
```
