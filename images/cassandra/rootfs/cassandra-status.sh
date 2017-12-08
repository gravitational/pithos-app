#!/bin/bash

ip_addr=$(hostname --ip-address)
/usr/bin/nodetool -p 7199 -h localhost status | grep $ip_addr | sed "s/$ip_addr/$(hostname)/" \
    | /usr/bin/gawk -f /cassandra-status.awk
