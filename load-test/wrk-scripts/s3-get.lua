local headers = {}
-- create authorized request using wrk.format function
-- refer: https://github.com/wg/wrk/blob/master/SCRIPTING
request = function()
  -- every request would have different auth headers
  -- unless timestamp and content are exactly the same

  -- setup API path
  path = "/1Kb/1Kb"

  -- command to generate auth headers
  -- NOTE: same body payload is used as above, BUT we have type it again since here it needs some escaping
  cmd = 'bash header-generate.sh'

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

  -- return the authorized request
  return wrk.format("HEAD", path, headers, body)
end
