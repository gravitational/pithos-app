# Parse output of `nodetool status -r` command

# --  Address  Load       Tokens       Owns (effective)  Host ID                               Rack
# UN  node-1  105.58 KiB  32           100.0%            0ab52e7b-672f-4821-aeca-1d745c9d5720  rack1
# DL  node-2  105.58 KiB  32           100.0%            0ab52e7b-672f-4821-aeca-1d745c9d5720  rack1


BEGIN { ORS = ""; }
  {
      address = $2
      host_id = $7
      split($1, a, "")

      switch (a[1]) {
      case "U":
          status = "1"
          break
      case "D":
          status = "0"
          break
      }

      switch (a[2]) {
      case "N":
          state = "0"
          break
      case "L":
          state = "1"
          break
      case "J":
          state = "2"
          break
      case "M":
          state = "3"
          break
      }

      printf "%scassandraStatus,address=%s,host_id=%s status=%s,state=%s",
          separator, address, host_id, status, state
          separator = "\n"
  }
END { print "\n"; }

# Output legend
# status:
# 0 - Node is down
# 1 - Node is up
#
# state:
# 0 - Normal
# 1 - Leaving
# 2 - Joining
# 3 - Moving

