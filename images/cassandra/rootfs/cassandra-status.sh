#!/bin/bash

/usr/bin/nodetool -p 7199 -h cassandra.default.svc status -r | tail -n +6 | head -n +1 | /usr/bin/gawk -f /cassandra-status.awk
