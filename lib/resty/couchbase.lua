local _M = {
  _VERSION = '0.1-alpha'
}

local cjson = require "cjson"
local http = require "resty.http"
local bit = require "bit"

local c = require "resty.couchbase.consts"
local encoder = require "resty.couchbase.encoder"

local tcp = ngx.socket.tcp
local tconcat, tinsert = table.concat, table.insert
local assert = assert
local pairs = pairs
local json_decode = cjson.decode
local encode_base64 = ngx.encode_base64
local crc32 = ngx.crc32_short
local xpcall = xpcall
local traceback = debug.traceback
local unpack = unpack
local tostring = tostring
local rshift, band = bit.rshift, bit.band

local defaults = {
  port = 8091,
  timeout = 30000,
  query_timeout = 30000,
  pool_idle = 10,
  pool_size = 10
}

-- consts

local MAGIC = c.magic
local op_code = c.op_code
local status = c.status
local status_desc = c.status_desc

-- extras consts

local deadbeef = c.deadbeef

-- encoder

local encode = encoder.encode
local handle_header = encoder.handle_header
local handle_body = encoder.handle_body
local put_i8 = encoder.put_i8
local put_i16 = encoder.put_i16
local put_i32 = encoder.put_i32
local put_i32 = encoder.put_i32
local get_i32 = encoder.get_i32
local pack_bytes = encoder.pack_bytes

-- helpers

local function foreach_v(tab, f)
  for _,v in pairs(tab) do f(v) end
end

local zero_4 = encoder.pack_bytes(4, 0, 0, 0, 0)

-- class tables

local couchbase_cluster = {}
local couchbase_class = {}

-- request

local function request(sock, body, fun)
  assert(sock:send(body))
  local header = handle_header(assert(sock:receive(24)))
  local body = handle_body(sock, header)
  if fun and body.value then
    body.value = fun(body.value)
  end
  return {
    header = header,
    body = body
  }
end

local function requestQ(sock, body)
  assert(sock:send(body))
  return {}
end

local function requestUntil(sock, body)
  assert(sock:send(body))
  local t = {}
  repeat
    local header = handle_header(assert(sock:receive(24)))
    local body = handle_body(sock, header)
    tinsert(t, {
      header = header,
      body = body
    })
  until not body or not body.key
  return t
end

-- helpers

local function fetch_vbuckets(cluster)
  local httpc = http.new()

  httpc:set_timeout(cluster.timeout)

  assert(httpc:connect(cluster.host, cluster.port))

  local resp = assert(httpc:request {
    path = "/pools/default/buckets/" .. cluster.bucket,
    headers = {
      Authorization = "Basic " .. encode_base64(cluster.user .. ":" .. cluster.password),
      Accept = "application/json",
      Host = cluster.host .. ":" .. cluster.port
    }
  })

  assert(resp.status == ngx.HTTP_OK, "Unauthorized")

  local body = assert(resp:read_body())

  httpc:close()

  local vBucketServerMap = assert(json_decode(body)).vBucketServerMap

  assert(vBucketServerMap, "vBucketServerMap is not found in the response")
  assert(vBucketServerMap.vBucketMap, "vBucketServerMap.vBucketMap is not found in the response")
  assert(vBucketServerMap.serverList, "vBucketServerMap.serverList is not found in the response")

  return vBucketServerMap.vBucketMap, vBucketServerMap.serverList
end

local function update_vbucket_map(cluster, force)
  if force or not cluster.vbuckets then 
    cluster.vbuckets, cluster.servers = fetch_vbuckets(cluster)
    for i, server in ipairs(cluster.servers)
    do
      cluster.servers[i] = { server:match("^(.+):(%d+)$") }
    end
  end
end

local function get_vbucket_id(cluster, key)
  return cluster.VBUCKETAWARE and band(rshift(crc32(key), 16), #cluster.vbuckets - 1) or 1   
end

local function get_server(cluster, vbucket_id)
  return unpack(cluster.servers[cluster.vbuckets[vbucket_id or 1][1] + 1])
end

-- cluster class

function _M.cluster(opts)
  opts = opts or {}
  assert(opts.host and opts.user and opts.password, "host, user and password required")

  opts.bucket = opts.bucket or "default"
  opts.port = opts.port or defaults.port
  opts.timeout = opts.timeout or defaults.timeout
  opts.query_timeout = opts.query_timeout or defaults.query_timeout
  opts.pool_idle = opts.pool_idle or defaults.pool_idle
  opts.pool_size = opts.pool_size or defaults.pool_size

  return setmetatable(opts, {
    __index = couchbase_cluster
  })
end

function couchbase_cluster:new()
  update_vbucket_map(self)
  return setmetatable({
    cluster = self,
    connections = {}
  }, {
    __index = couchbase_class
  })
end

-- couchbase class

local function auth_sasl(sock, cluster)
  if not cluster.bucket_password then
    return
  end
  local _, auth_result = assert(xpcall(request, function(err)
    ngx.log(ngx.ERR, traceback())
    sock:close()
    return err
  end, sock, encode(op_code.SASL_Auth, {
    key = "PLAIN",
    value = put_i8(0) .. cluster.bucket .. put_i8(0) ..  cluster.bucket_password
  })))
  if not auth_result.body or auth_result.body.value ~= "Authenticated" then
    sock:close()
    error("Not authenticated")
  end
end

local function connect(self, vbucket_id)
  local host, port = get_server(self.cluster, vbucket_id)
  local cache_key = host .. ":" .. port
  local sock = self.connections[cache_key]
  if sock then
    return sock
  end
  sock = assert(tcp())
  sock:settimeout(self.cluster.timeout)
  assert(sock:connect(host, port, {
    pool = self.cluster.bucket
  }))
  if assert(sock:getreusedtimes()) == 0 then
    -- connection created
    -- sasl
    auth_sasl(sock, self.cluster)
  end
  self.connections[cache_key] = sock
  return sock
end

local function setkeepalive(self)
  local pool_idle, pool_size = self.cluster.pool_idle * 1000, self.cluster.pool_size
  foreach_v(self.connections, function(sock)
    sock:setkeepalive(pool_idle, pool_size)
  end)
  self.map = {}
end

local function close(self)
  foreach_v(self.connections, function(sock)
    request(sock, encode(op_code.QuitQ, {}))
    sock:close()
  end)
  self.map = {}
end

function couchbase_class:setkeepalive()
  setkeepalive(self)
end

function couchbase_class:close()
  close(self)
end

function couchbase_class:noop()
  foreach_v(self.connections, function(sock)
    request(sock, encode(op_code.Noop, {}))
  end)
end

function couchbase_class:flush()
  return request(connect(self), encode(op_code.Flush, {}))    
end

function couchbase_class:flushQ()
  error("Unsupported")
end

function couchbase_class:set(key, value, expire, cas)
  local vbucket_id = get_vbucket_id(self.cluster, key)
  return request(connect(self, vbucket_id), encode(op_code.Set, {
    key = key,
    value = value,
    expire = expire or 0,
    extras = deadbeef,
    cas = cas,
    vbucket_id = vbucket_id
  }))
end   

function couchbase_class:setQ(key, value, expire, cas)
  local vbucket_id = get_vbucket_id(self.cluster, key)
  return requestQ(connect(self, vbucket_id), encode(op_code.SetQ, {
    key = key,
    value = value,
    expire = expire or 0,
    extras = deadbeef,
    cas = cas,
    vbucket_id = vbucket_id
  }))
end   

function couchbase_class:add(key, value, expire)
  local vbucket_id = get_vbucket_id(self.cluster, key)
  return request(connect(self, vbucket_id), encode(op_code.Add, {
    key = key,
    value = value,
    expire = expire or 0,
    extras = deadbeef,
    vbucket_id = vbucket_id
  }))
end

function couchbase_class:addQ(key, value, expire)
  local vbucket_id = get_vbucket_id(self.cluster, key)
  return requestQ(connect(self, vbucket_id), encode(op_code.AddQ, {
    key = key,
    value = value,
    expire = expire or 0,
    extras = deadbeef,
    vbucket_id = vbucket_id
  }))
end

function couchbase_class:replace(key, value, expire, cas)
  local vbucket_id = get_vbucket_id(self.cluster, key)
  return request(connect(self, vbucket_id), encode(op_code.Replace, {
    key = key,
    value = value,
    expire = expire or 0,
    extras = deadbeef,
    cas = cas,
    vbucket_id = vbucket_id
  }))
end 

function couchbase_class:replaceQ(key, value, expire, cas)
  local vbucket_id = get_vbucket_id(self.cluster, key)
  return requestQ(connect(self, vbucket_id), encode(op_code.ReplaceQ, {
    key = key,
    value = value,
    expire = expire or 0,
    extras = deadbeef,
    cas = cas,
    vbucket_id = vbucket_id
  }))
end 

function couchbase_class:get(key)
  local vbucket_id = get_vbucket_id(self.cluster, key)
  return request(connect(self, vbucket_id), encode(op_code.Get, {
    key = key,
    vbucket_id = vbucket_id
  }))
end

function couchbase_class:getQ(key)
  error("Unsupported")
end

function couchbase_class:getK(key)
  local vbucket_id = get_vbucket_id(self.cluster, key)
  return request(connect(self, vbucket_id), encode(op_code.GetK, {
    key = key,
    vbucket_id = vbucket_id
  }))
end

function couchbase_class:getKQ(key)
  error("Unsupported")
end

function couchbase_class:touch(key, expire)
  local vbucket_id = get_vbucket_id(self.cluster, key)
  return request(connect(self, vbucket_id), encode(op_code.Touch, {
    key = key,
    expire = expire,
    vbucket_id = vbucket_id
  }))
end

function couchbase_class:gat(key, expire)
  if not expire then
    return nil, "expire required"
  end
  local vbucket_id = get_vbucket_id(self.cluster, key)
  return request(connect(self, vbucket_id), encode(op_code.GAT, {
    key = key,
    expire = expire, 
    vbucket_id = vbucket_id
  }))
end

function couchbase_class:gatQ(key, expire)
  if not expire then
    return nil, "expire required"
  end
  local vbucket_id = get_vbucket_id(self.cluster, key)
  return requestQ(connect(self, vbucket_id), encode(op_code.GATQ, {
    key = key,
    expire = expire, 
    vbucket_id = vbucket_id
  }))
end

function couchbase_class:delete(key, cas)
  local vbucket_id = get_vbucket_id(self.cluster, key)
  return request(connect(self, vbucket_id), encode(op_code.Delete, {
    key = key,
    cas = cas,
    vbucket_id = vbucket_id
  }))
end

function couchbase_class:deleteQ(key, cas)
  local vbucket_id = get_vbucket_id(self.cluster, key)
  return requestQ(connect(self, vbucket_id), encode(op_code.DeleteQ, {
    key = key,
    cas = cas,
    vbucket_id = vbucket_id
  }))
end

function couchbase_class:increment(key, increment, initial, expire)
  local vbucket_id = get_vbucket_id(self.cluster, key)
  local extras = zero_4                  ..
                 put_i32(increment or 1) ..
                 zero_4                  ..
                 put_i32(initial or 0)
  return request(connect(self, vbucket_id), encode(op_code.Increment, {
    key = key, 
    expire = expire or 0,
    extras = extras,
    vbucket_id = vbucket_id
  }), function(value)
    return get_i32 {
      data = value,
      pos = 5
    }
  end)
end 

function couchbase_class:incrementQ(key, increment, initial, expire)
  local vbucket_id = get_vbucket_id(self.cluster, key)
  local extras = zero_4                  ..
                 put_i32(increment or 1) ..
                 zero_4                  ..
                 put_i32(initial or 0)
  return requestQ(connect(self, vbucket_id), encode(op_code.IncrementQ, {
    key = key, 
    expire = expire or 0,
    extras = extras,
    vbucket_id = vbucket_id
  }))
end 

function couchbase_class:decrement(key, decrement, initial, expire)
  local vbucket_id = get_vbucket_id(self.cluster, key)
  local extras = zero_4                  ..
                 put_i32(decrement or 1) ..
                 zero_4                  ..
                 put_i32(initial or 0)
  return request(connect(self, vbucket_id), encode(op_code.Decrement, {
    key = key, 
    expire = expire or 0,
    extras = extras,
    vbucket_id = vbucket_id
  }), function(value)
    return get_i32 {
      data = value,
      pos = 5
    }
  end)
end

function couchbase_class:decrementQ(key, decrement, initial, expire)
  local vbucket_id = get_vbucket_id(self.cluster, key)
  local extras = zero_4                  ..
                 put_i32(decrement or 1) ..
                 zero_4                  ..
                 put_i32(initial or 0)
  return requestQ(connect(self, vbucket_id), encode(op_code.DecrementQ, {
    key = key, 
    expire = expire or 0,
    extras = extras,
    vbucket_id = vbucket_id
  }))
end

function couchbase_class:append(key, value, cas)
  if not key or not value then
    return nil, "key and value required"
  end
  local vbucket_id = get_vbucket_id(self.cluster, key)
  return request(connect(self, vbucket_id), encode(op_code.Append, {
    key = key,
    value = value,
    cas = cas,
    vbucket_id = vbucket_id
  }))
end

function couchbase_class:appendQ(key, value, cas)
  if not key or not value then
    return nil, "key and value required"
  end
  local vbucket_id = get_vbucket_id(self.cluster, key)
  return requestQ(connect(self, vbucket_id), encode(op_code.AppendQ, {
    key = key,
    value = value,
    cas = cas,
    vbucket_id = vbucket_id
  }))
end

function couchbase_class:prepend(key, value, cas)
  if not key or not value then
    return nil, "key and value required"
  end
  local vbucket_id = get_vbucket_id(self.cluster, key)
  return request(connect(self, vbucket_id), encode(op_code.Prepend, {
    key = key,
    value = value,
    cas = cas,
    vbucket_id = vbucket_id
  }))
end

function couchbase_class:prependQ(key, value, cas)
  if not key or not value then
    return nil, "key and value required"
  end
  local vbucket_id = get_vbucket_id(self.cluster, key)
  return requestQ(connect(self, vbucket_id), encode(op_code.PrependQ, {
    key = key,
    value = value,
    cas = cas,
    vbucket_id = vbucket_id
  }))
end

function couchbase_class:stat(key)
  return requestUntil(connect(self), encode(op_code.Stat, {
    key = key
  }))
end

function couchbase_class:version()
  return request(connect(self), encode(op_code.Version, {}))
end

function couchbase_class:verbosity(level)
  if not level then
    return nil, "level required"
  end
  return request(connect(self), encode(op_code.Verbosity, {
    extras = put_i32(level)
  }))
end

function couchbase_class:helo()
  error("Unsupported")
end

function couchbase_class:sasl_list()
  return request(connect(self), encode(op_code.SASL_List, {}))
end

function couchbase_class:set_vbucket()
  error("Unsupported")
end

function couchbase_class:get_vbucket(key)
  error("Unsupported")
end

function couchbase_class:del_vbucket()
  error("Unsupported")
end

function couchbase_class:list_buckets()
  return request(connect(self), encode(op_code.List_buckets, {}))
end

return _M