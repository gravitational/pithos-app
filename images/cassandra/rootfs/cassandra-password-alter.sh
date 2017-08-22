#!/usr/bin/env bash

# change default password, if not already set
printenv
echo "ALTER ROLE cassandra WITH PASSWORD='${CASSANDRA_PASSWORD}'"
cqlsh -u cassandra -p cassandra -e "ALTER ROLE cassandra WITH PASSWORD='${CASSANDRA_PASSWORD}'" cassandra.default.svc.cluster.local
