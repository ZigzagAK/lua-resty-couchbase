local _M = {
  _VERSION = "1.0"
}

local couchbase = require "resty.couchbase"

local cluster = couchbase.cluster {
--host = "10.0.10.2",
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

function _M.get_perf(key)
  local cb = bucket:session()
  local r = cb:get(key)
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

function _M.get2(key)
  local cb = bucket2:session()
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
  cb:sasl_list()
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

function _M.batch(body)
  local c = require "resty.couchbase.consts"
  local cb = bucket:session()
  for i,item in ipairs(body)
  do
    item.expire = 0
    body[i] = {
      op = c.op_code.Set,
      opts = item
    }
  end
  cb:batch(body, {
    unacked_window = 4,
    thread_pool_size = 4
  })
end

function _M.batch_gen(n)
  local c = require "resty.couchbase.consts"
  local cb = bucket:session()
  local body = {}
  for i=1,n
  do
    local item = {
      expire = 0,
      key=i,
      value=[[
{
   "meta":{
      "id":"u1111",
      "tp":"u",
      "v":1,
      "mdf":1511081964
   },
   "aId":1111,
   "login":"Test",
   "pwd":"password",
   "pwdExp":123456,
   "pwdTp":123,
   "lng":123,
   "usrTp":123,
   "crDate":123456,
   "lockTp":123456,
   "lockUntil":123456,
   "creds":[
      {
         "val":"Admin",
         "tpId":250300001
      }
   ],
   "dep":"department_one",
   "depId":999,
   "lngIana":"ru",
   "asppId":1
}]]
    }
    body[i] = {
      op = c.op_code.Set,
      opts = item
    }
  end
  local s = ngx.now()
  cb:batch(body, {
    unacked_window = 100,
    thread_pool_size = 10
  })
  ngx.update_time()
  return ngx.now() - s
end

function _M.batch_genQ(s,n)
  local c = require "resty.couchbase.consts"
  local cb = bucket:session()
  local body = {}

  local s = ngx.now()

  local peers = {}
  for i=s,s+n
  do
    local w = cb:setQ(i, [[
{
   "meta":{
      "id":"u1111",
      "tp":"u",
      "v":1,
      "mdf":1511081964
   },
   "aId":1111,
   "login":"Test",
   "pwd":"password",
   "pwdExp":123456,
   "pwdTp":123,
   "lng":123,
   "usrTp":123,
   "crDate":123456,
   "lockTp":123456,
   "lockUntil":123456,
   "creds":[
      {
         "val":"Admin",
         "tpId":250300001
      }
   ],
   "dep":"department_one",
   "depId":999,
   "lngIana":"ru",
   "asppId":1
}]])
    local sock, pool = unpack(w.peer)
    peers[pool] = w.peer
  end

  -- wait responses (only errors)

  for pool, peer in pairs(peers)
  do
    cb:receive(peer)
  end
  
  ngx.update_time()
  return ngx.now() - s
 end
  
return _M