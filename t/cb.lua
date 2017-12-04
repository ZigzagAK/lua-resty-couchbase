local _M = {
  _VERSION = "1.0"
}

local couchbase = require "resty.couchbase"

local cluster = couchbase.cluster {
  host = "192.168.2.2",
  user = "Administrator",
  password = "Administrator"
}

local bucket = cluster:bucket {
  name = "b1",
  password = "1111",
  VBUCKETAWARE = true,
  pool_idle = 10,
  pool_size = 200
}

local bucket2 = cluster:bucket {
  name = "b2",
  password = "2222",
  VBUCKETAWARE = false
}

function _M.set(key, value)
  local cb = bucket:session()
  cb:setQ(key, value)
  local r = cb:set(key, value)
  if r.header.status_code ~= 0 then
    return r
  end
  r = cb:getK(key)
  cb:setkeepalive()
  return r
end

function _M.set_perf(key, value)
  local cb = bucket:session()
  local r = cb:set(key, value)
  cb:setkeepalive()
  return r
end

function _M.set2(key, value)
  local cb = bucket2:session()
  local r = cb:set(key, value)
  if r.header.status_code ~= 0 then
    return r
  end
--  r = cb:getK(key)
  cb:setkeepalive()
  return r
end

function _M.replace(key, value)
  local cb = bucket2:session()
  local r = cb:replace(key, value)
  cb:setkeepalive()
  return r
end

function _M.touch(key, expire)
  local cb = bucket:session()
  local r = cb:touch(key, expire)
  cb:setkeepalive()
  return r
end

function _M.get(key)
  local cb = bucket:session()
  local r = cb:get(key)
  cb:setkeepalive()
  return r
end

function _M.delete(key)
  local cb = bucket:session()
  local r = cb:delete(key)
  cb:setkeepalive()
  return r
end

function _M.gat(key)
  local cb = bucket:session()
  cb:touch(key, ngx.time() + 3600)
  local r = cb:gat(key, ngx.time() + 3600)
  cb:setkeepalive()
  return r
end

function _M.stat(key)
  local cb = bucket:session()
  local r = cb:stat(key)
  cb:setkeepalive()
  return r
end

function _M.version(key)
  local cb = bucket:session()
  local r = cb:version()
  cb:setkeepalive()
  return r
end

function _M.verbosity(level)
  local cb = bucket:session()
  local r = cb:verbosity(level)
  cb:setkeepalive()
  return r
end

function _M.incr(key)
  local cb = bucket:session()
  local r = cb:increment(key)
  cb:setkeepalive()
  return r
end

function _M.decr(key)
  local cb = bucket:session()
  local r = cb:decrement(key)
  cb:setkeepalive()
  return r
end

function _M.sasl_list()
  local cb = bucket:session()
  local r = cb:sasl_list(key)
  cb:setkeepalive()
  return r
end

function _M.list_buckets()
  local cb = bucket:session()
  local r = cb:list_buckets()
  cb:setkeepalive()
  return r
end

function _M.noop()
  local cb = bucket:session()
  cb:sasl_list(key)
  local r = cb:noop()
  cb:setkeepalive()
  return r
end

function _M.flush()
  local cb = bucket:session()
  local r = cb:flush()
  cb:setkeepalive()
  return r
end

return _M