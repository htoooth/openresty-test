local cjson = require "cjson"
local multipart_parser = require "multipart-parser"
local qcloud_cos = require "qcloud-cos-api"
local utils = require "utils"

-- cos info
local app_id = os.getenv("app_id")
local secret_id = os.getenv("secret_id")
local secret_key = os.getenv("secret_key")
local bucket_name = os.getenv("bucket_name")
local region = os.getenv("region")

local host = "myqcloud.com"
local upload_host = string.format("%s-%s.cos.%s.%s", bucket_name, app_id, region, host)
local file_field_name = "file_data"
local csv_filepath = "./image/app-error.log"

local multipart =
  multipart_parser:new(
  {
    chunk_size = 4096
  }
)

-- receive file
local app_upload_info = multipart:read()

local app_snap_file_info = app_upload_info[file_field_name]
local cos_filename = utils.uuid_filename(app_snap_file_info.header.filename)
local cos_filepath = string.format("/error-image/%s", cos_filename)
local cos_fileurl = string.format("%s%s", upload_host, cos_filepath)

-- upload cos
local qcloud_api =
  qcloud_cos:new(
  {
    host = upload_host,
    port = port,
    app_id = app_id,
    bucket_name = bucket_name,
    region = region,
    secret_id = secret_id,
    secret_key = secret_key
  }
)

local res_cos, err =
  qcloud_api:put(
  {
    method = "PUT",
    path = cos_filepath,
    body = app_snap_file_info.body,
    headers = {
      ["Host"] = upload_host,
      ["Content-Type"] = "image/jpg",
      ["Content-Length"] = app_snap_file_info.header.size
    },
    keepalive_timeout = 10000,
    keepalive_pool = 10
  }
)

if not res_cos.body then
  utils.log("cos upload msg: ", res_cos.body)
end

if err then
  utils.log("cos upload msg: ", err)
end

local row = {
  app_upload_info.uid and app_upload_info.uid.body or "null",
  app_upload_info.udid and app_upload_info.udid.body or "null",
  app_upload_info.app_version and app_upload_info.app_version.body or "null",
  app_upload_info.os_version and app_upload_info.os_version.body or "null",
  app_upload_info.client_type and app_upload_info.client_type.body or "null",
  math.floor(ngx.now()),
  app_upload_info.suggest and app_upload_info.suggest.body or "null",
  cos_fileurl or "null"
}

utils.write(csv_filepath, table.concat(row, ","))

ngx.say(
  cjson.encode(
    {
      code = 200,
      msg = "upload ok",
      data = cos_fileurl
    }
  )
)
