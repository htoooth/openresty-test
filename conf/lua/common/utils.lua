local uuid = require "uuid"

local _M = {}

function _M.uuid_filename(filename)
  uuid.seed()
  return uuid() .. "." .. filename:match(".+%.(%w+)$")
end

function _M.log(...)
  local arg = {...}
  local result = {}

  for _, v in ipairs(arg) do
    table.insert(result, v)
  end

  ngx.log(ngx.ERR, table.concat(result, ""))
end

function _M.write(path, str)
  local file = io.open(path, "a+")
  io.output(file)
  io.write(str .. "\n")
  io.close(file)
end

return _M
