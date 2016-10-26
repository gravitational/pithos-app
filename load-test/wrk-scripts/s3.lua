local headers = {}
local method = ""
local bucket = ""
local object = ""

-- parse args
init = function(args)
    method = args[1]
    bucket = args[2]
    object = args[3]
end

-- create authorized request using wrk.format function
-- refer: https://github.com/wg/wrk/blob/master/SCRIPTING
request = function()
  -- every request would have different auth headers
  -- unless timestamp and content are exactly the same

  -- setup API path
  path = string.format("/%s/%s", bucket, object)

  -- command to generate auth headers
  cmd = string.format("bash header-generate.sh %s %s %s", method, bucket, object)

  -- parse command output into variables
  local f = io.popen(cmd, 'r')
  local header_content_type = f:read()
  local header_date = f:read()
  local header_auth_token = f:read()
  f:close()

  -- setup headers for an authorized request
  headers["Host"] = header_content_type
  headers["Date"] = header_date
  headers["Authorization"] = header_auth_token

  local req = wrk.format(method, path, headers, body)

  -- return the authorized request
  return req
end
