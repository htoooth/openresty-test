local _M = {code = 200, data = "", msg = ""}

local mt = {__index = _M}

function _M:ok(msg, url)
    local ret = self:new()
    ret["code"] = 200
    ret["msg"] = msg or "upload success"
    ret["data"] = url or ""
    return ret
end

function _M:error(msg)
    local ret = self:new()
    ret["code"] = 501
    ret["msg"] = msg or "upload failed"
    return ret
end

function _M:new()
    return setmetatable({}, mt)
end

return _M
