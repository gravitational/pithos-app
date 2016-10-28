-- wrk script to work with S3

-- Need to pass these between functions
local action = ""
local bucket = ""
local object = ""
local file_path = ""

-- parse args
init = function(args)
    action = args[1]
    if action == "download" then
      bucket = args[2]
      object = args[3]
    elseif action == "upload" then
      file_path = args[2]
      bucket = args[3]
      object = args[4]
    else
      print("unsupported action: ", action)
      do return end
    end
end

-- create authorized request using wrk.format function
-- refer: https://github.com/wg/wrk/blob/master/SCRIPTING
-- every request would have different auth headers
-- unless timestamp and content are exactly the same
request = function()
  local http_method = ""
  local headers = {}
  local body = nil
  local path = string.format("/%s/%s", bucket, object)

  if action == "download" then
    http_method = "GET"
    headers = get_headers_for_download()
  else
    http_method = "PUT"
    headers = get_headers_for_upload()
  end

  return wrk.format(http_method, path, headers, body)
end

response = function(status, headers, body)
   if status ~= 200 then
     print("Error report:")
     print("HTTP code:", status)
     tprint(headers)
     print()
   end
end

function get_headers_for_download()
  local cmd = string.format("bash header-generate.sh download %s %s", bucket, object)

  -- parse command output into variables
  local f = io.popen(cmd, 'r')
  local header_content_type = f:read()
  local header_date = f:read()
  local header_auth_token = f:read()
  f:close()

  -- setup headers for an authorized request
  local headers = {}
  headers["Host"] = header_content_type
  headers["Date"] = header_date
  headers["Authorization"] = header_auth_token

  return headers
end

function get_headers_for_upload()
  local cmd = string.format("bash header-generate.sh upload %s %s %s %s", file_path, bucket, object, "public-read")

  -- parse command output into variables
  local f = io.popen(cmd, 'r')
  local header_content_md5 = f:read()
  local header_acl = f:read()
  local header_content_type = f:read()
  local header_date = f:read()
  local header_auth_token = f:read()
  f:close()

  -- setup headers for an authorized request
  local headers = {}
  headers["Host"] = header_content_type
  headers["Date"] = header_date
  headers["Authorization"] = header_auth_token
  headers["Content-MD5"] = header_content_md5
  headers["x-amz-acl"] = header_acl

  return headers
end

-- Print contents of `tbl`, with indentation.
-- `indent` sets the initial level of indentation.
function tprint (tbl, indent)
  if not indent then indent = 0 end
  for k, v in pairs(tbl) do
    formatting = string.rep("  ", indent) .. k .. ": "
    if type(v) == "table" then
      print(formatting)
      tprint(v, indent+1)
    else
      print(formatting .. v)
    end
  end
end
