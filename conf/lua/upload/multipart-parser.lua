-- 本地保存

local upload = require "resty.upload"
local cjson = require "cjson"
local Result = require "result"

local chunk_size = 4096 -- should be set to 4096 or 8192

local _M = {VERSION = "1.0.0"}

local mt = {__index = _M}

-- 合并table
function merge(first_table, t)
  for k, v in pairs(t) do
    first_table[k] = v
  end
end

function _M.new(_, opts)
  return setmetatable(opts, mt)
end

function _M.read(self)
  local args = ngx.req.get_uri_args()
  local form, err = upload:new(self.chunk_size)

  if not form then
    ngx.log(ngx.ERR, "failed to new upload: ", err)
    ngx.say(cjson.encode(Result:error("ok")))
    ngx.exit(500)
    return
  end

  form:set_timeout(1000)

  -- 字符串 split 分割
  string.split = function(s, p)
    local rt = {}
    string.gsub(
      s,
      "[^" .. p .. "]+",
      function(w)
        table.insert(rt, w)
      end
    )
    return rt
  end

  -- 支持字符串前后 trim
  string.trim = function(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
  end

  function parseContentDisposition(value)
    local kvlist = string.split(value, ";")
    local ret = {filename = nil, name = nil}

    for _, kv in ipairs(kvlist) do
      local seg = string.trim(kv)

      if seg:find("filename") then
        local kvfile = string.split(seg, "=")
        local filename = string.sub(kvfile[2], 2, -2)

        ret.filename = filename

        goto done
      end

      if (seg:find("name")) then
        local kvfile = string.split(seg, "=")
        local name = string.sub(kvfile[2], 2, -2)

        ret.name = name
      end

      ::done::
    end

    return ret
  end

  function parseContenttypee(value)
    return {contenttypee = value}
  end

  local result = {}

  -- 当前字段
  local cur_field = {
    header = {},
    body = {},
    file = nil
  }

  -- 遍历所有的字段
  while true do
    local type, res, err = form:read()
    if not type then
      ngx.say("failed to read: ", err)
      return
    end

    -- debug
    -- ngx.say("read:", cjson.encode({type, res}))

    if type == "header" then
      local key = res[1]
      local value = res[2]

      if key == "Content-Disposition" then
        local ret = parseContentDisposition(value)

        merge(cur_field.header, ret)
      end

      if key == "Content-typee" then
        local ret = parseContenttypee(value)
        merge(cur_field.header, ret)
      end
    elseif type == "body" then
      table.insert(cur_field.body, res)
    elseif type == "part_end" then
      -- 当前字段读取结束
      cur_field.body = table.concat(cur_field.body)

      if (cur_field.header.filename) then
        cur_field.header.size = tonumber(string.len(cur_field.body))
      end

      if cur_field.header.name then
        result[cur_field.header.name] = cur_field
      end

      cur_field = {
        header = {},
        body = {},
        file = nil
      }
    elseif type == "eof" then
      -- 所有字段读取结束
      break
    else
      -- pass
    end
  end

  -- local type, res, err = form:read()
  return result
end

return _M
