local http = require "http"
local sign = require "qcloud-cos-sign"

local _M = {}

_M.VERSION = "1.0.0"

local mt = {__index = _M}

function _M.new(self, opts)
  return setmetatable(opts, mt)
end

function _M.put(self, settings)
  local httpc = http.new()

  httpc:set_timeout(10000)

  local auth = sign.sign(settings, self.secret_key, self.secret_id)
  settings.headers["Authorization"] = auth

  local uri = string.format("http://%s%s", self.host, settings.path)

  return httpc:request_uri(uri, settings)
end

return _M
