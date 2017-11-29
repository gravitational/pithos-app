#!/bin/bash

/usr/bin/nodetool -p 7199 -h localhost status | tail -n +6 | head -n -1 | /usr/bin/gawk -f /cassandra-status.awk
