#!/usr/bin/env bash

NUM_NODES=$(kubectl get nodes --selector=pithos-role=node --no-headers | wc --lines)
REPLICATION_FACTOR=1

if [[ $NUM_NODES -gt 2 ]]; then
	REPLICATION_FACTOR=3
fi

# change default password, if not already set
cqlsh -u cassandra -p cassandra -e "ALTER ROLE cassandra WITH PASSWORD='${CASSANDRA_PASSWORD}'" cassandra.default.svc.cluster.local || true

sed -i 's/REPLICATION_FACTOR/'"${REPLICATION_FACTOR}"'/g' /init.cql

cqlsh -u cassandra -p "${CASSANDRA_PASSWORD}" -f /init.cql cassandra.default.svc.cluster.local
