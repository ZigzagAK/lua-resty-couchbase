local _M = {
  _VERSION = "1.0"
}

local couchbase = require "resty.couchbase"

local bucket = couchbase.bucket {
  bucket = "b1",
  host = "10.0.10.2",
  user = "Administrator",
  password = "Administrator",
  bucket_password = "1111",
  VBUCKETAWARE = true
}

local bucket2 = couchbase.bucket {
  bucket = "b2",
  host = "10.0.10.2",
  user = "Administrator",
  password = "Administrator",
  bucket_password = "2222",
  VBUCKETAWARE = true
}

function _M.set(key, value)
  local cb = bucket:new()
  local r = cb:setQ(key, value)
  r = cb:getK(key)
  cb:setkeepalive()
  return r
end

function _M.set2(key, value)
  local cb = bucket2:new()
  local r = cb:setQ(key, value)
  r = cb:getK(key)
  cb:setkeepalive()
  return r
end

function _M.get(key)
  local cb = bucket:new()
  local r = cb:get(key)
  cb:setkeepalive()
  return r
end

function _M.gat(key)
  local cb = bucket:new()
  cb:touch(key, ngx.time() + 3600)
  local r = cb:gat(key, ngx.time() + 3600)
  cb:setkeepalive()
  return r
end

function _M.stat(key)
  local cb = bucket:new()
  local r = cb:stat(key)
  cb:setkeepalive()
  return r
end

function _M.version(key)
  local cb = bucket:new()
  local r = cb:version()
  cb:setkeepalive()
  return r
end

function _M.verbosity(level)
  local cb = bucket:new()
  local r = cb:verbosity(level)
  cb:setkeepalive()
  return r
end

function _M.incr(key)
  local cb = bucket:new()
  local r = cb:increment(key)
  cb:setkeepalive()
  return r
end

function _M.decr(key)
  local cb = bucket:new()
  local r = cb:decrement(key)
  cb:setkeepalive()
  return r
end

function _M.sasl_list()
  local cb = bucket:new()
  local r = cb:sasl_list(key)
  cb:setkeepalive()
  return r
end

function _M.list_buckets()
  local cb = bucket:new()
  local r = cb:list_buckets()
  cb:setkeepalive()
  return r
end

return _M