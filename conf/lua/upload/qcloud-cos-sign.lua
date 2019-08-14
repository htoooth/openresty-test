-- 腾讯云存储
local _M = {}

local hmacSha1 = ngx.hmac_sha1
local sha1 = ngx.sha1_bin
local urlEncode = ngx.escape_uri
local resty_string = require "resty-string"

local TIME_60_MINS = 60 * 60

local function toHex(buf)
  return resty_string.to_hex(buf)
end

local function getKeyTime(expires)
  local start_timestamp = math.floor(ngx.now())
  local end_timestamp = math.floor(start_timestamp + (expires or TIME_60_MINS))

  return string.format("%d;%d", start_timestamp, end_timestamp)
end

local function getSignKey(secret_key, key_time)
  return toHex(hmacSha1(secret_key, key_time))
end

local function encodeTable(param_table)
  local key_list = {}
  local clone_table = {}

  for k, v in pairs(param_table) do
    local lower_k = string.lower(k)
    local encode_v = urlEncode(v)

    table.insert(key_list, lower_k)

    clone_table[lower_k] = encode_v
  end

  table.sort(key_list)

  local encode_key_list = {}
  for _, v in ipairs(key_list) do
    table.insert(encode_key_list, string.lower(urlEncode(v)))
  end

  local paramenter_list = {}
  local param_list = {}

  for _, v in ipairs(encode_key_list) do
    table.insert(paramenter_list, string.format("%s=%s", v, clone_table[v]))
    table.insert(param_list, v)
  end

  return table.concat(paramenter_list, "&"), table.concat(param_list, ";")
end

local function getHttpString(http_request_opts)
  local method = string.lower(http_request_opts.method or "get")
  local uri_path_name = http_request_opts.path or ""
  local http_paramenters, url_param_list = encodeTable(http_request_opts.query or {})
  local http_headers, header_list = encodeTable(http_request_opts.headers or {})

  return string.format("%s\n%s\n%s\n%s\n", method, uri_path_name, http_paramenters, http_headers), header_list, url_param_list
end

local function getStringToSign(key_time, http_string)
  local sha1_str = toHex(sha1(http_string))
  return string.format("sha1\n%s\n%s\n", key_time, sha1_str)
end

local function getSignature(sign_key, string_to_sigin)
  return toHex(hmacSha1(sign_key, string_to_sigin))
end

local function getSignatureStr(secret_id, key_time, header_list, url_param_list, signature)
  return string.format(
    "q-sign-algorithm=sha1&q-ak=%s&q-sign-time=%s&q-key-time=%s&q-header-list=%s&q-url-param-list=%s&q-signature=%s",
    secret_id,
    key_time,
    key_time,
    header_list,
    url_param_list,
    signature
  )
end

function _M.sign(http_request_opts, secret_key, secret_id, expire_time)
  if (not secret_key) or (not secret_id) then
    return ""
  end

  local key_time = getKeyTime(expire_time)
  local sign_key = getSignKey(secret_key, key_time)
  local http_string, header_list, url_param_list  = getHttpString(http_request_opts)
  local string_to_sigin = getStringToSign(key_time, http_string)
  local signature = getSignature(sign_key, string_to_sigin)
  local signature_str = getSignatureStr(secret_id, key_time, header_list, url_param_list, signature)

  return signature_str
end

return _M
