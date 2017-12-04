# lua-resty-couchbase
Nginx lua couchbase client (binary memcached protocol)

Thank's for the ideas: [Lua-couchbase](https://github.com/kolchanov/Lua-couchbase)

Table of Contents
=============

* [Status](#status)
* [Synopsis](#synopsis)
	* [Module](#module)
	* [Config](#config)
* [Cluster API](#cluster_api)
* [Bucket API](#bucket_api)
* [Session API](#session_api)

Status
=====

Under development.

Synopsis
=======

Module
-------
```
local _M = {
  _VERSION = "1.0"
}

local couchbase = require "resty.couchbase"

-- cluster
local cluster = couchbase.cluster {
  host = "10.0.10.2",
  user = "Administrator",
  password = "Administrator"
}

-- one bucket
local bucket1 = cluster:bucket {
  name = "b1",
  password = "1111",
  VBUCKETAWARE = true
}

-- second bucket
local bucket2 = cluster:bucket {
  name = "b2",
  password = "2222",
  VBUCKETAWARE = true
}

function _M.test_b1(key, value)
  local cb = bucket1:session()
  local r = cb:set(key, value)
  r = cb:get(key)
  cb:setkeepalive()
  return r
end

function _M.test_b2(key, value)
  local cb = bucket2:session()
  local r = cb:set(key, value)
  r = cb:get(key)
  cb:setkeepalive()
  return r
end

return _M

```

Config
------
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

<a name="cluster_api"></a>
Cluster API
========
cluster
------
**syntax:** `cluster(opts)`

**context:** rewrite_by_lua, access_by_lua, content_by_lua, timer

Create the cluster object.

`opts` - the table with parameters.

* host - Couchbase REST API host.
* port - Couchbase REST API port (default 8091).
* user, password - username and password for REST api.
* timeout - http timeout.

```
local couchbase = require "resty.couchbase"

local cluster = couchbase.cluster {
  host = "10.0.10.2",
  user = "Administrator",
  password = "Administrator"
}
```

**return:** cluster object or throws the error.

bucket
------
**syntax:** `cluster:bucket(opts)`

**context:** rewrite_by_lua, access_by_lua, content_by_lua, timer

Create the bucket object.

```
local bucket = cluster:bucket {
  name = "b",
  password = "1111",
  VBUCKETAWARE = true
}
```

`opts` - the table with parameters.

* name - Couchbase BUCKET name (default: `default`).
* password - SASL password for the bucket `name`.
* timeout - socket timeout.
* pool_size - bucket keepalive pool size.
* pool_idle - bucket keepalive pool idle in sec.
* VBUCKETAWARE: `true` or `false`.

**return:** bucket object or throws the error.

<a name="bucket_api"></a>
Bucket API
========
session
------
**syntax:** `bucket:session()`

**context:** rewrite_by_lua, access_by_lua, content_by_lua, timer

Create the session object.

```
local bucket = bucket:session()
```

**return:** session object or throws the error.

<a name="session_api"></a>
Session API
========
noop
------
**syntax:** `session:noop()`

**context:** rewrite_by_lua, access_by_lua, content_by_lua, timer

No operation.

Noop operation over all connections in the current bucket session is used.

**return:** array with couchbase responses `[{"header":{"opaque":0,"CAS":[0,0,0,0,0,0,0,0],"status_code":0,"status":"No error","type":0}}]`.

close
------
**syntax:** `session:close()`

**context:** rewrite_by_lua, access_by_lua, content_by_lua, timer

Close all connections to all vbuckets in the current bucket session.

**return:** none

setkeepalive
------------
**syntax:** `session:setkeepalive()`

**context:** rewrite_by_lua, access_by_lua, content_by_lua, timer

Return all connections in the current session to keepalive bucket pool.

**return:** none

set
---
**syntax:** `session:set(key, value, expire, cas)`

**context:** rewrite_by_lua, access_by_lua, content_by_lua, timer

Sets the `value` for the `key`.

Optional parameter `expire` sets the TTL for key.
Optional parameter `cas` must be a CAS value from the `get()` method.

**return:** `{"header":{"opaque":0,"CAS":[0,164,136,177,61,99,242,140],"status_code":0,"status":"No error","type":0}}` on success (or any valid couchbase status) or throws the error.  Status MUST be retrieved from the header.

setQ
----
**syntax:** `session:setQ(key, value, expire, cas)`

**context:** rewrite_by_lua, access_by_lua, content_by_lua, timer

Sets the `value` for the `key`.

Optional parameter `expire` sets the TTL for key.
Optional parameter `cas` must be a CAS value from the `get()` method.

Couchbase not sent the response on setQ command.

**return:** `{}` on success (or any valid couchbase status) or throws the error.

add
---
**syntax:** `session:set(key, value, expire)`

**context:** rewrite_by_lua, access_by_lua, content_by_lua, timer

Add the `key` with `value`.
Optional parameterr: `expire`.

**return:** `{"header":{"opaque":0,"CAS":[0,164,136,177,61,99,242,140],"status_code":0,"status":"No error","type":0}}` on success (or any valid couchbase status) or throws the error. Status MUST be retrieved from the header.

addQ
----
**syntax:** `session:addQ(key, value, expire)`

**context:** rewrite_by_lua, access_by_lua, content_by_lua, timer

Add the `key` with `value`.

Optional parameter `expire` sets the TTL for key.

Couchbase not sent the response on addQ command.

**return:** `{}` on success (or any valid couchbase status) or throws the error.

replace
-------
**syntax:** `session:replace(key, value, expire, cas)`

**context:** rewrite_by_lua, access_by_lua, content_by_lua, timer

Replace the `value` for the `key`.

Optional parameter `expire` sets the TTL for key.
Optional parameter `cas` must be a CAS value from the `get()` method.

**return:** `{"header":{"opaque":0,"CAS":[0,164,137,158,82,69,97,51],"status_code":0,"status":"No error","type":0}}` on success (or any valid couchbase status) or throws the error.  
If key is not exists `{"header":{"opaque":0,"CAS":[0,0,0,0,0,0,0,0],"status_code":1,"status":"Key not found","type":0},"value":"Not found"}`.
Status MUST be retrieved from the header.

replaceQ
--------
**syntax:** `session:replaceQ(key, value, expire, cas)`

**context:** rewrite_by_lua, access_by_lua, content_by_lua, timer

Replace the `value` for the `key`.

Optional parameter `expire` sets the TTL for key.
Optional parameter `cas` must be a CAS value from the `get()` method.

Couchbase not sent the response on replaceQ command.

**return:** `{}` on success (or any valid couchbase status) or throws the error.

get
---
**syntax:** `session:get(key)`

**context:** rewrite_by_lua, access_by_lua, content_by_lua, timer

Get value for the `key`.

**return:** `{"header":{"opaque":0,"CAS":[0,164,133,238,116,1,16,213],"status_code":0,"status":"No error","type":0},"value":"7"}` on success (or any valid couchbase status) or throws the error.
If key is not exists `{"header":{"opaque":0,"CAS":[0,0,0,0,0,0,0,0],"status_code":1,"status":"Key not found","type":0},"value":"Not found"}`.
Status MUST be retrieved from the header.

getK
----
**syntax:** `session:getK(key)`

**context:** rewrite_by_lua, access_by_lua, content_by_lua, timer

Get value for the `key`.

K-version for `get` returns the `key` in additional parameter.

touch
-----
**syntax:** `session:touch(key, expire)`

**context:** rewrite_by_lua, access_by_lua, content_by_lua, timer

Get value for the `key`.
Optional parameter `expire` sets the TTL for key.

**return:** `{"header":{"opaque":0,"CAS":[0,164,140,177,69,146,148,224],"status_code":0,"status":"No error","type":0}}` on success (or any valid couchbase status) or throws the error.
If key is not exists `{"header":{"opaque":0,"CAS":[0,0,0,0,0,0,0,0],"status_code":1,"status":"Key not found","type":0},"value":"Not found"}`.
Status MUST be retrieved from the header.

gat
---
**syntax:** `session:gat(key, expire)`

**context:** rewrite_by_lua, access_by_lua, content_by_lua, timer

get() + touch()

delete
------
**syntax:** `session:delete(delete, cas)`

**context:** rewrite_by_lua, access_by_lua, content_by_lua, timer

Delete the `key`.
Optional parameter `cas` must be a CAS value from the `get()` method.

**return:** `{"header":{"opaque":0,"CAS":[0,164,140,177,69,146,148,224],"status_code":0,"status":"No error","type":0}}` on success (or any valid couchbase status) or throws the error.
If key is not exists `{"header":{"opaque":0,"CAS":[0,0,0,0,0,0,0,0],"status_code":1,"status":"Key not found","type":0},"value":"Not found"}`.
Status MUST be retrieved from the header.

deleteQ
-------
**syntax:** `session:deleteQ(delete, cas)`

**context:** rewrite_by_lua, access_by_lua, content_by_lua, timer

Delete the `key`.
Optional parameter `cas` must be a CAS value from the `get()` method.

Couchbase not sent the response on deleteQ command.

**return:** `{}` on success (or any valid couchbase status) or throws the error.

increment
---------
**syntax:** `session:increment(key, increment, initial, expire)`

**context:** rewrite_by_lua, access_by_lua, content_by_lua, timer

Increment value for the `key`.
Optional parameter `increment` sets the increment value.
Optional parameter `initial` sets the initial value.
Optional parameter `expire` sets the TTL for key.

**return:** `{"header":{"opaque":0,"CAS":[0,164,139,76,53,235,109,100],"status_code":0,"status":"No error","type":0},"value":213}` on success (or any valid couchbase status) or throws the error. Returns the next value.
Status MUST be retrieved from the header.

incrementQ
---------
**syntax:** `session:incrementQ(key, increment, initial, expire)`

**context:** rewrite_by_lua, access_by_lua, content_by_lua, timer

Increment value for the `key`.
Optional parameter `increment` sets the increment value.
Optional parameter `initial` sets the initial value.
Optional parameter `expire` sets the TTL for key.

Couchbase not sent the response on incrementQ command.

**return:** `{}` on success (or any valid couchbase status) or throws the error. Returns the next value.
Status MUST be retrieved from the header.

decrement
----------
**syntax:** `session:decrement(key, increment, initial, expire)`

**context:** rewrite_by_lua, access_by_lua, content_by_lua, timer

Decrement value for the `key`.
Optional parameter `increment` sets the decrement value.
Optional parameter `initial` sets the initial value.
Optional parameter `expire` sets the TTL for key.

**return:** `{"header":{"opaque":0,"CAS":[0,164,139,76,53,235,109,100],"status_code":0,"status":"No error","type":0},"value":213}` on success (or any valid couchbase status) or throws the error. Returns the next value.
Status MUST be retrieved from the header.

decrementQ
-----------
**syntax:** `session:decrementQ(key, increment, initial, expire)`

**context:** rewrite_by_lua, access_by_lua, content_by_lua, timer

Decrement value for the `key`.
Optional parameter `increment` sets the decrement value.
Optional parameter `initial` sets the initial value.
Optional parameter `expire` sets the TTL for key.

Couchbase not sent the response on decrementQ command.

**return:** `{}` on success (or any valid couchbase status) or throws the error. Returns the next value.
Status MUST be retrieved from the header.